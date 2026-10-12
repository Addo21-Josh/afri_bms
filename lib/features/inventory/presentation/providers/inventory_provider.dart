import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/variant_entity.dart';
import '../../domain/entities/stock_movement_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../../core/sync/domain/models/sync_queue_item.dart';
import '../../../../core/utils/logger.dart';

final inventoryRemoteDatasourceProvider = Provider<InventoryRemoteDatasource>((ref) {
  return InventoryRemoteDatasourceImpl(Supabase.instance.client);
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final remote = ref.watch(inventoryRemoteDatasourceProvider);
  return InventoryRepositoryImpl(remoteDatasource: remote);
});

// Category filter & Search query state
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// Fetch categories for active business with offline fallback
final productCategoriesProvider = FutureProvider.autoDispose<List<ProductCategoryEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final repo = ref.watch(inventoryRepositoryProvider);
  final localCache = ref.watch(localCacheServiceProvider);

  final result = await repo.getCategories(currentBiz.id);
  return result.fold(
    (failure) async {
      AppLogger.w('Categories fetch failed: ${failure.message}. Falling back to offline cache.');
      return await localCache.getCachedCategories(currentBiz.id);
    },
    (categories) async {
      await localCache.cacheCategories(currentBiz.id, categories);
      return categories;
    },
  );
});

// Fetch products list for active business and active branch with offline fallback
final productsListProvider = FutureProvider.autoDispose<List<ProductEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final currentBranch = ref.watch(currentBranchProvider);
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);

  final repo = ref.watch(inventoryRepositoryProvider);
  final localCache = ref.watch(localCacheServiceProvider);

  final result = await repo.getProducts(
    businessId: currentBiz.id,
    branchId: currentBranch?.id,
    categoryId: categoryId,
    searchQuery: searchQuery,
  );

  return result.fold(
    (failure) async {
      AppLogger.w('Products fetch failed: ${failure.message}. Falling back to offline cache.');
      var cached = await localCache.getCachedProducts(currentBiz.id);
      if (categoryId != null) {
        cached = cached.where((p) => p.categoryId == categoryId).toList();
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        cached = cached.where((p) => p.name.toLowerCase().contains(q) || (p.sku?.toLowerCase().contains(q) ?? false)).toList();
      }
      return cached;
    },
    (products) async {
      await localCache.cacheProducts(currentBiz.id, products);
      return products;
    },
  );
});

// Single product provider
final productDetailProvider = FutureProvider.family<ProductEntity, String>((ref, productId) async {
  final currentBranch = ref.watch(currentBranchProvider);
  final repo = ref.watch(inventoryRepositoryProvider);

  final result = await repo.getProductById(productId, branchId: currentBranch?.id);
  return result.fold(
    (failure) => throw failure.message,
    (product) => product,
  );
});

// Stock movement history provider
final stockMovementsProvider = FutureProvider.autoDispose<List<StockMovementEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final currentBranch = ref.watch(currentBranchProvider);
  final repo = ref.watch(inventoryRepositoryProvider);

  final result = await repo.getStockMovements(
    businessId: currentBiz.id,
    branchId: currentBranch?.id,
  );

  return result.fold(
    (failure) => throw failure.message,
    (movements) => movements,
  );
});

// Inventory controller for mutations
class InventoryController extends StateNotifier<AsyncValue<void>> {
  InventoryController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<ProductEntity?> createProduct({
    String? categoryId,
    required String name,
    String? description,
    String? sku,
    String? barcode,
    required int costPrice,
    required int sellingPrice,
    required String currency,
    String unit = 'pcs',
    int reorderLevel = 10,
    int initialStock = 0,
    List<ProductVariantEntity> variants = const [],
    List<String> imageUrls = const [],
  }) async {
    final currentBiz = ref.read(currentBusinessProvider);
    final currentBranch = ref.read(currentBranchProvider);
    if (currentBiz == null) {
      state = AsyncValue.error('No active business found. Please create a business first.', StackTrace.current);
      return null;
    }

    state = const AsyncValue.loading();
    final repo = ref.read(inventoryRepositoryProvider);

    final result = await repo.createProduct(
      businessId: currentBiz.id,
      categoryId: categoryId,
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      currency: currency,
      unit: unit,
      reorderLevel: reorderLevel,
      initialStock: initialStock,
      initialBranchId: currentBranch?.id,
      variants: variants,
      imageUrls: imageUrls,
    );

    return result.fold(
      (failure) async {
        final syncState = ref.read(syncProvider);
        if (!syncState.isOnline || failure.message.contains('SocketException') || failure.message.contains('ClientException') || failure.message.contains('Failed host lookup')) {
          final localProduct = ProductEntity(
            id: const Uuid().v4(),
            businessId: currentBiz.id,
            categoryId: categoryId,
            name: name,
            description: description,
            sku: sku,
            barcode: barcode,
            costPrice: costPrice,
            sellingPrice: sellingPrice,
            currency: currency,
            unit: unit,
            reorderLevel: reorderLevel,
            currentBranchStock: initialStock,
            variants: variants,
            imageUrls: imageUrls,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await ref.read(localCacheServiceProvider).saveOfflineProduct(currentBiz.id, localProduct);
          await ref.read(syncProvider.notifier).enqueueOperation(
            table: 'products',
            operation: SyncOperation.insert,
            recordId: localProduct.id,
            payload: ProductModel.fromEntity(localProduct).toJson(),
            businessId: currentBiz.id,
          );

          state = const AsyncValue.data(null);
          ref.invalidate(productsListProvider);
          return localProduct;
        }

        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (product) async {
        await ref.read(localCacheServiceProvider).saveOfflineProduct(currentBiz.id, product);
        state = const AsyncValue.data(null);
        ref.invalidate(productsListProvider);
        return product;
      },
    );
  }

  Future<bool> updateProduct(ProductEntity product) async {
    state = const AsyncValue.loading();
    final repo = ref.read(inventoryRepositoryProvider);

    final result = await repo.updateProduct(product);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(productsListProvider);
        ref.invalidate(productDetailProvider(product.id));
        return true;
      },
    );
  }

  Future<bool> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    final repo = ref.read(inventoryRepositoryProvider);

    final result = await repo.deleteProduct(productId);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(productsListProvider);
        return true;
      },
    );
  }

  Future<ProductCategoryEntity?> createCategory(String name, {String? description}) async {
    final currentBiz = ref.read(currentBusinessProvider);
    if (currentBiz == null) return null;

    state = const AsyncValue.loading();
    final repo = ref.read(inventoryRepositoryProvider);

    final result = await repo.createCategory(
      businessId: currentBiz.id,
      name: name,
      description: description,
    );

    return result.fold(
      (failure) async {
        final syncState = ref.read(syncProvider);
        if (!syncState.isOnline || failure.message.contains('SocketException') || failure.message.contains('ClientException') || failure.message.contains('Failed host lookup')) {
          final localCat = ProductCategoryEntity(
            id: const Uuid().v4(),
            businessId: currentBiz.id,
            name: name,
            description: description,
            createdAt: DateTime.now(),
          );

          await ref.read(localCacheServiceProvider).saveOfflineCategory(currentBiz.id, localCat);
          await ref.read(syncProvider.notifier).enqueueOperation(
            table: 'categories',
            operation: SyncOperation.insert,
            recordId: localCat.id,
            payload: ProductCategoryModel.fromEntity(localCat).toJson(),
            businessId: currentBiz.id,
          );

          state = const AsyncValue.data(null);
          ref.invalidate(productCategoriesProvider);
          return localCat;
        }

        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (category) async {
        await ref.read(localCacheServiceProvider).saveOfflineCategory(currentBiz.id, category);
        state = const AsyncValue.data(null);
        ref.invalidate(productCategoriesProvider);
        return category;
      },
    );
  }

  Future<bool> adjustStock({
    required String productId,
    required String branchId,
    String? variantId,
    required int newQuantity,
    String type = 'adjustment',
    String? reason,
    String? batchNumber,
    DateTime? expiryDate,
  }) async {
    final currentBiz = ref.read(currentBusinessProvider);
    if (currentBiz == null) {
      state = AsyncValue.error('No business selected', StackTrace.current);
      return false;
    }

    state = const AsyncValue.loading();
    final repo = ref.read(inventoryRepositoryProvider);

    final result = await repo.adjustStock(
      businessId: currentBiz.id,
      productId: productId,
      branchId: branchId,
      variantId: variantId,
      newQuantity: newQuantity,
      type: type,
      reason: reason,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        ref.invalidate(productsListProvider);
        ref.invalidate(productDetailProvider(productId));
        ref.invalidate(stockMovementsProvider);
        return true;
      },
    );
  }
}

final inventoryControllerProvider = StateNotifierProvider<InventoryController, AsyncValue<void>>((ref) {
  return InventoryController(ref);
});
