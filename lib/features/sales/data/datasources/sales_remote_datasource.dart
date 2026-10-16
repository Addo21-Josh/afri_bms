import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/logger.dart';
import '../models/sale_model.dart';
import '../models/sale_item_model.dart';

abstract class SalesRemoteDatasource {
  Future<SaleModel> processSale({
    required String businessId,
    required String branchId,
    required String cashierId,
    required String saleNumber,
    required int subtotal,
    required int discountAmount,
    required int taxAmount,
    required int totalAmount,
    required String paymentMethod,
    required int amountTendered,
    required int changeGiven,
    String? customerId,
    String? paymentReference,
    String? customerName,
    String? customerPhone,
    String? notes,
    required List<SaleItemModel> items,
  });

  Future<List<SaleModel>> getSales({
    required String businessId,
    String? branchId,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  });

  Future<SaleModel> getSaleById(String saleId);
}

class SalesRemoteDatasourceImpl implements SalesRemoteDatasource {
  final SupabaseClient _supabaseClient;

  SalesRemoteDatasourceImpl(this._supabaseClient);

  @override
  Future<SaleModel> processSale({
    required String businessId,
    required String branchId,
    required String cashierId,
    required String saleNumber,
    required int subtotal,
    required int discountAmount,
    required int taxAmount,
    required int totalAmount,
    required String paymentMethod,
    required int amountTendered,
    required int changeGiven,
    String? customerId,
    String? paymentReference,
    String? customerName,
    String? customerPhone,
    String? notes,
    required List<SaleItemModel> items,
  }) async {
    try {
      final itemsJson = items.map((i) => i.toRpcJson()).toList();

      String? saleId;

      try {
        // Try atomic RPC procedure with 6-second timeout
        final response = await _supabaseClient.rpc('process_sale', params: {
          'p_business_id': businessId,
          'p_branch_id': branchId,
          'p_cashier_id': cashierId,
          'p_sale_number': saleNumber,
          'p_subtotal': subtotal,
          'p_discount_amount': discountAmount,
          'p_tax_amount': taxAmount,
          'p_total_amount': totalAmount,
          'p_payment_method': paymentMethod,
          'p_amount_tendered': amountTendered,
          'p_change_given': changeGiven,
          'p_payment_reference': paymentReference,
          'p_customer_name': customerName,
          'p_customer_phone': customerPhone,
          'p_notes': notes,
          'p_items': itemsJson,
        }).timeout(const Duration(seconds: 6));

        saleId = response as String?;
      } catch (rpcError) {
        // Fast-fail if the error was due to network disconnection or timeout
        final err = rpcError.toString();
        final isNetwork = rpcError is TimeoutException ||
            err.contains('SocketException') ||
            err.contains('ClientException') ||
            err.contains('Failed host lookup') ||
            err.contains('Connection refused') ||
            err.contains('Network is unreachable') ||
            err.contains('timed out') ||
            err.contains('Connection reset') ||
            err.contains('Software caused connection abort') ||
            err.contains('HandshakeException');

        if (isNetwork) {
          AppLogger.w('process_sale remote RPC failed due to network ($rpcError). Aborting remote attempts.');
          throw AppException('Network unavailable: $rpcError');
        }

        AppLogger.w('process_sale RPC error or not applied, falling back to direct inserts: $rpcError');

        // Fallback in case stored procedure migration hasn't been run yet:
        // 1. Insert into sales
        final saleRow = await _supabaseClient.from('sales').insert({
          'business_id': businessId,
          'branch_id': branchId,
          'cashier_id': cashierId,
          'sale_number': saleNumber,
          'subtotal': subtotal,
          'discount_amount': discountAmount,
          'tax_amount': taxAmount,
          'total_amount': totalAmount,
          'payment_method': paymentMethod,
          'payment_status': 'paid',
          'amount_tendered': amountTendered,
          'change_given': changeGiven,
          'payment_reference': paymentReference,
          if (customerId != null) 'customer_id': customerId,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'notes': notes,
        }).select().single().timeout(const Duration(seconds: 6));

        saleId = saleRow['id'] as String;

        // 2. Insert sale_items
        final saleItemsData = items.map((item) => {
          'sale_id': saleId,
          'product_id': item.productId,
          'variant_id': item.variantId,
          'product_name': item.productName,
          'variant_name': item.variantName,
          'unit_cost_price': item.unitCostPrice,
          'unit_price': item.unitPrice,
          'quantity': item.quantity,
          'discount_amount': item.discountAmount,
          'total_price': item.totalPrice,
        }).toList();

        await _supabaseClient.from('sale_items').insert(saleItemsData).timeout(const Duration(seconds: 6));

        // 3. Decrement stock & record stock movement for each item
        for (final item in items) {
          try {
            var stockQuery = _supabaseClient
                .from('stock')
                .select('id, quantity')
                .eq('branch_id', branchId)
                .eq('product_id', item.productId);

            if (item.variantId != null) {
              stockQuery = stockQuery.eq('variant_id', item.variantId!);
            } else {
              stockQuery = stockQuery.isFilter('variant_id', null);
            }

            final stockRows = await stockQuery;
            if (stockRows.isNotEmpty) {
              final stockId = stockRows.first['id'] as String;
              final currentStock = (stockRows.first['quantity'] as num).toInt();
              await _supabaseClient.from('stock').update({
                'quantity': currentStock - item.quantity,
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', stockId);
            }

            // Audit movement
            await _supabaseClient.from('stock_movements').insert({
              'business_id': businessId,
              'branch_id': branchId,
              'product_id': item.productId,
              'variant_id': item.variantId,
              'quantity': -item.quantity,
              'type': 'sale',
              'reason': 'Sale: $saleNumber',
              'user_id': cashierId,
            });
          } catch (e) {
            AppLogger.w('Item stock deduction warning: $e');
          }
        }
      }

      if (saleId == null) {
        throw AppException('Failed to retrieve sale ID after processing.');
      }

      // 4. Auto-create debt receivable if sale is on credit or has unpaid balance
      final isCreditSale = paymentMethod.toLowerCase() == 'credit';
      final unpaidAmount = isCreditSale ? totalAmount : (totalAmount - amountTendered).clamp(0, totalAmount);
      if (unpaidAmount > 0) {
        try {
          await _supabaseClient.from('debts').insert({
            'business_id': businessId,
            'branch_id': branchId,
            'debt_type': 'receivable',
            if (customerId != null) 'customer_id': customerId,
            'sale_id': saleId,
            'person_name': (customerName != null && customerName.isNotEmpty) ? customerName : 'Customer ($saleNumber)',
            if (customerPhone != null) 'person_phone': customerPhone,
            'initial_amount': unpaidAmount,
            'remaining_balance': unpaidAmount,
            'due_date': DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10),
            'status': 'active',
            'notes': 'Auto-created from Sale #$saleNumber',
          });

          // Also increment customer outstanding_balance if customerId is present
          if (customerId != null) {
            final cust = await _supabaseClient
                .from('customers')
                .select('outstanding_balance')
                .eq('id', customerId)
                .single();
            final currentBal = (cust['outstanding_balance'] as num?)?.toInt() ?? 0;
            await _supabaseClient.from('customers').update({
              'outstanding_balance': currentBal + unpaidAmount,
            }).eq('id', customerId);
          }
        } catch (debtError) {
          AppLogger.w('Auto-create debt receivable notice: $debtError');
        }
      }

      return await getSaleById(saleId).timeout(const Duration(seconds: 6));
    } catch (e) {
      AppLogger.e('Process Sale Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<List<SaleModel>> getSales({
    required String businessId,
    String? branchId,
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      var query = _supabaseClient.from('sales').select('''
        id,
        business_id,
        branch_id,
        cashier_id,
        sale_number,
        subtotal,
        discount_amount,
        tax_amount,
        total_amount,
        payment_method,
        payment_status,
        amount_tendered,
        change_given,
        payment_reference,
        customer_name,
        customer_phone,
        notes,
        created_at,
        profiles ( full_name ),
        sale_items (
          id,
          sale_id,
          product_id,
          variant_id,
          product_name,
          variant_name,
          unit_cost_price,
          unit_price,
          quantity,
          discount_amount,
          total_price,
          created_at
        )
      ''').eq('business_id', businessId);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('sale_number.ilike.%$searchQuery%,customer_name.ilike.%$searchQuery%');
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map((json) => SaleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is PostgrestException && (e.code == 'PGRST205' || e.message.contains('sales'))) {
        AppLogger.w('sales table not yet migrated in Supabase (PGRST205). Please run migration 20261009000003_sales_pos_schema.sql.');
        return [];
      }
      AppLogger.e('Get Sales Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<SaleModel> getSaleById(String saleId) async {
    try {
      final response = await _supabaseClient.from('sales').select('''
        id,
        business_id,
        branch_id,
        cashier_id,
        sale_number,
        subtotal,
        discount_amount,
        tax_amount,
        total_amount,
        payment_method,
        payment_status,
        amount_tendered,
        change_given,
        payment_reference,
        customer_name,
        customer_phone,
        notes,
        created_at,
        profiles ( full_name ),
        sale_items (
          id,
          sale_id,
          product_id,
          variant_id,
          product_name,
          variant_name,
          unit_cost_price,
          unit_price,
          quantity,
          discount_amount,
          total_price,
          created_at
        )
      ''').eq('id', saleId).single();

      return SaleModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Get Sale By Id Error: $e');
      throw AppException(e.toString());
    }
  }
}
