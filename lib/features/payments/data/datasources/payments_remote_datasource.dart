import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/logger.dart';
import '../models/payment_model.dart';
import '../../../sales/domain/entities/sale_entity.dart';

abstract class PaymentsRemoteDatasource {
  Future<PaymentModel> recordPayment({
    required String businessId,
    String? branchId,
    String? saleId,
    String? customerId,
    String? supplierId,
    required int amount,
    required PaymentMethod paymentMethod,
    String? provider,
    String? reference,
    String? phoneNumber,
    String status = 'completed',
    String? notes,
  });

  Future<List<PaymentModel>> getPaymentsBySale(String saleId);
  Future<List<PaymentModel>> getPaymentsByCustomer(String customerId);
  Future<List<PaymentModel>> getPaymentsByBusiness({
    required String businessId,
    String? branchId,
    int limit = 50,
  });
}

class PaymentsRemoteDatasourceImpl implements PaymentsRemoteDatasource {
  final SupabaseClient _supabaseClient;

  PaymentsRemoteDatasourceImpl(this._supabaseClient);

  @override
  Future<PaymentModel> recordPayment({
    required String businessId,
    String? branchId,
    String? saleId,
    String? customerId,
    String? supplierId,
    required int amount,
    required PaymentMethod paymentMethod,
    String? provider,
    String? reference,
    String? phoneNumber,
    String status = 'completed',
    String? notes,
  }) async {
    try {
      final response = await _supabaseClient
          .from('payments')
          .insert({
            'business_id': businessId,
            'branch_id': branchId,
            'sale_id': saleId,
            'customer_id': customerId,
            'supplier_id': supplierId,
            'amount': amount,
            'payment_method': paymentMethod.value,
            'provider': provider,
            'reference': reference,
            'phone_number': phoneNumber,
            'status': status,
            'notes': notes,
            'recorded_by': _supabaseClient.auth.currentUser?.id,
          })
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Record Payment Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsBySale(String saleId) async {
    try {
      final response = await _supabaseClient
          .from('payments')
          .select()
          .eq('sale_id', saleId)
          .order('created_at', ascending: false);

      final list = response as List;
      return list
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        return [];
      }
      throw AppException(e.message);
    } catch (e) {
      AppLogger.e('Get Payments By Sale Error: $e');
      return [];
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByCustomer(String customerId) async {
    try {
      final response = await _supabaseClient
          .from('payments')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      final list = response as List;
      return list
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        return [];
      }
      throw AppException(e.message);
    } catch (e) {
      AppLogger.e('Get Payments By Customer Error: $e');
      return [];
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByBusiness({
    required String businessId,
    String? branchId,
    int limit = 50,
  }) async {
    try {
      var query = _supabaseClient
          .from('payments')
          .select()
          .eq('business_id', businessId);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      final list = response as List;
      return list
          .map((json) => PaymentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        AppLogger.w(
          'public.payments table not found in schema cache. Migration pending: ${e.message}',
        );
        return [];
      }
      throw AppException(e.message);
    } catch (e) {
      AppLogger.e('Get Payments By Business Error: $e');
      return [];
    }
  }
}
