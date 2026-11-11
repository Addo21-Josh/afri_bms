import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/staff_user_entity.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../../data/datasources/user_management_remote_datasource.dart';
import '../../data/repositories/user_management_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';

final userManagementRemoteDatasourceProvider =
    Provider<UserManagementRemoteDatasource>((ref) {
      return UserManagementRemoteDatasourceImpl(Supabase.instance.client);
    });

final userManagementRepositoryProvider = Provider<UserManagementRepository>((
  ref,
) {
  final remote = ref.watch(userManagementRemoteDatasourceProvider);
  return UserManagementRepositoryImpl(remoteDatasource: remote);
});

// Fetch current user's role in active business
final currentUserRoleProvider = FutureProvider<UserRoleType?>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return null;

  final localCache = ref.watch(localCacheServiceProvider);
  final syncState = ref.watch(syncProvider);
  final user = Supabase.instance.client.auth.currentUser;
  final userId = user?.id ?? await localCache.getLastUserId();

  Future<UserRoleType?> getCachedRole() async {
    final cachedRole = await localCache.getCachedUserRole(
      currentBiz.id,
      userId,
    );
    if (cachedRole != null && cachedRole.isNotEmpty) {
      return UserRoleType.fromString(cachedRole);
    }
    final syncRole = localCache.getUserRoleSync(currentBiz.id, userId);
    if (syncRole != null && syncRole.isNotEmpty) {
      return UserRoleType.fromString(syncRole);
    }
    // Only assume admin if the logged in user is explicitly the business owner
    if (userId != null && currentBiz.ownerId == userId) {
      return UserRoleType.admin;
    }
    return null;
  }

  if (!syncState.isOnline) {
    final cached = await getCachedRole();
    if (cached != null) return cached;
  }

  final repo = ref.watch(userManagementRepositoryProvider);
  final result = await repo.getCurrentUserRole(currentBiz.id);
  return result.fold(
    (failure) async {
      return await getCachedRole();
    },
    (role) async {
      if (role != null) {
        final uid = userId ?? Supabase.instance.client.auth.currentUser?.id;
        if (uid != null) {
          await localCache.cacheUserRole(currentBiz.id, uid, role.toDbString());
        }
        return role;
      }
      // If remote returned null (e.g. caught network error in datasource), check cache
      return await getCachedRole();
    },
  );
});

// Fetch staff list for active business
final businessStaffListProvider =
    FutureProvider.autoDispose<List<StaffUserEntity>>((ref) async {
      final currentBiz = ref.watch(currentBusinessProvider);
      if (currentBiz == null) return [];

      final repo = ref.watch(userManagementRepositoryProvider);
      final result = await repo.getBusinessStaff(currentBiz.id);
      return result.fold((failure) => throw failure.message, (staff) => staff);
    });

// Staff controller for mutations (assign, update, remove)
class StaffController extends StateNotifier<AsyncValue<void>> {
  StaffController(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

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

final staffControllerProvider =
    StateNotifierProvider<StaffController, AsyncValue<void>>((ref) {
      return StaffController(ref);
    });
