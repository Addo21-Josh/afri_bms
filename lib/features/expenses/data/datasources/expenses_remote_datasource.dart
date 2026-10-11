import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';
import '../models/expense_category_model.dart';

abstract class ExpensesRemoteDataSource {
  Future<List<ExpenseCategoryModel>> getCategories(String businessId);
  Future<ExpenseCategoryModel> createCategory(ExpenseCategoryModel category);
  Future<ExpenseCategoryModel> updateCategory(ExpenseCategoryModel category);
  Future<void> deleteCategory(String categoryId);

  Future<List<ExpenseModel>> getExpenses({
    required String businessId,
    String? branchId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String expenseId);
}

class ExpensesRemoteDataSourceImpl implements ExpensesRemoteDataSource {
  ExpensesRemoteDataSourceImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  final SupabaseClient _supabaseClient;

  // Default fallback categories
  static final List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Rent & Utilities', 'icon': 'apartment', 'color': '0xFF3F51B5'},
    {'name': 'Salaries & Wages', 'icon': 'people', 'color': '0xFF4CAF50'},
    {'name': 'Transportation & Fuel', 'icon': 'local_shipping', 'color': '0xFFFF9800'},
    {'name': 'Inventory & Stock Supplies', 'icon': 'inventory_2', 'color': '0xFF9C27B0'},
    {'name': 'Marketing & Promotion', 'icon': 'campaign', 'color': '0xFFE91E63'},
    {'name': 'Repairs & Maintenance', 'icon': 'build', 'color': '0xFF795548'},
    {'name': 'Office & General Expenses', 'icon': 'store', 'color': '0xFF009688'},
    {'name': 'Miscellaneous', 'icon': 'more_horiz', 'color': '0xFF607D8B'},
  ];

  @override
  Future<List<ExpenseCategoryModel>> getCategories(String businessId) async {
    try {
      final res = await _supabaseClient
          .from('expense_categories')
          .select()
          .eq('business_id', businessId)
          .order('name');

      final list = (res as List)
          .map((item) => ExpenseCategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // If business has no categories yet, automatically seed default categories
      if (list.isEmpty) {
        final seeded = await _seedDefaultCategories(businessId);
        if (seeded.isNotEmpty) return seeded;
      }

      return list;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.message.contains('does not exist')) {
        return _fallbackCategories(businessId);
      }
      rethrow;
    } catch (_) {
      return _fallbackCategories(businessId);
    }
  }

  Future<List<ExpenseCategoryModel>> _seedDefaultCategories(String businessId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final inserts = _defaultCategories.map((cat) => {
        'business_id': businessId,
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'is_system': true,
        'created_at': now,
        'updated_at': now,
      }).toList();

      final res = await _supabaseClient
          .from('expense_categories')
          .insert(inserts)
          .select();

      return (res as List)
          .map((item) => ExpenseCategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallbackCategories(businessId);
    }
  }

  List<ExpenseCategoryModel> _fallbackCategories(String businessId) {
    final now = DateTime.now();
    return _defaultCategories.map((cat) => ExpenseCategoryModel(
      id: 'default-${cat['name']}',
      businessId: businessId,
      name: cat['name'] as String,
      icon: cat['icon'] as String,
      color: cat['color'] as String,
      isSystem: true,
      createdAt: now,
      updatedAt: now,
    )).toList();
  }

  @override
  Future<ExpenseCategoryModel> createCategory(ExpenseCategoryModel category) async {
    final res = await _supabaseClient
        .from('expense_categories')
        .insert(category.toInsertJson())
        .select()
        .single();
    return ExpenseCategoryModel.fromJson(res);
  }

  @override
  Future<ExpenseCategoryModel> updateCategory(ExpenseCategoryModel category) async {
    final res = await _supabaseClient
        .from('expense_categories')
        .update({
          'name': category.name,
          'description': category.description,
          'icon': category.icon,
          'color': category.color,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', category.id)
        .select()
        .single();
    return ExpenseCategoryModel.fromJson(res);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _supabaseClient.from('expense_categories').delete().eq('id', categoryId);
  }

  @override
  Future<List<ExpenseModel>> getExpenses({
    required String businessId,
    String? branchId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabaseClient
          .from('expenses')
          .select('*, expense_categories(name)')
          .eq('business_id', businessId);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }
      if (startDate != null) {
        query = query.gte('expense_date', startDate.toIso8601String().substring(0, 10));
      }
      if (endDate != null) {
        query = query.lte('expense_date', endDate.toIso8601String().substring(0, 10));
      }

      final res = await query.order('expense_date', ascending: false).order('created_at', ascending: false);
      return (res as List)
          .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.message.contains('does not exist')) {
        return [];
      }
      rethrow;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final res = await _supabaseClient
        .from('expenses')
        .insert(expense.toInsertJson())
        .select('*, expense_categories(name)')
        .single();
    return ExpenseModel.fromJson(res);
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    final res = await _supabaseClient
        .from('expenses')
        .update({
          if (expense.categoryId != null) 'category_id': expense.categoryId,
          'amount': expense.amount,
          'description': expense.description,
          'payment_method': expense.paymentMethod,
          'payment_reference': expense.paymentReference,
          'expense_date': expense.expenseDate.toIso8601String().substring(0, 10),
          'receipt_url': expense.receiptUrl,
          'notes': expense.notes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', expense.id)
        .select('*, expense_categories(name)')
        .single();
    return ExpenseModel.fromJson(res);
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _supabaseClient.from('expenses').delete().eq('id', expenseId);
  }
}
