import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../data/datasources/debts_remote_datasource.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../../core/sync/domain/models/sync_queue_item.dart';

final debtsRemoteDataSourceProvider = Provider<DebtsRemoteDataSource>((ref) {
  return DebtsRemoteDataSourceImpl(supabaseClient: Supabase.instance.client);
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final remote = ref.watch(debtsRemoteDataSourceProvider);
  return DebtRepositoryImpl(remoteDataSource: remote);
});

class DebtFilter {
  const DebtFilter({
    this.debtType = DebtType.receivable,
    this.status = DebtStatus.active,
    this.agingBucket,
    this.searchQuery = '',
  });

  final DebtType debtType;
  final DebtStatus? status;
  final AgingBucket? agingBucket;
  final String searchQuery;

  DebtFilter copyWith({
    DebtType? debtType,
    DebtStatus? status,
    bool clearStatus = false,
    AgingBucket? agingBucket,
    bool clearAging = false,
    String? searchQuery,
  }) {
    return DebtFilter(
      debtType: debtType ?? this.debtType,
      status: clearStatus ? null : (status ?? this.status),
      agingBucket: clearAging ? null : (agingBucket ?? this.agingBucket),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final debtFilterProvider = StateProvider<DebtFilter>((ref) {
  return const DebtFilter(
    debtType: DebtType.receivable,
    status: DebtStatus.active,
  );
});

final debtsListProvider =
    AsyncNotifierProvider<DebtsListNotifier, List<DebtEntity>>(() {
      return DebtsListNotifier();
    });

class DebtsListNotifier extends AsyncNotifier<List<DebtEntity>> {
  @override
  Future<List<DebtEntity>> build() async {
    final business = ref.watch(currentBusinessProvider);
    if (business == null) return [];

    final branch = ref.watch(currentBranchProvider);
    final filter = ref.watch(debtFilterProvider);
    final isOnline = ref.watch(syncProvider.select((s) => s.isOnline));
    final localCache = ref.watch(localCacheServiceProvider);

    if (!isOnline) {
      final cached = await localCache.getCachedDebts(
        business.id,
        branchId: branch?.id,
      );
      return _filterDebts(cached, filter);
    }

    final repo = ref.watch(debtRepositoryProvider);

    try {
      final rawList = await repo.getDebts(
        businessId: business.id,
        branchId: branch?.id,
        debtType: filter.debtType,
        status: filter.status,
      );

      // Cache the raw list when no extra filters are applied
      await localCache.cacheDebts(business.id, rawList);
      return _filterDebts(rawList, filter);
    } catch (_) {
      final cached = await localCache.getCachedDebts(
        business.id,
        branchId: branch?.id,
      );
      return _filterDebts(cached, filter);
    }
  }

  List<DebtEntity> _filterDebts(List<DebtEntity> rawList, DebtFilter filter) {
    var filtered = rawList.where((d) => d.debtType == filter.debtType).toList();

    if (filter.status != null) {
      filtered = filtered.where((d) => d.status == filter.status).toList();
    }

    if (filter.agingBucket != null) {
      filtered = filtered
          .where((d) => d.agingBucket == filter.agingBucket)
          .toList();
    }

    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.toLowerCase().trim();
      filtered = filtered.where((d) {
        return d.personName.toLowerCase().contains(q) ||
            (d.personPhone != null && d.personPhone!.contains(q));
      }).toList();
    }

    return filtered;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// Single Debt Detail Provider with offline cache fallback
final debtDetailProvider = FutureProvider.family<DebtEntity, String>((
  ref,
  debtId,
) async {
  final business = ref.watch(currentBusinessProvider);
  final isOnline = ref.watch(syncProvider.select((s) => s.isOnline));
  final localCache = ref.watch(localCacheServiceProvider);

  if (!isOnline && business != null) {
    final cached = await localCache.getCachedDebtById(business.id, debtId);
    if (cached != null) return cached;
  }

  final repo = ref.watch(debtRepositoryProvider);
  try {
    return await repo.getDebtById(debtId);
  } catch (e) {
    if (business != null) {
      final cached = await localCache.getCachedDebtById(business.id, debtId);
      if (cached != null) return cached;
    }
    rethrow;
  }
});

// Payments List for a debt
final debtPaymentsListProvider =
    FutureProvider.family<List<DebtPaymentEntity>, String>((ref, debtId) async {
      final repo = ref.watch(debtRepositoryProvider);
      try {
        return await repo.getDebtPayments(debtId);
      } catch (_) {
        return [];
      }
    });

// Summary: Total active customer receivables with offline fallback
final totalReceivablesSummaryProvider = FutureProvider<int>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return 0;
  final branch = ref.watch(currentBranchProvider);
  final isOnline = ref.watch(syncProvider.select((s) => s.isOnline));
  final localCache = ref.watch(localCacheServiceProvider);

  if (!isOnline) {
    final cached = await localCache.getCachedDebts(
      business.id,
      branchId: branch?.id,
    );
    return cached
        .where(
          (d) =>
              d.debtType == DebtType.receivable &&
              d.status == DebtStatus.active,
        )
        .fold<int>(0, (sum, d) => sum + d.remainingBalance);
  }

  try {
    final repo = ref.watch(debtRepositoryProvider);
    final receivables = await repo.getDebts(
      businessId: business.id,
      branchId: branch?.id,
      debtType: DebtType.receivable,
      status: DebtStatus.active,
    );
    return receivables.fold<int>(0, (sum, d) => sum + d.remainingBalance);
  } catch (_) {
    final cached = await localCache.getCachedDebts(
      business.id,
      branchId: branch?.id,
    );
    return cached
        .where(
          (d) =>
              d.debtType == DebtType.receivable &&
              d.status == DebtStatus.active,
        )
        .fold<int>(0, (sum, d) => sum + d.remainingBalance);
  }
});

// Summary: Total active supplier payables with offline fallback
final totalPayablesSummaryProvider = FutureProvider<int>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return 0;
  final branch = ref.watch(currentBranchProvider);
  final isOnline = ref.watch(syncProvider.select((s) => s.isOnline));
  final localCache = ref.watch(localCacheServiceProvider);

  if (!isOnline) {
    final cached = await localCache.getCachedDebts(
      business.id,
      branchId: branch?.id,
    );
    return cached
        .where(
          (d) =>
              d.debtType == DebtType.payable && d.status == DebtStatus.active,
        )
        .fold<int>(0, (sum, d) => sum + d.remainingBalance);
  }

  try {
    final repo = ref.watch(debtRepositoryProvider);
    final payables = await repo.getDebts(
      businessId: business.id,
      branchId: branch?.id,
      debtType: DebtType.payable,
      status: DebtStatus.active,
    );
    return payables.fold<int>(0, (sum, d) => sum + d.remainingBalance);
  } catch (_) {
    final cached = await localCache.getCachedDebts(
      business.id,
      branchId: branch?.id,
    );
    return cached
        .where(
          (d) =>
              d.debtType == DebtType.payable && d.status == DebtStatus.active,
        )
        .fold<int>(0, (sum, d) => sum + d.remainingBalance);
  }
});

// Summary: Aging distribution of receivables for buckets
final receivablesAgingSummaryProvider = FutureProvider<Map<AgingBucket, int>>((
  ref,
) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return {};
  final branch = ref.watch(currentBranchProvider);
  final isOnline = ref.watch(syncProvider.select((s) => s.isOnline));
  final localCache = ref.watch(localCacheServiceProvider);

  List<DebtEntity> list = [];
  if (!isOnline) {
    final cached = await localCache.getCachedDebts(
      business.id,
      branchId: branch?.id,
    );
    list = cached
        .where(
          (d) =>
              d.debtType == DebtType.receivable &&
              d.status == DebtStatus.active,
        )
        .toList();
  } else {
    try {
      final repo = ref.watch(debtRepositoryProvider);
      list = await repo.getDebts(
        businessId: business.id,
        branchId: branch?.id,
        debtType: DebtType.receivable,
        status: DebtStatus.active,
      );
    } catch (_) {
      final cached = await localCache.getCachedDebts(
        business.id,
        branchId: branch?.id,
      );
      list = cached
          .where(
            (d) =>
                d.debtType == DebtType.receivable &&
                d.status == DebtStatus.active,
          )
          .toList();
    }
  }

  final map = {
    AgingBucket.current: 0,
    AgingBucket.thirtyDays: 0,
    AgingBucket.sixtyDays: 0,
    AgingBucket.ninetyDaysPlus: 0,
  };

  for (final d in list) {
    map[d.agingBucket] = (map[d.agingBucket] ?? 0) + d.remainingBalance;
  }
  return map;
});

// Operations Controller
class DebtControllerState {
  const DebtControllerState({this.isLoading = false, this.errorMessage});
  final bool isLoading;
  final String? errorMessage;
}

final debtControllerProvider =
    StateNotifierProvider<DebtControllerNotifier, DebtControllerState>((ref) {
      return DebtControllerNotifier(ref);
    });

class DebtControllerNotifier extends StateNotifier<DebtControllerState> {
  DebtControllerNotifier(this._ref) : super(const DebtControllerState());

  final Ref _ref;

  Future<bool> createDebt({
    required DebtType debtType,
    String? customerId,
    String? supplierId,
    String? saleId,
    required String personName,
    String? personPhone,
    required int amount,
    DateTime? dueDate,
    String? notes,
  }) async {
    final business = _ref.read(currentBusinessProvider);
    final branch = _ref.read(currentBranchProvider);
    if (business == null || branch == null) return false;

    state = const DebtControllerState(isLoading: true);
    final isOnline = _ref.read(syncProvider).isOnline;

    if (!isOnline) {
      final offlineId = const Uuid().v4();
      final now = DateTime.now();
      final offlineDebt = DebtEntity(
        id: offlineId,
        businessId: business.id,
        branchId: branch.id,
        debtType: debtType,
        customerId: customerId,
        supplierId: supplierId,
        saleId: saleId,
        personName: personName,
        personPhone: personPhone,
        initialAmount: amount,
        remainingBalance: amount,
        dueDate: dueDate,
        status: DebtStatus.active,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      final localCache = _ref.read(localCacheServiceProvider);
      await localCache.saveOfflineDebt(business.id, offlineDebt);

      await _ref
          .read(syncProvider.notifier)
          .enqueueOperation(
            table: 'debts',
            operation: SyncOperation.insert,
            recordId: offlineId,
            payload: {
              'id': offlineId,
              'business_id': business.id,
              'branch_id': branch.id,
              'debt_type': debtType.name,
              'customer_id': customerId,
              'supplier_id': supplierId,
              'sale_id': saleId,
              'person_name': personName,
              'person_phone': personPhone,
              'initial_amount': amount,
              'remaining_balance': amount,
              'due_date': dueDate?.toIso8601String(),
              'status': DebtStatus.active.name,
              'notes': notes,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            },
          );

      await _ref.read(debtsListProvider.notifier).refresh();
      _ref.invalidate(totalReceivablesSummaryProvider);
      _ref.invalidate(totalPayablesSummaryProvider);
      _ref.invalidate(receivablesAgingSummaryProvider);
      state = const DebtControllerState(isLoading: false);
      return true;
    }

    try {
      final repo = _ref.read(debtRepositoryProvider);
      final debt = DebtEntity(
        id: '',
        businessId: business.id,
        branchId: branch.id,
        debtType: debtType,
        customerId: customerId,
        supplierId: supplierId,
        saleId: saleId,
        personName: personName,
        personPhone: personPhone,
        initialAmount: amount,
        remainingBalance: amount,
        dueDate: dueDate,
        status: DebtStatus.active,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repo.createDebt(debt);
      await _ref
          .read(localCacheServiceProvider)
          .saveOfflineDebt(business.id, created);
      await _ref.read(debtsListProvider.notifier).refresh();
      _ref.invalidate(totalReceivablesSummaryProvider);
      _ref.invalidate(totalPayablesSummaryProvider);
      _ref.invalidate(receivablesAgingSummaryProvider);
      state = const DebtControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = DebtControllerState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> recordPayment({
    required String debtId,
    required int amount,
    String paymentMethod = 'cash',
    String? paymentReference,
    String? notes,
  }) async {
    final business = _ref.read(currentBusinessProvider);
    if (business == null) return false;

    state = const DebtControllerState(isLoading: true);
    final isOnline = _ref.read(syncProvider).isOnline;

    if (!isOnline) {
      final localCache = _ref.read(localCacheServiceProvider);
      final cachedDebt = await localCache.getCachedDebtById(
        business.id,
        debtId,
      );

      if (cachedDebt != null) {
        final newRemaining = (cachedDebt.remainingBalance - amount).clamp(
          0,
          cachedDebt.initialAmount,
        );
        final newStatus = newRemaining == 0
            ? DebtStatus.paid
            : DebtStatus.active;
        final updatedDebt = DebtEntity(
          id: cachedDebt.id,
          businessId: cachedDebt.businessId,
          branchId: cachedDebt.branchId,
          debtType: cachedDebt.debtType,
          customerId: cachedDebt.customerId,
          supplierId: cachedDebt.supplierId,
          saleId: cachedDebt.saleId,
          personName: cachedDebt.personName,
          personPhone: cachedDebt.personPhone,
          initialAmount: cachedDebt.initialAmount,
          remainingBalance: newRemaining,
          dueDate: cachedDebt.dueDate,
          status: newStatus,
          notes: cachedDebt.notes,
          createdAt: cachedDebt.createdAt,
          updatedAt: DateTime.now(),
        );

        await localCache.saveOfflineDebt(business.id, updatedDebt);

        final paymentId = const Uuid().v4();
        final now = DateTime.now();

        await _ref
            .read(syncProvider.notifier)
            .enqueueOperation(
              table: 'debt_payments',
              operation: SyncOperation.insert,
              recordId: paymentId,
              payload: {
                'id': paymentId,
                'business_id': business.id,
                'debt_id': debtId,
                'amount': amount,
                'payment_method': paymentMethod,
                'payment_reference': paymentReference,
                'notes': notes,
                'created_at': now.toIso8601String(),
              },
            );

        await _ref
            .read(syncProvider.notifier)
            .enqueueOperation(
              table: 'debts',
              operation: SyncOperation.update,
              recordId: debtId,
              payload: {
                'remaining_balance': newRemaining,
                'status': newStatus.name,
                'updated_at': now.toIso8601String(),
              },
            );

        await _ref.read(debtsListProvider.notifier).refresh();
        _ref.invalidate(debtDetailProvider(debtId));
        _ref.invalidate(debtPaymentsListProvider(debtId));
        _ref.invalidate(totalReceivablesSummaryProvider);
        _ref.invalidate(totalPayablesSummaryProvider);
        _ref.invalidate(receivablesAgingSummaryProvider);
        state = const DebtControllerState(isLoading: false);
        return true;
      }
    }

    try {
      final repo = _ref.read(debtRepositoryProvider);
      await repo.recordDebtPayment(
        businessId: business.id,
        debtId: debtId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        notes: notes,
      );

      // Refresh debt from repo to update local cache
      try {
        final updated = await repo.getDebtById(debtId);
        await _ref
            .read(localCacheServiceProvider)
            .saveOfflineDebt(business.id, updated);
      } catch (_) {}

      await _ref.read(debtsListProvider.notifier).refresh();
      _ref.invalidate(debtDetailProvider(debtId));
      _ref.invalidate(debtPaymentsListProvider(debtId));
      _ref.invalidate(totalReceivablesSummaryProvider);
      _ref.invalidate(totalPayablesSummaryProvider);
      _ref.invalidate(receivablesAgingSummaryProvider);
      state = const DebtControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = DebtControllerState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateDebtStatus(DebtEntity debt, DebtStatus newStatus) async {
    state = const DebtControllerState(isLoading: true);
    final isOnline = _ref.read(syncProvider).isOnline;
    final business = _ref.read(currentBusinessProvider);

    final updated = DebtEntity(
      id: debt.id,
      businessId: debt.businessId,
      branchId: debt.branchId,
      debtType: debt.debtType,
      customerId: debt.customerId,
      supplierId: debt.supplierId,
      saleId: debt.saleId,
      personName: debt.personName,
      personPhone: debt.personPhone,
      initialAmount: debt.initialAmount,
      remainingBalance: newStatus == DebtStatus.paid
          ? 0
          : debt.remainingBalance,
      dueDate: debt.dueDate,
      status: newStatus,
      notes: debt.notes,
      createdAt: debt.createdAt,
      updatedAt: DateTime.now(),
    );

    if (!isOnline && business != null) {
      final localCache = _ref.read(localCacheServiceProvider);
      await localCache.saveOfflineDebt(business.id, updated);

      await _ref
          .read(syncProvider.notifier)
          .enqueueOperation(
            table: 'debts',
            operation: SyncOperation.update,
            recordId: debt.id,
            payload: {
              'remaining_balance': updated.remainingBalance,
              'status': newStatus.name,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );

      await _ref.read(debtsListProvider.notifier).refresh();
      _ref.invalidate(debtDetailProvider(debt.id));
      _ref.invalidate(totalReceivablesSummaryProvider);
      _ref.invalidate(totalPayablesSummaryProvider);
      _ref.invalidate(receivablesAgingSummaryProvider);
      state = const DebtControllerState(isLoading: false);
      return true;
    }

    try {
      final repo = _ref.read(debtRepositoryProvider);
      await repo.updateDebt(updated);

      if (business != null) {
        await _ref
            .read(localCacheServiceProvider)
            .saveOfflineDebt(business.id, updated);
      }

      await _ref.read(debtsListProvider.notifier).refresh();
      _ref.invalidate(debtDetailProvider(debt.id));
      _ref.invalidate(totalReceivablesSummaryProvider);
      _ref.invalidate(totalPayablesSummaryProvider);
      _ref.invalidate(receivablesAgingSummaryProvider);
      state = const DebtControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = DebtControllerState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
