import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:afri_bms/features/business/domain/entities/business_entity.dart';
import 'package:afri_bms/features/business/domain/entities/branch_entity.dart';
import 'package:afri_bms/features/business/domain/repositories/business_repository.dart';
import 'package:afri_bms/features/business/domain/repositories/branch_repository.dart';
import 'package:afri_bms/features/business/data/datasources/business_remote_datasource.dart';
import 'package:afri_bms/features/business/data/repositories/business_repository_impl.dart';
import 'package:afri_bms/features/business/data/repositories/branch_repository_impl.dart';
import 'package:afri_bms/core/sync/presentation/providers/sync_provider.dart';
import 'package:afri_bms/core/utils/logger.dart';

part 'business_provider.g.dart';

@riverpod
BusinessRemoteDatasource businessRemoteDatasource(BusinessRemoteDatasourceRef ref) {
  return BusinessRemoteDatasourceImpl(Supabase.instance.client);
}

@riverpod
BusinessRepository businessRepository(BusinessRepositoryRef ref) {
  final remote = ref.watch(businessRemoteDatasourceProvider);
  return BusinessRepositoryImpl(remoteDatasource: remote);
}

@riverpod
BranchRepository branchRepository(BranchRepositoryRef ref) {
  final remote = ref.watch(businessRemoteDatasourceProvider);
  return BranchRepositoryImpl(remoteDatasource: remote);
}

// Fetch list of businesses for current user
@riverpod
Future<List<BusinessEntity>> userBusinesses(UserBusinessesRef ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final repo = ref.watch(businessRepositoryProvider);
  final localCache = ref.watch(localCacheServiceProvider);
  final syncState = ref.watch(syncProvider);

  if (!syncState.isOnline) {
    return await localCache.getCachedBusinesses(user.id);
  }

  final result = await repo.getUserBusinesses(user.id);

  return result.fold(
    (failure) async {
      AppLogger.w('Businesses fetch failed: ${failure.message}. Falling back to offline cache.');
      return await localCache.getCachedBusinesses(user.id);
    },
    (businesses) async {
      await localCache.cacheBusinesses(user.id, businesses);
      return businesses;
    },
  );
}

// Current Selected Business State
@riverpod
class CurrentBusiness extends _$CurrentBusiness {
  @override
  BusinessEntity? build() {
    final businessesAsync = ref.watch(userBusinessesProvider);
    return businessesAsync.maybeWhen(
      data: (businesses) => businesses.isNotEmpty ? businesses.first : null,
      orElse: () => null,
    );
  }

  void select(BusinessEntity business) {
    state = business;
  }

  void clear() {
    state = null;
  }
}

// Fetch list of branches for currently active business
@riverpod
Future<List<BranchEntity>> businessBranches(BusinessBranchesRef ref) async {
  final activeBiz = ref.watch(currentBusinessProvider);
  if (activeBiz == null) return [];

  final repo = ref.watch(branchRepositoryProvider);
  final localCache = ref.watch(localCacheServiceProvider);
  final syncState = ref.watch(syncProvider);

  if (!syncState.isOnline) {
    return await localCache.getCachedBranches(activeBiz.id);
  }

  final result = await repo.getBranches(activeBiz.id);

  return result.fold(
    (failure) async {
      AppLogger.w('Branches fetch failed: ${failure.message}. Falling back to offline cache.');
      return await localCache.getCachedBranches(activeBiz.id);
    },
    (branches) async {
      await localCache.cacheBranches(activeBiz.id, branches);
      return branches;
    },
  );
}

// Fetch assigned branch ID for current user in active business (if staff)
final userAssignedBranchIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final activeBiz = ref.watch(currentBusinessProvider);
  if (activeBiz == null) return null;

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    final roleData = await Supabase.instance.client
        .from('user_roles')
        .select('branch_id')
        .eq('business_id', activeBiz.id)
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();

    return roleData?['branch_id'] as String?;
  } catch (_) {
    return null;
  }
});

// Current Selected Branch State
@riverpod
class CurrentBranch extends _$CurrentBranch {
  @override
  BranchEntity? build() {
    final branchesAsync = ref.watch(businessBranchesProvider);
    final assignedBranchId = ref.watch(userAssignedBranchIdProvider).value;

    return branchesAsync.maybeWhen(
      data: (branches) {
        if (branches.isEmpty) return null;
        if (assignedBranchId != null) {
          final assigned = branches.where((b) => b.id == assignedBranchId).firstOrNull;
          if (assigned != null) return assigned;
        }
        return branches.firstWhere((b) => b.isMain, orElse: () => branches.first);
      },
      orElse: () => null,
    );
  }

  void select(BranchEntity branch) {
    state = branch;
  }

  void clear() {
    state = null;
  }
}

// Business controller for actions like creation and updates
@riverpod
class BusinessController extends _$BusinessController {
  @override
  FutureOr<BusinessEntity?> build() => null;

  Future<void> createBusiness({
    required String ownerId,
    required String name,
    required String defaultCurrency,
    required String firstBranchName,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(businessRepositoryProvider);

    final result = await repo.createBusiness(
      ownerId: ownerId,
      name: name,
      defaultCurrency: defaultCurrency,
      firstBranchName: firstBranchName,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (business) {
        ref.read(currentBusinessProvider.notifier).select(business);
        ref.invalidate(userBusinessesProvider);
        return AsyncValue.data(business);
      },
    );
  }

  Future<void> updateBusiness(BusinessEntity business) async {
    state = const AsyncValue.loading();
    final repo = ref.read(businessRepositoryProvider);
    final result = await repo.updateBusiness(business);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (updated) {
        ref.read(currentBusinessProvider.notifier).select(updated);
        ref.invalidate(userBusinessesProvider);
        return AsyncValue.data(updated);
      },
    );
  }
}

// Branch controller for branch management
@riverpod
class BranchController extends _$BranchController {
  @override
  FutureOr<BranchEntity?> build() => null;

  Future<void> createBranch({
    required String businessId,
    required String name,
    required String currency,
    String? address,
    String? phone,
    bool isMain = false,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(branchRepositoryProvider);

    final result = await repo.createBranch(
      businessId: businessId,
      name: name,
      currency: currency,
      address: address,
      phone: phone,
      isMain: isMain,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (branch) {
        ref.invalidate(businessBranchesProvider);
        return AsyncValue.data(branch);
      },
    );
  }

  Future<void> updateBranch(BranchEntity branch) async {
    state = const AsyncValue.loading();
    final repo = ref.read(branchRepositoryProvider);
    final result = await repo.updateBranch(branch);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (updated) {
        ref.invalidate(businessBranchesProvider);
        if (ref.read(currentBranchProvider)?.id == updated.id) {
          ref.read(currentBranchProvider.notifier).select(updated);
        }
        return AsyncValue.data(updated);
      },
    );
  }

  Future<void> deleteBranch(String branchId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(branchRepositoryProvider);
    final result = await repo.deleteBranch(branchId);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) {
        ref.invalidate(businessBranchesProvider);
        return const AsyncValue.data(null);
      },
    );
  }
}
