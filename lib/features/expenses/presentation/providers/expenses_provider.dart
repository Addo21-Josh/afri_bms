import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/datasources/expenses_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';

final expensesRemoteDataSourceProvider = Provider<ExpensesRemoteDataSource>((ref) {
  return ExpensesRemoteDataSourceImpl(supabaseClient: Supabase.instance.client);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final remoteDataSource = ref.watch(expensesRemoteDataSourceProvider);
  return ExpenseRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Categories list provider
final expenseCategoriesProvider = AsyncNotifierProvider<ExpenseCategoriesNotifier, List<ExpenseCategoryEntity>>(() {
  return ExpenseCategoriesNotifier();
});

class ExpenseCategoriesNotifier extends AsyncNotifier<List<ExpenseCategoryEntity>> {
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
  const ExpenseFilter({
    this.categoryId,
    this.startDate,
    this.endDate,
  });

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
final expensesListProvider = AsyncNotifierProvider<ExpensesListNotifier, List<ExpenseEntity>>(() {
  return ExpensesListNotifier();
});

class ExpensesListNotifier extends AsyncNotifier<List<ExpenseEntity>> {
  @override
  Future<List<ExpenseEntity>> build() async {
    final business = ref.watch(currentBusinessProvider);
    if (business == null) return [];

    final branch = ref.watch(currentBranchProvider);
    final filter = ref.watch(expenseFilterProvider);
    final repo = ref.watch(expenseRepositoryProvider);

    return repo.getExpenses(
      businessId: business.id,
      branchId: branch?.id,
      categoryId: filter.categoryId,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
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
    StateNotifierProvider<ExpenseControllerNotifier, ExpenseControllerState>((ref) {
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
    try {
      final repo = _ref.read(expenseRepositoryProvider);
      final currentUser = Supabase.instance.client.auth.currentUser;

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

      await repo.createExpense(expense);
      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = ExpenseControllerState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseEntity expense) async {
    state = const ExpenseControllerState(isLoading: true);
    try {
      final repo = _ref.read(expenseRepositoryProvider);
      await repo.updateExpense(expense);
      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = ExpenseControllerState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    state = const ExpenseControllerState(isLoading: true);
    try {
      final repo = _ref.read(expenseRepositoryProvider);
      await repo.deleteExpense(expenseId);
      await _ref.read(expensesListProvider.notifier).refresh();
      state = const ExpenseControllerState(isLoading: false);
      return true;
    } catch (e) {
      state = ExpenseControllerState(isLoading: false, errorMessage: e.toString());
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
