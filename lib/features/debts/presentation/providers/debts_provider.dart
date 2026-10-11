import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../data/datasources/debts_remote_datasource.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';

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
  return const DebtFilter(debtType: DebtType.receivable, status: DebtStatus.active);
});

final debtsListProvider = AsyncNotifierProvider<DebtsListNotifier, List<DebtEntity>>(() {
  return DebtsListNotifier();
});

class DebtsListNotifier extends AsyncNotifier<List<DebtEntity>> {
  @override
  Future<List<DebtEntity>> build() async {
    final business = ref.watch(currentBusinessProvider);
    if (business == null) return [];

    final branch = ref.watch(currentBranchProvider);
    final filter = ref.watch(debtFilterProvider);
    final repo = ref.watch(debtRepositoryProvider);

    final rawList = await repo.getDebts(
      businessId: business.id,
      branchId: branch?.id,
      debtType: filter.debtType,
      status: filter.status,
    );

    var filtered = rawList;

    // Filter by aging bucket if chosen
    if (filter.agingBucket != null) {
      filtered = filtered.where((d) => d.agingBucket == filter.agingBucket).toList();
    }

    // Filter by search query
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

// Single Debt Detail Provider
final debtDetailProvider = FutureProvider.family<DebtEntity, String>((ref, debtId) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getDebtById(debtId);
});

// Payments List for a debt
final debtPaymentsListProvider =
    FutureProvider.family<List<DebtPaymentEntity>, String>((ref, debtId) async {
  final repo = ref.watch(debtRepositoryProvider);
  return repo.getDebtPayments(debtId);
});

// Summary: Total active customer receivables
final totalReceivablesSummaryProvider = FutureProvider<int>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return 0;
  final branch = ref.watch(currentBranchProvider);
  final repo = ref.watch(debtRepositoryProvider);

  final receivables = await repo.getDebts(
    businessId: business.id,
    branchId: branch?.id,
    debtType: DebtType.receivable,
    status: DebtStatus.active,
  );
  return receivables.fold<int>(0, (sum, d) => sum + d.remainingBalance);
});

// Summary: Total active supplier payables
final totalPayablesSummaryProvider = FutureProvider<int>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return 0;
  final branch = ref.watch(currentBranchProvider);
  final repo = ref.watch(debtRepositoryProvider);

  final payables = await repo.getDebts(
    businessId: business.id,
    branchId: branch?.id,
    debtType: DebtType.payable,
    status: DebtStatus.active,
  );
  return payables.fold<int>(0, (sum, d) => sum + d.remainingBalance);
});

// Summary: Aging distribution of receivables for buckets
final receivablesAgingSummaryProvider = FutureProvider<Map<AgingBucket, int>>((ref) async {
  final business = ref.watch(currentBusinessProvider);
  if (business == null) return {};
  final branch = ref.watch(currentBranchProvider);
  final repo = ref.watch(debtRepositoryProvider);

  final list = await repo.getDebts(
    businessId: business.id,
    branchId: branch?.id,
    debtType: DebtType.receivable,
    status: DebtStatus.active,
  );

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

      await repo.createDebt(debt);
      await _ref.read(debtsListProvider.notifier).refresh();
      _ref.invalidate(totalReceivablesSummaryProvider);
      _ref.invalidate(totalPayablesSummaryProvider);
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
    try {
      final repo = _ref.read(debtRepositoryProvider);
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
        remainingBalance: newStatus == DebtStatus.paid ? 0 : debt.remainingBalance,
        dueDate: debt.dueDate,
        status: newStatus,
        notes: debt.notes,
        createdAt: debt.createdAt,
        updatedAt: DateTime.now(),
      );

      await repo.updateDebt(updated);
      await _ref.read(debtsListProvider.notifier).refresh();
      _ref.invalidate(debtDetailProvider(debt.id));
      _ref.invalidate(totalReceivablesSummaryProvider);
      _ref.invalidate(totalPayablesSummaryProvider);
      state = const DebtControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = DebtControllerState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}
