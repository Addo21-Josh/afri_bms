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

class LocalCacheService {
  static const String _cacheFileName = 'afri_offline_cache.json';
  File? _cacheFile;

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
      if (content.isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.w('Failed to read offline cache: $e');
      return {};
    }
  }

  Future<void> _writeCache(Map<String, dynamic> data) async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      AppLogger.e('Failed to write offline cache: $e');
    }
  }

  // ─── PRODUCTS CACHE ───
  Future<void> cacheProducts(String businessId, List<ProductEntity> products) async {
    final cache = await _readCache();
    final jsonList = products.map((p) => ProductModel.fromEntity(p).toCacheJson()).toList();
    cache['products_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<ProductEntity>> getCachedProducts(String businessId, {String? branchId}) async {
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

  Future<void> saveOfflineProduct(String businessId, ProductEntity product) async {
    final products = await getCachedProducts(businessId);
    final index = products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      products[index] = product;
    } else {
      products.insert(0, product);
    }
    await cacheProducts(businessId, products);
  }

  Future<void> deductOfflineStock(String businessId, String productId, int quantity) async {
    final products = await getCachedProducts(businessId);
    final index = products.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      final current = products[index];
      final newStock = (current.currentBranchStock - quantity).clamp(0, 999999);
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
      await cacheProducts(businessId, products);
    }
  }

  // ─── CATEGORIES CACHE ───
  Future<void> cacheCategories(String businessId, List<ProductCategoryEntity> categories) async {
    final cache = await _readCache();
    final jsonList = categories.map((c) => ProductCategoryModel.fromEntity(c).toJson()).toList();
    cache['categories_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<ProductCategoryEntity>> getCachedCategories(String businessId) async {
    final cache = await _readCache();
    final list = cache['categories_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list.map((json) => ProductCategoryModel.fromJson(json as Map<String, dynamic>).toEntity()).toList();
    } catch (e) {
      AppLogger.w('Error parsing cached categories: $e');
      return [];
    }
  }

  Future<void> saveOfflineCategory(String businessId, ProductCategoryEntity category) async {
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
  Future<void> cacheCustomers(String businessId, List<CustomerEntity> customers) async {
    final cache = await _readCache();
    final jsonList = customers.map((c) => CustomerModel.fromEntity(c).toJson()).toList();
    cache['customers_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<CustomerEntity>> getCachedCustomers(String businessId) async {
    final cache = await _readCache();
    final list = cache['customers_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list.map((json) => CustomerModel.fromJson(json as Map<String, dynamic>).toEntity()).toList();
    } catch (e) {
      AppLogger.w('Error parsing cached customers: $e');
      return [];
    }
  }

  Future<void> saveOfflineCustomer(String businessId, CustomerEntity customer) async {
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
    final jsonList = sales.map((s) => SaleModel.fromEntity(s).toJson()).toList();
    cache['sales_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<SaleEntity>> getCachedSales(String businessId) async {
    final cache = await _readCache();
    final list = cache['sales_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list.map((json) => SaleModel.fromJson(json as Map<String, dynamic>).toEntity()).toList();
    } catch (e) {
      AppLogger.w('Error parsing cached sales: $e');
      return [];
    }
  }

  Future<void> saveOfflineSale(String businessId, SaleEntity sale) async {
    final sales = await getCachedSales(businessId);
    sales.insert(0, sale);
    await cacheSales(businessId, sales);
  }

  // ─── BUSINESSES CACHE ───
  Future<void> cacheBusinesses(String userId, List<BusinessEntity> businesses) async {
    final cache = await _readCache();
    final jsonList = businesses.map((b) => BusinessModel.fromEntity(b).toJson()).toList();
    cache['businesses_$userId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<BusinessEntity>> getCachedBusinesses(String userId) async {
    final cache = await _readCache();
    final list = cache['businesses_$userId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list.map((json) => BusinessModel.fromJson(json as Map<String, dynamic>).toEntity()).toList();
    } catch (e) {
      AppLogger.w('Error parsing cached businesses: $e');
      return [];
    }
  }

  // ─── BRANCHES CACHE ───
  Future<void> cacheBranches(String businessId, List<BranchEntity> branches) async {
    final cache = await _readCache();
    final jsonList = branches.map((b) => BranchModel.fromEntity(b).toJson()).toList();
    cache['branches_$businessId'] = jsonList;
    await _writeCache(cache);
  }

  Future<List<BranchEntity>> getCachedBranches(String businessId) async {
    final cache = await _readCache();
    final list = cache['branches_$businessId'] as List<dynamic>?;
    if (list == null) return [];
    try {
      return list.map((json) => BranchModel.fromJson(json as Map<String, dynamic>).toEntity()).toList();
    } catch (e) {
      AppLogger.w('Error parsing cached branches: $e');
      return [];
    }
  }

  // ─── ACTIVE BUSINESS SELECTION ───
  Future<void> saveSelectedBusinessId(String userId, String businessId) async {
    final cache = await _readCache();
    cache['selected_business_$userId'] = businessId;
    await _writeCache(cache);
  }

  Future<String?> getSelectedBusinessId(String userId) async {
    final cache = await _readCache();
    return cache['selected_business_$userId'] as String?;
  }

  Future<void> clearSelectedBusinessId(String userId) async {
    final cache = await _readCache();
    cache.remove('selected_business_$userId');
    await _writeCache(cache);
  }

  Future<void> removeCachedBusiness(String userId, String businessId) async {
    final cache = await _readCache();
    final list = cache['businesses_$userId'] as List<dynamic>?;
    if (list != null) {
      cache['businesses_$userId'] = list.where((item) => (item as Map<String, dynamic>)['id'] != businessId).toList();
    }
    if (cache['selected_business_$userId'] == businessId) {
      cache.remove('selected_business_$userId');
    }
    await _writeCache(cache);
  }
}
