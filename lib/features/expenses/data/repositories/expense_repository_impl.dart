import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expenses_remote_datasource.dart';
import '../models/expense_model.dart';
import '../models/expense_category_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl({
    required ExpensesRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ExpensesRemoteDataSource _remoteDataSource;

  @override
  Future<List<ExpenseCategoryEntity>> getCategories(String businessId) async {
    return _remoteDataSource.getCategories(businessId);
  }

  @override
  Future<ExpenseCategoryEntity> createCategory({
    required String businessId,
    required String name,
    String? description,
    String icon = 'category',
    String color = '0xFF2196F3',
  }) async {
    final now = DateTime.now();
    final model = ExpenseCategoryModel(
      id: '',
      businessId: businessId,
      name: name,
      description: description,
      icon: icon,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    return _remoteDataSource.createCategory(model);
  }

  @override
  Future<ExpenseCategoryEntity> updateCategory(
    ExpenseCategoryEntity category,
  ) async {
    final model = ExpenseCategoryModel(
      id: category.id,
      businessId: category.businessId,
      name: category.name,
      description: category.description,
      icon: category.icon,
      color: category.color,
      isSystem: category.isSystem,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
    return _remoteDataSource.updateCategory(model);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    return _remoteDataSource.deleteCategory(categoryId);
  }

  @override
  Future<List<ExpenseEntity>> getExpenses({
    required String businessId,
    String? branchId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _remoteDataSource.getExpenses(
      businessId: businessId,
      branchId: branchId,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<ExpenseEntity> createExpense(ExpenseEntity expense) async {
    final model = ExpenseModel(
      id: expense.id,
      businessId: expense.businessId,
      branchId: expense.branchId,
      categoryId: expense.categoryId,
      categoryName: expense.categoryName,
      amount: expense.amount,
      description: expense.description,
      paymentMethod: expense.paymentMethod,
      paymentReference: expense.paymentReference,
      expenseDate: expense.expenseDate,
      receiptUrl: expense.receiptUrl,
      recordedBy: expense.recordedBy,
      recordedByName: expense.recordedByName,
      notes: expense.notes,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
    return _remoteDataSource.createExpense(model);
  }

  @override
  Future<ExpenseEntity> updateExpense(ExpenseEntity expense) async {
    final model = ExpenseModel(
      id: expense.id,
      businessId: expense.businessId,
      branchId: expense.branchId,
      categoryId: expense.categoryId,
      categoryName: expense.categoryName,
      amount: expense.amount,
      description: expense.description,
      paymentMethod: expense.paymentMethod,
      paymentReference: expense.paymentReference,
      expenseDate: expense.expenseDate,
      receiptUrl: expense.receiptUrl,
      recordedBy: expense.recordedBy,
      recordedByName: expense.recordedByName,
      notes: expense.notes,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
    return _remoteDataSource.updateExpense(model);
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    return _remoteDataSource.deleteExpense(expenseId);
  }
}
