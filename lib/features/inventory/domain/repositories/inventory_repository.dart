import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/product_entity.dart';
import '../entities/category_entity.dart';
import '../entities/variant_entity.dart';
import '../entities/stock_movement_entity.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    required String businessId,
    String? branchId,
    String? categoryId,
    String? searchQuery,
  });

  Future<Either<Failure, ProductEntity>> getProductById(
    String id, {
    String? branchId,
  });

  Future<Either<Failure, ProductEntity>> createProduct({
    required String businessId,
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
    String? initialBranchId,
    List<ProductVariantEntity> variants = const [],
    List<String> imageUrls = const [],
  });

  Future<Either<Failure, ProductEntity>> updateProduct(ProductEntity product);

  Future<Either<Failure, void>> deleteProduct(String productId);

  // Categories
  Future<Either<Failure, List<ProductCategoryEntity>>> getCategories(
    String businessId,
  );
  Future<Either<Failure, ProductCategoryEntity>> createCategory({
    required String businessId,
    required String name,
    String? description,
  });
  Future<Either<Failure, void>> deleteCategory(String categoryId);

  // Stock & Movement Tracking
  Future<Either<Failure, void>> adjustStock({
    required String businessId,
    required String productId,
    required String branchId,
    String? variantId,
    required int newQuantity,
    String type = 'adjustment',
    String? reason,
    String? batchNumber,
    DateTime? expiryDate,
  });

  Future<Either<Failure, List<StockMovementEntity>>> getStockMovements({
    required String businessId,
    String? branchId,
    String? productId,
  });
}
