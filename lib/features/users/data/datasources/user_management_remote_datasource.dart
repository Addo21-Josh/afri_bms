import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../domain/entities/staff_user_entity.dart';
import '../models/staff_user_model.dart';

abstract class UserManagementRemoteDatasource {
  Future<List<StaffUserModel>> getBusinessStaff(String businessId);
  Future<StaffUserModel> assignStaffRole({
    required String businessId,
    required String userEmail,
    required UserRoleType role,
    String? fullName,
    String? password,
    String? phone,
    String? branchId,
    Map<String, dynamic> customPermissions = const {},
  });
  Future<void> updateStaffRole({
    required String roleId,
    required UserRoleType newRole,
    String? newBranchId,
    bool? isActive,
    Map<String, dynamic>? customPermissions,
  });
  Future<void> removeStaffRole(String roleId);
  Future<UserRoleType?> getCurrentUserRole(String businessId);
}

class UserManagementRemoteDatasourceImpl implements UserManagementRemoteDatasource {
  final SupabaseClient _supabaseClient;

  UserManagementRemoteDatasourceImpl(this._supabaseClient);

  @override
  Future<List<StaffUserModel>> getBusinessStaff(String businessId) async {
    try {
      final response = await _supabaseClient
          .from('user_roles')
          .select('''
            id,
            user_id,
            business_id,
            branch_id,
            role,
            is_active,
            custom_permissions,
            created_at,
            profiles (
              email,
              full_name,
              phone
            ),
            branches (
              name
            )
          ''')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);

      final list = response as List;
      return list.map((item) => StaffUserModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.e('Get Business Staff Error: $e');
      throw AppException(e.toString());
    }
  }

  @override
  Future<StaffUserModel> assignStaffRole({
    required String businessId,
    required String userEmail,
    required UserRoleType role,
    String? fullName,
    String? password,
    String? phone,
    String? branchId,
    Map<String, dynamic> customPermissions = const {},
  }) async {
    try {
      final normalizedEmail = userEmail.trim().toLowerCase();

      // 1. Try calling the PostgreSQL create_staff_user procedure directly
      try {
        final createdUserId = await _supabaseClient.rpc('create_staff_user', params: {
          'p_email': normalizedEmail,
          'p_password': password ?? 'AfriBMS@123',
          'p_full_name': fullName ?? normalizedEmail.split('@').first,
          'p_phone': phone,
          'p_business_id': businessId,
          'p_branch_id': branchId,
          'p_role': role.toDbString(),
        });

        if (createdUserId != null) {
          final staffData = await _supabaseClient
              .from('user_roles')
              .select('''
                id,
                user_id,
                business_id,
                branch_id,
                role,
                is_active,
                custom_permissions,
                created_at,
                profiles (
                  email,
                  full_name,
                  phone
                ),
                branches (
                  name
                )
              ''')
              .eq('business_id', businessId)
              .eq('user_id', createdUserId)
              .maybeSingle();

          if (staffData != null) {
            return StaffUserModel.fromJson(staffData);
          }
        }
      } catch (rpcErr) {
        AppLogger.w('create_staff_user RPC error: $rpcErr');
        // If the error indicates the function doesn't exist (e.g. 42883 / PGRST202), fallback to lookup
        final errStr = rpcErr.toString();
        if (!errStr.contains('PGRST202') && !errStr.contains('42883') && !errStr.contains('not found')) {
          throw AppException(rpcErr is PostgrestException ? rpcErr.message : rpcErr.toString());
        }
      }

      // 2. Fallback: Find existing profile by email and assign role
      final profileResponse = await _supabaseClient
          .from('profiles')
          .select()
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (profileResponse == null) {
        throw AppException(
          'Unable to create staff account for "$userEmail". Please verify the email address or upgrade your subscription plan to add more team members.',
        );
      }

      final targetUserId = profileResponse['id'] as String;

      // Upsert into user_roles
      final insertedData = await _supabaseClient
          .from('user_roles')
          .upsert({
            'user_id': targetUserId,
            'business_id': businessId,
            'branch_id': branchId,
            'role': role.toDbString(),
            'is_active': true,
            'custom_permissions': customPermissions,
          })
          .select('''
            id,
            user_id,
            business_id,
            branch_id,
            role,
            is_active,
            custom_permissions,
            created_at,
            profiles (
              email,
              full_name,
              phone
            ),
            branches (
              name
            )
          ''')
          .single();

      return StaffUserModel.fromJson(insertedData);
    } catch (e) {
      AppLogger.e('Assign Staff Role Error: $e');
      if (e is AppException) rethrow;
      throw AppException(UserFriendlyError.toFriendly(e));
    }
  }

  @override
  Future<void> updateStaffRole({
    required String roleId,
    required UserRoleType newRole,
    String? newBranchId,
    bool? isActive,
    Map<String, dynamic>? customPermissions,
  }) async {
    try {
      final updates = <String, dynamic>{
        'role': newRole.toDbString(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (newBranchId != null) updates['branch_id'] = newBranchId;
      if (isActive != null) updates['is_active'] = isActive;
      if (customPermissions != null) updates['custom_permissions'] = customPermissions;

      await _supabaseClient.from('user_roles').update(updates).eq('id', roleId);
    } catch (e) {
      AppLogger.e('Update Staff Role Error: $e');
      if (e is AppException) rethrow;
      throw AppException(UserFriendlyError.toFriendly(e));
    }
  }

  @override
  Future<void> removeStaffRole(String roleId) async {
    try {
      await _supabaseClient.from('user_roles').delete().eq('id', roleId);
    } catch (e) {
      AppLogger.e('Remove Staff Role Error: $e');
      if (e is AppException) rethrow;
      throw AppException(UserFriendlyError.toFriendly(e));
    }
  }

  @override
  Future<UserRoleType?> getCurrentUserRole(String businessId) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return null;

      // Check if user is owner
      final business = await _supabaseClient
          .from('businesses')
          .select('owner_id')
          .eq('id', businessId)
          .maybeSingle();

      if (business != null && business['owner_id'] == user.id) {
        return UserRoleType.admin;
      }

      // Check user_roles table
      final roleData = await _supabaseClient
          .from('user_roles')
          .select('role')
          .eq('business_id', businessId)
          .eq('user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      if (roleData == null) return null;
      return UserRoleType.fromString(roleData['role'] as String);
    } catch (e) {
      AppLogger.e('Get Current User Role Error: $e');
      return null;
    }
  }
}
