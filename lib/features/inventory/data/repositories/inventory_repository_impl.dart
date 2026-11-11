import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/variant_entity.dart';
import '../../domain/entities/stock_movement_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({required this.remoteDatasource});
  final InventoryRemoteDatasource remoteDatasource;

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    required String businessId,
    String? branchId,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      final models = await remoteDatasource.getProducts(
        businessId: businessId,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );
      final entities = models
          .map((m) => m.toEntity(currentBranchId: branchId))
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(
    String id, {
    String? branchId,
  }) async {
    try {
      final model = await remoteDatasource.getProductById(id);
      return Right(model.toEntity(currentBranchId: branchId));
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final model = await remoteDatasource.createProduct(
        businessId: businessId,
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
        initialBranchId: initialBranchId,
        variants: variants,
        imageUrls: imageUrls,
      );
      return Right(model.toEntity(currentBranchId: initialBranchId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
    ProductEntity product,
  ) async {
    try {
      final model = await remoteDatasource.updateProduct(product);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String productId) async {
    try {
      await remoteDatasource.deleteProduct(productId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductCategoryEntity>>> getCategories(
    String businessId,
  ) async {
    try {
      final models = await remoteDatasource.getCategories(businessId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductCategoryEntity>> createCategory({
    required String businessId,
    required String name,
    String? description,
  }) async {
    try {
      final model = await remoteDatasource.createCategory(
        businessId: businessId,
        name: name,
        description: description,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String categoryId) async {
    try {
      await remoteDatasource.deleteCategory(categoryId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      await remoteDatasource.adjustStock(
        businessId: businessId,
        productId: productId,
        branchId: branchId,
        variantId: variantId,
        newQuantity: newQuantity,
        type: type,
        reason: reason,
        batchNumber: batchNumber,
        expiryDate: expiryDate,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockMovementEntity>>> getStockMovements({
    required String businessId,
    String? branchId,
    String? productId,
  }) async {
    try {
      final models = await remoteDatasource.getStockMovements(
        businessId: businessId,
        branchId: branchId,
        productId: productId,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
