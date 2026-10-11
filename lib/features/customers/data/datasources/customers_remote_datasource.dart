import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/logger.dart';
import '../models/customer_model.dart';
import '../../../sales/data/models/sale_model.dart';

abstract class CustomersRemoteDatasource {
  Future<List<CustomerModel>> getCustomers(String businessId, {String? searchQuery});
  Future<CustomerModel> getCustomerById(String customerId);
  Future<CustomerModel> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    int creditLimit = 0,
    String? notes,
  });
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String customerId);
  Future<CustomerModel> updateBalance({
    required String customerId,
    required int balanceAdjustment,
  });
  Future<List<SaleModel>> getCustomerSales(String customerId);
}

class CustomersRemoteDatasourceImpl implements CustomersRemoteDatasource {
  final SupabaseClient _supabaseClient;

  CustomersRemoteDatasourceImpl(this._supabaseClient);

  @override
  Future<List<CustomerModel>> getCustomers(String businessId, {String? searchQuery}) async {
    try {
      var query = _supabaseClient
          .from('customers')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final sanitized = searchQuery.trim();
        query = query.or('name.ilike.%$sanitized%,phone.ilike.%$sanitized%');
      }

      final response = await query.order('name', ascending: true);
      final list = response as List;
      return list.map((json) => CustomerModel.fromJson(json as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        AppLogger.w('public.customers table not found in schema cache. Migration pending: ${e.message}');
        return [];
      }
      AppLogger.e('Get Customers PostgrestException: $e');
      throw AppException(e.message);
    } catch (e) {
      AppLogger.e('Get Customers Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String customerId) async {
    try {
      final response = await _supabaseClient
          .from('customers')
          .select()
          .eq('id', customerId)
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Get Customer By Id Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<CustomerModel> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    int creditLimit = 0,
    String? notes,
  }) async {
    try {
      final response = await _supabaseClient
          .from('customers')
          .insert({
            'business_id': businessId,
            'name': name.trim(),
            'phone': phone?.trim(),
            'email': email?.trim(),
            'address': address?.trim(),
            'credit_limit': creditLimit,
            'outstanding_balance': 0,
            'notes': notes?.trim(),
            'is_active': true,
          })
          .select()
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Create Customer Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final response = await _supabaseClient
          .from('customers')
          .update({
            'name': customer.name.trim(),
            'phone': customer.phone?.trim(),
            'email': customer.email?.trim(),
            'address': customer.address?.trim(),
            'credit_limit': customer.creditLimit,
            'notes': customer.notes?.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customer.id)
          .select()
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Update Customer Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _supabaseClient
          .from('customers')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', customerId);
    } catch (e) {
      AppLogger.e('Delete Customer Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<CustomerModel> updateBalance({
    required String customerId,
    required int balanceAdjustment,
  }) async {
    try {
      // Fetch current balance
      final current = await _supabaseClient
          .from('customers')
          .select('outstanding_balance')
          .eq('id', customerId)
          .single();

      final currentBalance = (current['outstanding_balance'] as num?)?.toInt() ?? 0;
      final newBalance = (currentBalance + balanceAdjustment).clamp(0, double.maxFinite.toInt());

      final updated = await _supabaseClient
          .from('customers')
          .update({
            'outstanding_balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId)
          .select()
          .single();

      return CustomerModel.fromJson(updated);
    } catch (e) {
      AppLogger.e('Update Customer Balance Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<List<SaleModel>> getCustomerSales(String customerId) async {
    try {
      final response = await _supabaseClient
          .from('sales')
          .select('*, sale_items(*)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      final list = response as List;
      return list.map((json) => SaleModel.fromJson(json as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        return [];
      }
      throw AppException(e.message);
    } catch (e) {
      AppLogger.e('Get Customer Sales Error: $e');
      return [];
    }
  }
}
