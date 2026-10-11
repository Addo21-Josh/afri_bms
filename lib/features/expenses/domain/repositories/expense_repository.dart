import '../entities/expense_entity.dart';
import '../entities/expense_category_entity.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseCategoryEntity>> getCategories(String businessId);
  Future<ExpenseCategoryEntity> createCategory({
    required String businessId,
    required String name,
    String? description,
    String icon = 'category',
    String color = '0xFF2196F3',
  });
  Future<ExpenseCategoryEntity> updateCategory(ExpenseCategoryEntity category);
  Future<void> deleteCategory(String categoryId);

  Future<List<ExpenseEntity>> getExpenses({
    required String businessId,
    String? branchId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<ExpenseEntity> createExpense(ExpenseEntity expense);
  Future<ExpenseEntity> updateExpense(ExpenseEntity expense);
  Future<void> deleteExpense(String expenseId);
}
