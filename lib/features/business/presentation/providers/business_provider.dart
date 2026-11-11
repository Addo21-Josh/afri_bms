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
BusinessRemoteDatasource businessRemoteDatasource(
  BusinessRemoteDatasourceRef ref,
) {
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
  final localCache = ref.watch(localCacheServiceProvider);
  final syncState = ref.watch(syncProvider);

  // Determine the effective user ID — use Supabase auth first,
  // then fall back to cached user ID for offline resilience.
  String? userId = user?.id;

  if (userId != null) {
    // Cache this user ID for future offline access
    await localCache.cacheLastUserId(userId);
  } else {
    // Offline or session expired — use the last known user ID
    userId = await localCache.getLastUserId();
    AppLogger.i(
      'Offline fallback: using cached user ID ($userId) for business loading',
    );
  }

  // If offline or without Supabase auth user, ALWAYS load cached businesses
  if (!syncState.isOnline || userId == null) {
    final cached = await localCache.getCachedBusinesses(userId);
    if (cached.isNotEmpty) {
      return cached;
    }
    // Fallback: Check if a single active business was cached
    final activeBiz = await localCache.getActiveBusiness();
    if (activeBiz != null) {
      return [activeBiz];
    }
    if (userId == null) return [];
  }

  final repo = ref.watch(businessRepositoryProvider);
  final result = await repo.getUserBusinesses(userId);

  return result.fold(
    (failure) async {
      AppLogger.w(
        'Businesses fetch failed: ${failure.message}. Falling back to offline cache.',
      );
      final cached = await localCache.getCachedBusinesses(userId);
      if (cached.isNotEmpty) return cached;
      final activeBiz = await localCache.getActiveBusiness();
      if (activeBiz != null) return [activeBiz];
      return [];
    },
    (businesses) async {
      if (businesses.isNotEmpty) {
        await localCache.cacheBusinesses(userId!, businesses);
      }
      return businesses;
    },
  );
}

// Provider to load the user's previously chosen active business ID from cache
final savedBusinessIdProvider = FutureProvider<String?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  final localCache = ref.watch(localCacheServiceProvider);
  String? userId = user?.id;

  if (userId == null) {
    // Offline fallback — try cached user ID
    userId = await localCache.getLastUserId();
  }
  return await localCache.getSelectedBusinessId(userId);
});

// Current Selected Business State
@riverpod
class CurrentBusiness extends _$CurrentBusiness {
  BusinessEntity? _lastKnown;
  String? _manualSelectedId;

  @override
  BusinessEntity? build() {
    final businessesAsync = ref.watch(userBusinessesProvider);
    final savedId =
        ref.watch(savedBusinessIdProvider).value ?? _manualSelectedId;

    return businessesAsync.maybeWhen(
      data: (businesses) {
        if (businesses.isEmpty) {
          // Fallback to synchronous in-memory cached active business if available
          _lastKnown = ref
              .watch(localCacheServiceProvider)
              .getActiveBusinessSync();
          return _lastKnown;
        }
        BusinessEntity selected;
        if (savedId != null) {
          final matched = businesses.where((b) => b.id == savedId).firstOrNull;
          selected = matched ?? businesses.first;
        } else {
          selected = businesses.first;
        }
        ref.read(localCacheServiceProvider).cacheActiveBusiness(selected);
        _lastKnown = selected;
        return selected;
      },
      // CRITICAL: Preserve state using _lastKnown (NOT state) to avoid uninitialized provider error!
      orElse: () =>
          _lastKnown ??
          ref.watch(localCacheServiceProvider).getActiveBusinessSync(),
    );
  }

  void select(BusinessEntity business) async {
    _manualSelectedId = business.id;
    _lastKnown = business;
    state = business;
    ref.read(localCacheServiceProvider).cacheActiveBusiness(business);
    final user = Supabase.instance.client.auth.currentUser;
    final userId =
        user?.id ?? await ref.read(localCacheServiceProvider).getLastUserId();
    if (userId != null) {
      await ref
          .read(localCacheServiceProvider)
          .saveSelectedBusinessId(userId, business.id);
      ref.invalidate(savedBusinessIdProvider);
    }
  }

  void clear() async {
    _manualSelectedId = null;
    _lastKnown = null;
    state = null;
    final user = Supabase.instance.client.auth.currentUser;
    final userId =
        user?.id ?? await ref.read(localCacheServiceProvider).getLastUserId();
    if (userId != null) {
      await ref.read(localCacheServiceProvider).clearSelectedBusinessId(userId);
      ref.invalidate(savedBusinessIdProvider);
    }
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
    final cached = await localCache.getCachedBranches(activeBiz.id);
    if (cached.isNotEmpty) return cached;
    // Fallback: create default main branch if offline so nothing downstream breaks
    return [
      BranchEntity(
        id: 'main_${activeBiz.id}',
        businessId: activeBiz.id,
        name: 'Main Branch',
        currency: activeBiz.defaultCurrency,
        isMain: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  final result = await repo.getBranches(activeBiz.id);

  return result.fold(
    (failure) async {
      AppLogger.w(
        'Branches fetch failed: ${failure.message}. Falling back to offline cache.',
      );
      final cached = await localCache.getCachedBranches(activeBiz.id);
      if (cached.isNotEmpty) return cached;
      return [
        BranchEntity(
          id: 'main_${activeBiz.id}',
          businessId: activeBiz.id,
          name: 'Main Branch',
          currency: activeBiz.defaultCurrency,
          isMain: true,
          createdAt: DateTime.now(),
        ),
      ];
    },
    (branches) async {
      if (branches.isNotEmpty) {
        await localCache.cacheBranches(activeBiz.id, branches);
      }
      return branches;
    },
  );
}

// Fetch assigned branch ID for current user in active business (if staff)
final userAssignedBranchIdProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final activeBiz = ref.watch(currentBusinessProvider);
  if (activeBiz == null) return null;

  final syncState = ref.watch(syncProvider);
  if (!syncState.isOnline) return null;

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
  BranchEntity? _lastKnown;
  String? _manualSelectedId;

  @override
  BranchEntity? build() {
    final branchesAsync = ref.watch(businessBranchesProvider);
    final assignedBranchId = ref.watch(userAssignedBranchIdProvider).value;

    return branchesAsync.maybeWhen(
      data: (branches) {
        if (branches.isEmpty) {
          _lastKnown = ref
              .watch(localCacheServiceProvider)
              .getActiveBranchSync();
          return _lastKnown;
        }
        BranchEntity selected;
        if (_manualSelectedId != null) {
          final matched = branches
              .where((b) => b.id == _manualSelectedId)
              .firstOrNull;
          selected = matched ?? branches.first;
        } else if (assignedBranchId != null) {
          final assigned = branches
              .where((b) => b.id == assignedBranchId)
              .firstOrNull;
          selected =
              assigned ??
              branches.firstWhere(
                (b) => b.isMain,
                orElse: () => branches.first,
              );
        } else {
          selected = branches.firstWhere(
            (b) => b.isMain,
            orElse: () => branches.first,
          );
        }
        ref.read(localCacheServiceProvider).cacheActiveBranch(selected);
        _lastKnown = selected;
        return selected;
      },
      // CRITICAL: Preserve state using _lastKnown (NOT state) to avoid uninitialized provider error!
      orElse: () =>
          _lastKnown ??
          ref.watch(localCacheServiceProvider).getActiveBranchSync(),
    );
  }

  void select(BranchEntity branch) {
    _manualSelectedId = branch.id;
    _lastKnown = branch;
    state = branch;
    ref.read(localCacheServiceProvider).cacheActiveBranch(branch);
  }

  void clear() {
    _manualSelectedId = null;
    _lastKnown = null;
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

  Future<bool> deleteBusiness(String businessId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(businessRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;

    final result = await repo.deleteBusiness(businessId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) async {
        final effectiveUserId =
            user?.id ??
            await ref.read(localCacheServiceProvider).getLastUserId();
        if (effectiveUserId != null) {
          await ref
              .read(localCacheServiceProvider)
              .removeCachedBusiness(effectiveUserId, businessId);
        }
        final current = ref.read(currentBusinessProvider);
        if (current?.id == businessId) {
          ref.read(currentBusinessProvider.notifier).clear();
        }
        ref.invalidate(userBusinessesProvider);
        ref.invalidate(savedBusinessIdProvider);
        state = const AsyncValue.data(null);
        return true;
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
