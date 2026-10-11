import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/staff_user_entity.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../../data/datasources/user_management_remote_datasource.dart';
import '../../data/repositories/user_management_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';

final userManagementRemoteDatasourceProvider = Provider<UserManagementRemoteDatasource>((ref) {
  return UserManagementRemoteDatasourceImpl(Supabase.instance.client);
});

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  final remote = ref.watch(userManagementRemoteDatasourceProvider);
  return UserManagementRepositoryImpl(remoteDatasource: remote);
});

// Fetch current user's role in active business
final currentUserRoleProvider = FutureProvider.autoDispose<UserRoleType?>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return null;

  final repo = ref.watch(userManagementRepositoryProvider);
  final result = await repo.getCurrentUserRole(currentBiz.id);
  return result.fold(
    (failure) => null,
    (role) => role,
  );
});

// Fetch staff list for active business
final businessStaffListProvider = FutureProvider.autoDispose<List<StaffUserEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final repo = ref.watch(userManagementRepositoryProvider);
  final result = await repo.getBusinessStaff(currentBiz.id);
  return result.fold(
    (failure) => throw failure.message,
    (staff) => staff,
  );
});

// Staff controller for mutations (assign, update, remove)
class StaffController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  StaffController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> assignStaff({
    required String userEmail,
    required UserRoleType role,
    String? fullName,
    String? password,
    String? phone,
    String? branchId,
    Map<String, dynamic> customPermissions = const {},
  }) async {
    final currentBiz = ref.read(currentBusinessProvider);
    if (currentBiz == null) {
      state = AsyncValue.error('No active business found.', StackTrace.current);
      return false;
    }

    state = const AsyncValue.loading();
    final repo = ref.read(userManagementRepositoryProvider);

    final result = await repo.assignStaffRole(
      businessId: currentBiz.id,
      userEmail: userEmail,
      role: role,
      fullName: fullName,
      password: password,
      phone: phone,
      branchId: branchId,
      customPermissions: customPermissions,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (newStaff) {
        state = const AsyncValue.data(null);
        ref.invalidate(businessStaffListProvider);
        return true;
      },
    );
  }

  Future<bool> updateStaff({
    required String roleId,
    required UserRoleType newRole,
    String? newBranchId,
    bool? isActive,
    Map<String, dynamic>? customPermissions,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(userManagementRepositoryProvider);

    final result = await repo.updateStaffRole(
      roleId: roleId,
      newRole: newRole,
      newBranchId: newBranchId,
      isActive: isActive,
      customPermissions: customPermissions,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(businessStaffListProvider);
        return true;
      },
    );
  }

  Future<bool> removeStaff(String roleId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(userManagementRepositoryProvider);

    final result = await repo.removeStaffRole(roleId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(businessStaffListProvider);
        return true;
      },
    );
  }
}

final staffControllerProvider = StateNotifierProvider<StaffController, AsyncValue<void>>((ref) {
  return StaffController(ref);
});
