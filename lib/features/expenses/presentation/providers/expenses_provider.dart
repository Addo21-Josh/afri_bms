import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/datasources/expenses_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../../core/sync/domain/models/sync_queue_item.dart';

final expensesRemoteDataSourceProvider = Provider<ExpensesRemoteDataSource>((
  ref,
) {
  return ExpensesRemoteDataSourceImpl(supabaseClient: Supabase.instance.client);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final remoteDataSource = ref.watch(expensesRemoteDataSourceProvider);
  return ExpenseRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Categories list provider
final expenseCategoriesProvider =
    AsyncNotifierProvider<
      ExpenseCategoriesNotifier,
      List<ExpenseCategoryEntity>
    >(() {
      return ExpenseCategoriesNotifier();
    });

class ExpenseCategoriesNotifier
    extends AsyncNotifier<List<ExpenseCategoryEntity>> {
  @override
  Future<List<ExpenseCategoryEntity>> build() async {
    final business = ref.watch(currentBusinessProvider);
    if (business == null) return [];
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getCategories(business.id);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// Expense Filter state
class ExpenseFilter {
  const ExpenseFilter({this.categoryId, this.startDate, this.endDate});

  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;

  ExpenseFilter copyWith({
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearCategory = false,
    bool clearDates = false,
  }) {
    return ExpenseFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

final expenseFilterProvider = StateProvider<ExpenseFilter>((ref) {
  final now = DateTime.now();
  // Default to current month: from 1st of month to today
  final startOfMonth = DateTime(now.year, now.month, 1);
  return ExpenseFilter(startDate: startOfMonth, endDate: now);
});

// Expenses list provider
final expensesListProvider =
    AsyncNotifierProvider<ExpensesListNotifier, List<ExpenseEntity>>(() {
      return ExpensesListNotifier();
    });

class ExpensesListNotifier extends AsyncNotifier<List<ExpenseEntity>> {
  @override
  Future<List<ExpenseEntity>> build() async {
    final business = ref.watch(currentBusinessProvider);
    if (business == null) return [];

    final branch = ref.watch(currentBranchProvider);
    final filter = ref.watch(expenseFilterProvider);
    final isOnline = ref.watch(syncProvider.select((s) => s.isOnline));
    final localCache = ref.watch(localCacheServiceProvider);

    if (!isOnline) {
      final cached = await localCache.getCachedExpenses(
        business.id,
        branchId: branch?.id,
      );
      return _applyFilter(cached, filter);
    }

    final repo = ref.watch(expenseRepositoryProvider);

    try {
      final list = await repo.getExpenses(
        businessId: business.id,
        branchId: branch?.id,
        categoryId: filter.categoryId,
        startDate: filter.startDate,
        endDate: filter.endDate,
      );
      if (filter.categoryId == null && filter.startDate == null) {
        await localCache.cacheExpenses(business.id, list);
      }
      return list;
    } catch (_) {
      final cached = await localCache.getCachedExpenses(
        business.id,
        branchId: branch?.id,
      );
      return _applyFilter(cached, filter);
    }
  }

  List<ExpenseEntity> _applyFilter(
    List<ExpenseEntity> list,
    ExpenseFilter filter,
  ) {
    return list.where((e) {
      if (filter.categoryId != null && e.categoryId != filter.categoryId)
        return false;
      if (filter.startDate != null && e.expenseDate.isBefore(filter.startDate!))
        return false;
      if (filter.endDate != null && e.expenseDate.isAfter(filter.endDate!))
        return false;
      return true;
    }).toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// Calculated totals provider
final expensesTotalAmountProvider = Provider<int>((ref) {
  final expenses = ref.watch(expensesListProvider).value ?? [];
  return expenses.fold<int>(0, (sum, item) => sum + item.amount);
});

// Aggregated totals by category for pie/bar charts
final expensesGroupedByCategoryProvider = Provider<Map<String, int>>((ref) {
  final expenses = ref.watch(expensesListProvider).value ?? [];
  final map = <String, int>{};
  for (final exp in expenses) {
    final key = exp.categoryName ?? 'Uncategorized';
    map[key] = (map[key] ?? 0) + exp.amount;
  }
  return map;
});

// Expense Operations Controller
class ExpenseControllerState {
  const ExpenseControllerState({this.isLoading = false, this.errorMessage});
  final bool isLoading;
  final String? errorMessage;
}

final expenseControllerProvider =
    StateNotifierProvider<ExpenseControllerNotifier, ExpenseControllerState>((
      ref,
    ) {
      return ExpenseControllerNotifier(ref);
    });

class ExpenseControllerNotifier extends StateNotifier<ExpenseControllerState> {
  ExpenseControllerNotifier(this._ref) : super(const ExpenseControllerState());

  final Ref _ref;

  Future<bool> createExpense({
    String? categoryId,
    required int amount,
    required String description,
    String paymentMethod = 'cash',
    String? paymentReference,
    required DateTime expenseDate,
    String? receiptUrl,
    String? notes,
  }) async {
    final business = _ref.read(currentBusinessProvider);
    final branch = _ref.read(currentBranchProvider);
    if (business == null || branch == null) return false;

    state = const ExpenseControllerState(isLoading: true);
    final isOnline = _ref.read(syncProvider).isOnline;
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (!isOnline) {
      final offlineId = const Uuid().v4();
      final now = DateTime.now();
      final offlineExpense = ExpenseEntity(
        id: offlineId,
        businessId: business.id,
        branchId: branch.id,
        categoryId: categoryId,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        expenseDate: expenseDate,
        receiptUrl: receiptUrl,
        recordedBy: currentUser?.id,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      final localCache = _ref.read(localCacheServiceProvider);
      await localCache.saveOfflineExpense(business.id, offlineExpense);

      await _ref
          .read(syncProvider.notifier)
          .enqueueOperation(
            table: 'expenses',
            operation: SyncOperation.insert,
            recordId: offlineId,
            payload: {
              'id': offlineId,
              'business_id': business.id,
              'branch_id': branch.id,
              'category_id': categoryId,
              'amount': amount,
              'description': description,
              'payment_method': paymentMethod,
              'payment_reference': paymentReference,
              'expense_date': expenseDate.toIso8601String(),
              'receipt_url': receiptUrl,
              'recorded_by': currentUser?.id,
              'notes': notes,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            },
          );

      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    }

    try {
      final repo = _ref.read(expenseRepositoryProvider);

      final expense = ExpenseEntity(
        id: '',
        businessId: business.id,
        branchId: branch.id,
        categoryId: categoryId,
        amount: amount,
        description: description,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        expenseDate: expenseDate,
        receiptUrl: receiptUrl,
        recordedBy: currentUser?.id,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repo.createExpense(expense);
      await _ref
          .read(localCacheServiceProvider)
          .saveOfflineExpense(business.id, created);
      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = ExpenseControllerState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseEntity expense) async {
    state = const ExpenseControllerState(isLoading: true);
    final business = _ref.read(currentBusinessProvider);
    final isOnline = _ref.read(syncProvider).isOnline;

    if (!isOnline && business != null) {
      final localCache = _ref.read(localCacheServiceProvider);
      await localCache.saveOfflineExpense(business.id, expense);

      await _ref
          .read(syncProvider.notifier)
          .enqueueOperation(
            table: 'expenses',
            operation: SyncOperation.update,
            recordId: expense.id,
            payload: {
              'category_id': expense.categoryId,
              'amount': expense.amount,
              'description': expense.description,
              'payment_method': expense.paymentMethod,
              'payment_reference': expense.paymentReference,
              'expense_date': expense.expenseDate.toIso8601String(),
              'receipt_url': expense.receiptUrl,
              'notes': expense.notes,
              'updated_at': DateTime.now().toIso8601String(),
            },
          );

      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    }

    try {
      final repo = _ref.read(expenseRepositoryProvider);
      final updated = await repo.updateExpense(expense);
      if (business != null) {
        await _ref
            .read(localCacheServiceProvider)
            .saveOfflineExpense(business.id, updated);
      }
      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = ExpenseControllerState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    state = const ExpenseControllerState(isLoading: true);
    final business = _ref.read(currentBusinessProvider);
    final isOnline = _ref.read(syncProvider).isOnline;

    if (!isOnline && business != null) {
      final localCache = _ref.read(localCacheServiceProvider);
      await localCache.deleteOfflineExpense(business.id, expenseId);

      await _ref
          .read(syncProvider.notifier)
          .enqueueOperation(
            table: 'expenses',
            operation: SyncOperation.delete,
            recordId: expenseId,
            payload: {},
          );

      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    }

    try {
      final repo = _ref.read(expenseRepositoryProvider);
      await repo.deleteExpense(expenseId);
      if (business != null) {
        await _ref
            .read(localCacheServiceProvider)
            .deleteOfflineExpense(business.id, expenseId);
      }
      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = ExpenseControllerState(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> createCategory({
    required String name,
    String? description,
    String icon = 'category',
    String color = '0xFF2196F3',
  }) async {
    final business = _ref.read(currentBusinessProvider);
    if (business == null) return false;

    try {
      final repo = _ref.read(expenseRepositoryProvider);
      await repo.createCategory(
        businessId: business.id,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );
      await _ref.read(expenseCategoriesProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = ExpenseControllerState(errorMessage: e.toString());
      return false;
    }
  }
}
