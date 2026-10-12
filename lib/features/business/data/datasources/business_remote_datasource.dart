import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afri_bms/core/errors/app_exception.dart';
import 'package:afri_bms/core/utils/logger.dart';
import 'package:afri_bms/features/business/domain/entities/business_entity.dart';
import 'package:afri_bms/features/business/domain/entities/branch_entity.dart';
import '../models/business_model.dart';
import '../models/branch_model.dart';

abstract class BusinessRemoteDatasource {
  Future<BusinessEntity> createBusinessWithBranch({
    required String ownerId,
    required String name,
    required String defaultCurrency,
    required String firstBranchName,
  });

  Future<List<BusinessEntity>> getUserBusinesses(String userId);
  Future<BusinessEntity> updateBusiness(BusinessEntity business);
  Future<List<BranchEntity>> getBusinessBranches(String businessId);
  Future<BranchEntity> createBranch({
    required String businessId,
    required String name,
    required String currency,
    String? address,
    String? phone,
    bool isMain = false,
  });
  Future<BranchEntity> updateBranch(BranchEntity branch);
  Future<void> deleteBranch(String branchId);
  Future<void> deleteBusiness(String businessId);
}

class BusinessRemoteDatasourceImpl implements BusinessRemoteDatasource {
  final SupabaseClient _supabaseClient;

  BusinessRemoteDatasourceImpl(this._supabaseClient);

  @override
  Future<BusinessEntity> createBusinessWithBranch({
    required String ownerId,
    required String name,
    required String defaultCurrency,
    required String firstBranchName,
  }) async {
    try {
      // Ensure profile exists in public.profiles before foreign key references
      final existingProfile = await _supabaseClient
          .from('profiles')
          .select('id')
          .eq('id', ownerId)
          .maybeSingle();

      if (existingProfile == null) {
        final currentUser = _supabaseClient.auth.currentUser;
        if (currentUser != null) {
          await _supabaseClient.from('profiles').upsert({
            'id': ownerId,
            'email': currentUser.email ?? '',
            'full_name': currentUser.userMetadata?['full_name'] as String? ?? (currentUser.email?.split('@').first ?? 'User'),
            'phone': currentUser.userMetadata?['phone'] as String?,
          });
        }
      }

      // 1. Create Business
      final businessData = await _supabaseClient.from('businesses').insert({
        'owner_id': ownerId,
        'name': name,
        'default_currency': defaultCurrency,
        'supported_currencies': [defaultCurrency],
      }).select().single();

      final businessModel = BusinessModel.fromJson(businessData);
      final businessId = businessModel.id;

      // 2. Create Main Branch
      final branchData = await _supabaseClient.from('branches').insert({
        'business_id': businessId,
        'name': firstBranchName,
        'currency': defaultCurrency,
        'is_main': true,
      }).select().single();

      final branchModel = BranchModel.fromJson(branchData);

      // 3. Assign Admin Role to Owner
      await _supabaseClient.from('user_roles').insert({
        'user_id': ownerId,
        'business_id': businessId,
        'branch_id': branchModel.id,
        'role': 'admin',
      });

      return businessModel.toEntity();
    } catch (e) {
      AppLogger.e('Create Business Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<List<BusinessEntity>> getUserBusinesses(String userId) async {
    try {
      // 1. Fetch businesses owned by user
      final ownedData = await _supabaseClient
          .from('businesses')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      final businesses = (ownedData as List)
          .map((json) => BusinessModel.fromJson(json).toEntity())
          .toList();

      final existingIds = businesses.map((b) => b.id).toSet();

      // 2. Fetch businesses where user is an assigned team/staff member
      final staffRolesData = await _supabaseClient
          .from('user_roles')
          .select('business_id, businesses(*)')
          .eq('user_id', userId)
          .eq('is_active', true);

      for (final role in staffRolesData as List) {
        final bizJson = role['businesses'];
        if (bizJson != null && bizJson is Map<String, dynamic>) {
          final biz = BusinessModel.fromJson(bizJson).toEntity();
          if (!existingIds.contains(biz.id)) {
            existingIds.add(biz.id);
            businesses.add(biz);
          }
        }
      }

      return businesses;
    } catch (e) {
      AppLogger.e('Get User Businesses Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<BusinessEntity> updateBusiness(BusinessEntity business) async {
    try {
      final updatedData = await _supabaseClient
          .from('businesses')
          .update({
            'name': business.name,
            'description': business.description,
            'default_currency': business.defaultCurrency,
            'tax_rate': business.taxRate,
            'phone': business.phone,
            'email': business.email,
            'address': business.address,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', business.id)
          .select()
          .single();

      return BusinessModel.fromJson(updatedData).toEntity();
    } catch (e) {
      AppLogger.e('Update Business Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<List<BranchEntity>> getBusinessBranches(String businessId) async {
    try {
      final data = await _supabaseClient
          .from('branches')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true)
          .order('is_main', ascending: false);

      return (data as List)
          .map((json) => BranchModel.fromJson(json).toEntity())
          .toList();
    } catch (e) {
      AppLogger.e('Get Business Branches Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<BranchEntity> createBranch({
    required String businessId,
    required String name,
    required String currency,
    String? address,
    String? phone,
    bool isMain = false,
  }) async {
    try {
      final data = await _supabaseClient.from('branches').insert({
        'business_id': businessId,
        'name': name,
        'currency': currency,
        'address': address,
        'phone': phone,
        'is_main': isMain,
      }).select().single();

      return BranchModel.fromJson(data).toEntity();
    } catch (e) {
      AppLogger.e('Create Branch Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<BranchEntity> updateBranch(BranchEntity branch) async {
    try {
      final data = await _supabaseClient
          .from('branches')
          .update({
            'name': branch.name,
            'currency': branch.currency,
            'address': branch.address,
            'phone': branch.phone,
            'is_main': branch.isMain,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', branch.id)
          .select()
          .single();

      return BranchModel.fromJson(data).toEntity();
    } catch (e) {
      AppLogger.e('Update Branch Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> deleteBranch(String branchId) async {
    try {
      await _supabaseClient
          .from('branches')
          .update({'is_active': false})
          .eq('id', branchId);
    } catch (e) {
      AppLogger.e('Delete Branch Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> deleteBusiness(String businessId) async {
    try {
      // First clean up user roles and branches for this business if needed
      try {
        await _supabaseClient.from('user_roles').delete().eq('business_id', businessId);
      } catch (_) {}
      try {
        await _supabaseClient.from('branches').delete().eq('business_id', businessId);
      } catch (_) {}
      await _supabaseClient.from('businesses').delete().eq('id', businessId);
    } catch (e) {
      AppLogger.e('Delete Business Error: $e');
      throw AppException(e.toString());
    }
  }
}
