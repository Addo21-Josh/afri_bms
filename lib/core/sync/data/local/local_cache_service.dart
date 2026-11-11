import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:afri_bms/core/utils/logger.dart';
import 'package:afri_bms/features/inventory/domain/entities/product_entity.dart';
import 'package:afri_bms/features/inventory/domain/entities/category_entity.dart';
import 'package:afri_bms/features/inventory/data/models/product_model.dart';
import 'package:afri_bms/features/inventory/data/models/category_model.dart';
import 'package:afri_bms/features/customers/domain/entities/customer_entity.dart';
import 'package:afri_bms/features/customers/data/models/customer_model.dart';
import 'package:afri_bms/features/sales/domain/entities/sale_entity.dart';
import 'package:afri_bms/features/sales/data/models/sale_model.dart';
import 'package:afri_bms/features/business/domain/entities/business_entity.dart';
import 'package:afri_bms/features/business/domain/entities/branch_entity.dart';
import 'package:afri_bms/features/business/data/models/business_model.dart';
import 'package:afri_bms/features/business/data/models/branch_model.dart';
import 'package:afri_bms/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:afri_bms/features/suppliers/data/models/supplier_model.dart';
import 'package:afri_bms/features/expenses/domain/entities/expense_entity.dart';
import 'package:afri_bms/features/expenses/data/models/expense_model.dart';
import 'package:afri_bms/features/debts/domain/entities/debt_entity.dart';
import 'package:afri_bms/features/debts/data/models/debt_model.dart';

class LocalCacheService {
  static const String _cacheFileName = 'afri_offline_cache.json';
  File? _cacheFile;
  static Map<String, dynamic> _memoryCache = {};

  Future<File> _getFile() async {
    if (_cacheFile != null) return _cacheFile!;
    final directory = await getApplicationDocumentsDirectory();
    _cacheFile = File('${directory.path}/$_cacheFileName');
    if (!await _cacheFile!.exists()) {
      await _cacheFile!.writeAsString(jsonEncode({}), flush: true);
    }
    return _cacheFile!;
  }

  Future<Map<String, dynamic>> _readCache() async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      if (content.isEmpty) {
        return _memoryCache;
      }
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      _memoryCache = parsed;
      return parsed;
    } catch (e) {
      AppLogger.w('Failed to read offline cache: $e');
      return _memoryCache;
    }
  }

  Future<void> _writeCache(Map<String, dynamic> data) async {
    _memoryCache = data;
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      AppLogger.e('Failed to write offline cache: $e');
    }
  }

  /// Synchronous retrieval of active business from in-memory cache (zero async delay)
  BusinessEntity? getActiveBusinessSync() {
    final json = _memoryCache['last_active_business'] as Map<String, dynamic>?;
    if (json == null) return null;
    try {
      return BusinessModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  /// Synchronous retrieval of active branch from in-memory cache (zero async delay)
  BranchEntity? getActiveBranchSync() {
    final json = _memoryCache['last_active_branch'] as Map<String, dynamic>?;
    if (json == null) return null;
    try {
      return BranchModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  // ─── PRODUCTS CACHE ───
  Future<void> cacheProducts(
    String businessId,
    List<ProductEntity> products,
  ) async {
    final cache = await _readCache();
    final jsonList = products
        .map((p) => ProductModel.fromEntity(p).toCacheJson())
        .toList();
    cache['products_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<ProductEntity>> getCachedProducts(
    String businessId, {
    String? branchId,
  }) async {
    final cache = await _readCache();
    final list = cache['products_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list.map((json) {
        final map = json as Map<String, dynamic>;
        final model = ProductModel.fromJson(map);
        return model.toEntity(
          currentBranchId: branchId,
          cachedBranchStock: (map['current_branch_stock'] as num?)?.toInt(),
        );
      }).toList();
    } catch (e) {
      AppLogger.w('Error parsing cached products: $e');
      return [];
    }
  }

  Future<ProductEntity?> getCachedProductById(
    String businessId,
    String productId, {
    String? branchId,
  }) async {
    final products = await getCachedProducts(businessId, branchId: branchId);
    try {
      return products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOfflineProduct(
    String businessId,
    ProductEntity product,
  ) async {
    final products = await getCachedProducts(businessId);
    final index = products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }
    await cacheProducts(businessId, products);
  }

  Future<void> deductOfflineStock(
    String businessId,
    String productId,
    int quantity,
  ) async {
    await deductOfflineStockBatch(businessId, {productId: quantity});
  }

  Future<void> deductOfflineStockBatch(
    String businessId,
    Map<String, int> productQuantities,
  ) async {
    if (productQuantities.isEmpty) return;
    final products = await getCachedProducts(businessId);
    bool modified = false;

    for (final entry in productQuantities.entries) {
      final index = products.indexWhere((p) => p.id == entry.key);
      if (index >= 0) {
        final current = products[index];
        final newStock = (current.currentBranchStock - entry.value).clamp(
          0,
          999999,
        );
        products[index] = ProductEntity(
          id: current.id,
          businessId: current.businessId,
          categoryId: current.categoryId,
          category: current.category,
          name: current.name,
          description: current.description,
          sku: current.sku,
          barcode: current.barcode,
          costPrice: current.costPrice,
          sellingPrice: current.sellingPrice,
          currency: current.currency,
          unit: current.unit,
          reorderLevel: current.reorderLevel,
          isActive: current.isActive,
          imageUrls: current.imageUrls,
          variants: current.variants,
          stocks: current.stocks,
          currentBranchStock: newStock,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        );
        modified = true;
      }
    }

    if (modified) {
      await cacheProducts(businessId, products);
    }
  }

  Future<void> deleteOfflineProduct(String businessId, String productId) async {
    final products = await getCachedProducts(businessId);
    products.removeWhere((p) => p.id == productId);
    await cacheProducts(businessId, products);
  }

  // ─── CATEGORIES CACHE ───
  Future<void> cacheCategories(
    String businessId,
    List<ProductCategoryEntity> categories,
  ) async {
    final cache = await _readCache();
    final jsonList = categories
        .map((c) => ProductCategoryModel.fromEntity(c).toJson())
        .toList();
    cache['categories_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<ProductCategoryEntity>> getCachedCategories(
    String businessId,
  ) async {
    final cache = await _readCache();
    final list = cache['categories_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list
          .map(
            (json) => ProductCategoryModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } catch (e) {
      AppLogger.w('Error parsing cached categories: $e');
      return [];
    }
  }

  Future<void> saveOfflineCategory(
    String businessId,
    ProductCategoryEntity category,
  ) async {
    final categories = await getCachedCategories(businessId);
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      categories[index] = category;
    } else {
      categories.insert(0, category);
    }
    await cacheCategories(businessId, categories);
  }

  // ─── CUSTOMERS CACHE ───
  Future<void> cacheCustomers(
    String businessId,
    List<CustomerEntity> customers,
  ) async {
    final cache = await _readCache();
    final jsonList = customers
        .map((c) => CustomerModel.fromEntity(c).toJson())
        .toList();
    cache['customers_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<CustomerEntity>> getCachedCustomers(String businessId) async {
    final cache = await _readCache();
    final list = cache['customers_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list
          .map(
            (json) =>
                CustomerModel.fromJson(json as Map<String, dynamic>).toEntity(),
          )
          .toList();
    } catch (e) {
      AppLogger.w('Error parsing cached customers: $e');
      return [];
    }
  }

  Future<CustomerEntity?> getCachedCustomerById(
    String businessId,
    String customerId,
  ) async {
    final customers = await getCachedCustomers(businessId);
    try {
      return customers.firstWhere((c) => c.id == customerId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOfflineCustomer(
    String businessId,
    CustomerEntity customer,
  ) async {
    final customers = await getCachedCustomers(businessId);
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index >= 0) {
      customers[index] = customer;
    } else {
      customers.insert(0, customer);
    }
    await cacheCustomers(businessId, customers);
  }

  // ─── SALES CACHE ───
  Future<void> cacheSales(String businessId, List<SaleEntity> sales) async {
    final cache = await _readCache();
    final jsonList = sales
        .map((s) => SaleModel.fromEntity(s).toCacheJson())
        .toList();
    cache['sales_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<SaleEntity>> getCachedSales(String businessId) async {
    final cache = await _readCache();
    final list = cache['sales_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list
          .map(
            (json) =>
                SaleModel.fromJson(json as Map<String, dynamic>).toEntity(),
          )
          .toList();
    } catch (e) {
      AppLogger.w('Error parsing cached sales: $e');
      return [];
    }
  }

  Future<SaleEntity?> getCachedSaleById(
    String businessId,
    String saleId,
  ) async {
    final sales = await getCachedSales(businessId);
    try {
      return sales.firstWhere((s) => s.id == saleId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOfflineSale(String businessId, SaleEntity sale) async {
    final sales = await getCachedSales(businessId);
    final index = sales.indexWhere((s) => s.id == sale.id);
    if (index >= 0) {
      sales[index] = sale;
    } else {
      sales.insert(0, sale);
    }
    await cacheSales(businessId, sales);
  }

  // ─── SUPPLIERS CACHE ───
  Future<void> cacheSuppliers(
    String businessId,
    List<SupplierEntity> suppliers,
  ) async {
    final cache = await _readCache();
    final jsonList = suppliers
        .map(
          (s) => SupplierModel(
            id: s.id,
            businessId: s.businessId,
            name: s.name,
            contactPerson: s.contactPerson,
            phone: s.phone,
            email: s.email,
            address: s.address,
            outstandingBalance: s.outstandingBalance,
            notes: s.notes,
            isActive: s.isActive,
            createdAt: s.createdAt,
            updatedAt: s.updatedAt,
          ).toJson(),
        )
        .toList();
    cache['suppliers_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<SupplierEntity>> getCachedSuppliers(String businessId) async {
    final cache = await _readCache();
    final list = cache['suppliers_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list
          .map((json) => SupplierModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.w('Error parsing cached suppliers: $e');
      return [];
    }
  }

  Future<SupplierEntity?> getCachedSupplierById(
    String businessId,
    String supplierId,
  ) async {
    final suppliers = await getCachedSuppliers(businessId);
    try {
      return suppliers.firstWhere((s) => s.id == supplierId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOfflineSupplier(
    String businessId,
    SupplierEntity supplier,
  ) async {
    final suppliers = await getCachedSuppliers(businessId);
    final index = suppliers.indexWhere((s) => s.id == supplier.id);
    if (index >= 0) {
      suppliers[index] = supplier;
    } else {
      suppliers.insert(0, supplier);
    }
    await cacheSuppliers(businessId, suppliers);
  }

  Future<void> deleteOfflineSupplier(
    String businessId,
    String supplierId,
  ) async {
    final suppliers = await getCachedSuppliers(businessId);
    suppliers.removeWhere((s) => s.id == supplierId);
    await cacheSuppliers(businessId, suppliers);
  }

  // ─── EXPENSES CACHE ───
  Future<void> cacheExpenses(
    String businessId,
    List<ExpenseEntity> expenses,
  ) async {
    final cache = await _readCache();
    final jsonList = expenses
        .map(
          (e) => ExpenseModel(
            id: e.id,
            businessId: e.businessId,
            branchId: e.branchId,
            categoryId: e.categoryId,
            categoryName: e.categoryName,
            amount: e.amount,
            description: e.description,
            paymentMethod: e.paymentMethod,
            paymentReference: e.paymentReference,
            expenseDate: e.expenseDate,
            receiptUrl: e.receiptUrl,
            recordedBy: e.recordedBy,
            recordedByName: e.recordedByName,
            notes: e.notes,
            createdAt: e.createdAt,
            updatedAt: e.updatedAt,
          ).toJson(),
        )
        .toList();
    cache['expenses_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<ExpenseEntity>> getCachedExpenses(
    String businessId, {
    String? branchId,
  }) async {
    final cache = await _readCache();
    final list = cache['expenses_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      var expenses = list
          .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
          .toList();
      if (branchId != null && branchId.isNotEmpty) {
        expenses = expenses.where((e) => e.branchId == branchId).toList();
      }
      return expenses;
    } catch (e) {
      AppLogger.w('Error parsing cached expenses: $e');
      return [];
    }
  }

  Future<void> saveOfflineExpense(
    String businessId,
    ExpenseEntity expense,
  ) async {
    final expenses = await getCachedExpenses(businessId);
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      expenses[index] = expense;
    } else {
      expenses.insert(0, expense);
    }
    await cacheExpenses(businessId, expenses);
  }

  Future<void> deleteOfflineExpense(String businessId, String expenseId) async {
    final expenses = await getCachedExpenses(businessId);
    expenses.removeWhere((e) => e.id == expenseId);
    await cacheExpenses(businessId, expenses);
  }

  // ─── DEBTS CACHE ───
  Future<void> cacheDebts(String businessId, List<DebtEntity> debts) async {
    final cache = await _readCache();
    final jsonList = debts
        .map(
          (d) => DebtModel(
            id: d.id,
            businessId: d.businessId,
            branchId: d.branchId,
            debtType: d.debtType,
            customerId: d.customerId,
            supplierId: d.supplierId,
            saleId: d.saleId,
            personName: d.personName,
            personPhone: d.personPhone,
            initialAmount: d.initialAmount,
            remainingBalance: d.remainingBalance,
            dueDate: d.dueDate,
            status: d.status,
            notes: d.notes,
            createdAt: d.createdAt,
            updatedAt: d.updatedAt,
          ).toJson(),
        )
        .toList();
    cache['debts_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<DebtEntity>> getCachedDebts(
    String businessId, {
    String? branchId,
  }) async {
    final cache = await _readCache();
    final list = cache['debts_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      var debts = list
          .map((json) => DebtModel.fromJson(json as Map<String, dynamic>))
          .toList();
      if (branchId != null && branchId.isNotEmpty) {
        debts = debts.where((d) => d.branchId == branchId).toList();
      }
      return debts;
    } catch (e) {
      AppLogger.w('Error parsing cached debts: $e');
      return [];
    }
  }

  Future<DebtEntity?> getCachedDebtById(
    String businessId,
    String debtId,
  ) async {
    final debts = await getCachedDebts(businessId);
    try {
      return debts.firstWhere((d) => d.id == debtId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOfflineDebt(String businessId, DebtEntity debt) async {
    final debts = await getCachedDebts(businessId);
    final index = debts.indexWhere((d) => d.id == debt.id);
    if (index >= 0) {
      debts[index] = debt;
    } else {
      debts.insert(0, debt);
    }
    await cacheDebts(businessId, debts);
  }

  Future<void> deleteOfflineDebt(String businessId, String debtId) async {
    final debts = await getCachedDebts(businessId);
    debts.removeWhere((d) => d.id == debtId);
    await cacheDebts(businessId, debts);
  }

  // ─── BUSINESSES CACHE ───
  Future<void> cacheBusinesses(
    String userId,
    List<BusinessEntity> businesses,
  ) async {
    final cache = await _readCache();
    final jsonList = businesses
        .map((b) => BusinessModel.fromEntity(b).toJson())
        .toList();
    cache['businesses_$userId'] = jsonList;
    cache['cached_businesses'] = jsonList; // Global backup for any user ID loss
    if (businesses.isNotEmpty) {
      cache['last_active_business'] = BusinessModel.fromEntity(
        businesses.first,
      ).toJson();
      cache['last_authenticated_user_id'] ??= userId;
    }
    await _writeCache(cache);
  }

  Future<List<BusinessEntity>> getCachedBusinesses([String? userId]) async {
    final cache = await _readCache();

    // 1. Try userId-specific key if provided
    if (userId != null && userId.isNotEmpty) {
      final list = cache['businesses_$userId'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        try {
          return list
              .map(
                (json) => BusinessModel.fromJson(
                  json as Map<String, dynamic>,
                ).toEntity(),
              )
              .toList();
        } catch (e) {
          AppLogger.w('Error parsing cached businesses for $userId: $e');
        }
      }
    }

    // 2. Global cached_businesses fallback
    final globalList = cache['cached_businesses'] as List<dynamic>?;
    if (globalList != null && globalList.isNotEmpty) {
      try {
        return globalList
            .map(
              (json) => BusinessModel.fromJson(
                json as Map<String, dynamic>,
              ).toEntity(),
            )
            .toList();
      } catch (e) {
        AppLogger.w('Error parsing global cached businesses: $e');
      }
    }

    // 3. Scan for any 'businesses_*' key in cache
    for (final entry in cache.entries) {
      if (entry.key.startsWith('businesses_') &&
          entry.value is List &&
          (entry.value as List).isNotEmpty) {
        try {
          final list = (entry.value as List)
              .map(
                (json) => BusinessModel.fromJson(
                  json as Map<String, dynamic>,
                ).toEntity(),
              )
              .toList();
          if (list.isNotEmpty) return list;
        } catch (_) {}
      }
    }

    // 4. Fallback to last active business
    final lastActive = cache['last_active_business'] as Map<String, dynamic>?;
    if (lastActive != null) {
      try {
        final biz = BusinessModel.fromJson(lastActive).toEntity();
        return [biz];
      } catch (_) {}
    }

    return [];
  }

  Future<void> cacheActiveBusiness(BusinessEntity business) async {
    final cache = await _readCache();
    cache['last_active_business'] = BusinessModel.fromEntity(business).toJson();
    await _writeCache(cache);
  }

  Future<BusinessEntity?> getActiveBusiness() async {
    final cache = await _readCache();
    final json = cache['last_active_business'] as Map<String, dynamic>?;
    if (json == null) return null;
    try {
      return BusinessModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  // ─── BRANCHES CACHE ───
  Future<void> cacheBranches(
    String businessId,
    List<BranchEntity> branches,
  ) async {
    final cache = await _readCache();
    final jsonList = branches
        .map((b) => BranchModel.fromEntity(b).toJson())
        .toList();
    cache['branches_$businessId'] = jsonList;
    if (branches.isNotEmpty) {
      cache['last_active_branch'] = BranchModel.fromEntity(
        branches.first,
      ).toJson();
    }
    await _writeCache(cache);
  }

  Future<List<BranchEntity>> getCachedBranches(String businessId) async {
    final cache = await _readCache();
    final list = cache['branches_$businessId'] as List<dynamic>?;
    if (list != null && list.isNotEmpty) {
      try {
        return list
            .map(
              (json) =>
                  BranchModel.fromJson(json as Map<String, dynamic>).toEntity(),
            )
            .toList();
      } catch (e) {
        AppLogger.w('Error parsing cached branches: $e');
      }
    }

    // Scan for any branches_* key in cache
    for (final entry in cache.entries) {
      if (entry.key.startsWith('branches_') &&
          entry.value is List &&
          (entry.value as List).isNotEmpty) {
        try {
          final branches = (entry.value as List)
              .map(
                (json) => BranchModel.fromJson(
                  json as Map<String, dynamic>,
                ).toEntity(),
              )
              .toList();
          if (branches.isNotEmpty) return branches;
        } catch (_) {}
      }
    }

    // Fallback to last active branch
    final lastActiveBranch =
        cache['last_active_branch'] as Map<String, dynamic>?;
    if (lastActiveBranch != null) {
      try {
        final b = BranchModel.fromJson(lastActiveBranch).toEntity();
        return [b];
      } catch (_) {}
    }

    return [];
  }

  Future<void> cacheActiveBranch(BranchEntity branch) async {
    final cache = await _readCache();
    cache['last_active_branch'] = BranchModel.fromEntity(branch).toJson();
    await _writeCache(cache);
  }

  Future<BranchEntity?> getActiveBranch() async {
    final cache = await _readCache();
    final json = cache['last_active_branch'] as Map<String, dynamic>?;
    if (json == null) return null;
    try {
      return BranchModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  // ─── LAST AUTHENTICATED USER ID ───
  /// Cache the user ID whenever a successful auth session is active.
  /// This allows offline mode to load data even when Supabase session expires.
  Future<void> cacheLastUserId(String userId) async {
    final cache = await _readCache();
    cache['last_authenticated_user_id'] = userId;
    await _writeCache(cache);
  }

  /// Retrieve the last known authenticated user ID for offline fallback.
  Future<String?> getLastUserId() async {
    final cache = await _readCache();
    return cache['last_authenticated_user_id'] as String?;
  }

  Future<void> clearLastUserId() async {
    final cache = await _readCache();
    cache.remove('last_authenticated_user_id');
    await _writeCache(cache);
  }

  // ─── ACTIVE BUSINESS SELECTION ───
  Future<void> saveSelectedBusinessId(String userId, String businessId) async {
    final cache = await _readCache();
    cache['selected_business_$userId'] = businessId;
    cache['last_selected_business_id'] = businessId;
    await _writeCache(cache);
  }

  Future<String?> getSelectedBusinessId([String? userId]) async {
    final cache = await _readCache();
    if (userId != null && userId.isNotEmpty) {
      final id = cache['selected_business_$userId'] as String?;
      if (id != null && id.isNotEmpty) return id;
    }
    final lastId = cache['last_selected_business_id'] as String?;
    if (lastId != null && lastId.isNotEmpty) return lastId;
    for (final entry in cache.entries) {
      if (entry.key.startsWith('selected_business_') &&
          entry.value is String &&
          (entry.value as String).isNotEmpty) {
        return entry.value as String;
      }
    }
    return null;
  }

  Future<void> clearSelectedBusinessId(String userId) async {
    final cache = await _readCache();
    cache.remove('selected_business_$userId');
    cache.remove('last_selected_business_id');
    await _writeCache(cache);
  }

  Future<void> removeCachedBusiness(String userId, String businessId) async {
    final cache = await _readCache();
    final list = cache['businesses_$userId'] as List<dynamic>?;
    if (list != null) {
      cache['businesses_$userId'] = list
          .where((item) => (item as Map<String, dynamic>)['id'] != businessId)
          .toList();
    }
    final globalList = cache['cached_businesses'] as List<dynamic>?;
    if (globalList != null) {
      cache['cached_businesses'] = globalList
          .where((item) => (item as Map<String, dynamic>)['id'] != businessId)
          .toList();
    }
    if (cache['selected_business_$userId'] == businessId) {
      cache.remove('selected_business_$userId');
    }
    if (cache['last_selected_business_id'] == businessId) {
      cache.remove('last_selected_business_id');
    }
    await _writeCache(cache);
  }

  // ─── USER ROLES CACHE ───
  Future<void> cacheUserRole(
    String businessId,
    String userId,
    String role,
  ) async {
    final cache = await _readCache();
    cache['role_${businessId}_$userId'] = role;
    cache['last_known_role_$businessId'] = role;
    cache['last_known_user_role'] = role;
    await _writeCache(cache);
  }

  Future<String?> getCachedUserRole(String businessId, [String? userId]) async {
    final cache = await _readCache();
    if (userId != null && userId.isNotEmpty) {
      final role = cache['role_${businessId}_$userId'] as String?;
      if (role != null && role.isNotEmpty) return role;
    }
    final bizRole = cache['last_known_role_$businessId'] as String?;
    if (bizRole != null && bizRole.isNotEmpty) return bizRole;

    final lastRole = cache['last_known_user_role'] as String?;
    if (lastRole != null && lastRole.isNotEmpty) return lastRole;

    return null;
  }

  String? getUserRoleSync(String businessId, [String? userId]) {
    if (userId != null && userId.isNotEmpty) {
      final role = _memoryCache['role_${businessId}_$userId'] as String?;
      if (role != null && role.isNotEmpty) return role;
    }
    final bizRole = _memoryCache['last_known_role_$businessId'] as String?;
    if (bizRole != null && bizRole.isNotEmpty) return bizRole;

    final lastRole = _memoryCache['last_known_user_role'] as String?;
    if (lastRole != null && lastRole.isNotEmpty) return lastRole;

    return null;
  }
}
