import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/logger.dart';
import '../models/supplier_model.dart';

abstract class SuppliersRemoteDatasource {
  Future<List<SupplierModel>> getSuppliers(String businessId, {String? searchQuery});
  Future<SupplierModel> getSupplierById(String supplierId);
  Future<SupplierModel> createSupplier({
    required String businessId,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });
  Future<SupplierModel> updateSupplier(SupplierModel supplier);
  Future<void> deleteSupplier(String supplierId);
  Future<SupplierModel> updateBalance({
    required String supplierId,
    required int balanceAdjustment,
  });
}

class SuppliersRemoteDatasourceImpl implements SuppliersRemoteDatasource {
  final SupabaseClient _supabaseClient;

  SuppliersRemoteDatasourceImpl(this._supabaseClient);

  @override
  Future<List<SupplierModel>> getSuppliers(String businessId, {String? searchQuery}) async {
    try {
      var query = _supabaseClient
          .from('suppliers')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final sanitized = searchQuery.trim();
        query = query.or('name.ilike.%$sanitized%,contact_person.ilike.%$sanitized%,phone.ilike.%$sanitized%');
      }

      final response = await query.order('name', ascending: true);
      final list = response as List;
      return list.map((json) => SupplierModel.fromJson(json as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205') {
        AppLogger.w('public.suppliers table not found in schema cache. Migration pending: ${e.message}');
        return [];
      }
      AppLogger.e('Get Suppliers PostgrestException: $e');
      throw AppException(e.message);
    } catch (e) {
      AppLogger.e('Get Suppliers Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<SupplierModel> getSupplierById(String supplierId) async {
    try {
      final response = await _supabaseClient
          .from('suppliers')
          .select()
          .eq('id', supplierId)
          .single();

      return SupplierModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Get Supplier By Id Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<SupplierModel> createSupplier({
    required String businessId,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final response = await _supabaseClient
          .from('suppliers')
          .insert({
            'business_id': businessId,
            'name': name.trim(),
            'contact_person': contactPerson?.trim(),
            'phone': phone?.trim(),
            'email': email?.trim(),
            'address': address?.trim(),
            'outstanding_balance': 0,
            'notes': notes?.trim(),
            'is_active': true,
          })
          .select()
          .single();

      return SupplierModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Create Supplier Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<SupplierModel> updateSupplier(SupplierModel supplier) async {
    try {
      final response = await _supabaseClient
          .from('suppliers')
          .update({
            'name': supplier.name.trim(),
            'contact_person': supplier.contactPerson?.trim(),
            'phone': supplier.phone?.trim(),
            'email': supplier.email?.trim(),
            'address': supplier.address?.trim(),
            'notes': supplier.notes?.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', supplier.id)
          .select()
          .single();

      return SupplierModel.fromJson(response);
    } catch (e) {
      AppLogger.e('Update Supplier Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> deleteSupplier(String supplierId) async {
    try {
      await _supabaseClient
          .from('suppliers')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', supplierId);
    } catch (e) {
      AppLogger.e('Delete Supplier Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<SupplierModel> updateBalance({
    required String supplierId,
    required int balanceAdjustment,
  }) async {
    try {
      final current = await _supabaseClient
          .from('suppliers')
          .select('outstanding_balance')
          .eq('id', supplierId)
          .single();

      final currentBalance = (current['outstanding_balance'] as num?)?.toInt() ?? 0;
      final newBalance = (currentBalance + balanceAdjustment).clamp(0, double.maxFinite.toInt());

      final updated = await _supabaseClient
          .from('suppliers')
          .update({
            'outstanding_balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', supplierId)
          .select()
          .single();

      return SupplierModel.fromJson(updated);
    } catch (e) {
      AppLogger.e('Update Supplier Balance Error: $e');
      throw AppException(e.toString());
    }
  }
}
