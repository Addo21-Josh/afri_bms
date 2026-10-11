import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/variant_entity.dart';
import '../../domain/entities/stock_movement_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../../business/presentation/providers/business_provider.dart';

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

// Fetch categories for active business
final productCategoriesProvider = FutureProvider.autoDispose<List<ProductCategoryEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final repo = ref.watch(inventoryRepositoryProvider);
  final result = await repo.getCategories(currentBiz.id);
  return result.fold(
    (failure) => throw failure.message,
    (categories) => categories,
  );
});

// Fetch products list for active business and active branch
final productsListProvider = FutureProvider.autoDispose<List<ProductEntity>>((ref) async {
  final currentBiz = ref.watch(currentBusinessProvider);
  if (currentBiz == null) return [];

  final currentBranch = ref.watch(currentBranchProvider);
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final searchQuery = ref.watch(productSearchQueryProvider);

  final repo = ref.watch(inventoryRepositoryProvider);
  final result = await repo.getProducts(
    businessId: currentBiz.id,
    branchId: currentBranch?.id,
    categoryId: categoryId,
    searchQuery: searchQuery,
  );

  return result.fold(
    (failure) => throw failure.message,
    (products) => products,
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
  final Ref ref;

  InventoryController(this.ref) : super(const AsyncValue.data(null));

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
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (product) {
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
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (category) {
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
