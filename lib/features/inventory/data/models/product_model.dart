import '../../domain/entities/product_entity.dart';
import 'category_model.dart';
import 'variant_model.dart';
import 'stock_model.dart';

class ProductModel {
  final String id;
  final String businessId;
  final String? categoryId;
  final ProductCategoryModel? category;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final int costPrice;
  final int sellingPrice;
  final String currency;
  final String unit;
  final int reorderLevel;
  final bool isActive;
  final List<String> imageUrls;
  final List<ProductVariantModel> variants;
  final List<StockModel> stocks;
  final int currentBranchStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.businessId,
    this.categoryId,
    this.category,
    required this.name,
    this.description,
    this.sku,
    this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    this.currency = 'GHS',
    this.unit = 'pcs',
    this.reorderLevel = 10,
    this.isActive = true,
    this.imageUrls = const [],
    this.variants = const [],
    this.stocks = const [],
    this.currentBranchStock = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromEntity(ProductEntity e) {
    return ProductModel(
      id: e.id,
      businessId: e.businessId,
      categoryId: e.categoryId,
      category: e.category != null
          ? ProductCategoryModel.fromEntity(e.category!)
          : null,
      name: e.name,
      description: e.description,
      sku: e.sku,
      barcode: e.barcode,
      costPrice: e.costPrice,
      sellingPrice: e.sellingPrice,
      currency: e.currency,
      unit: e.unit,
      reorderLevel: e.reorderLevel,
      isActive: e.isActive,
      imageUrls: e.imageUrls,
      variants: e.variants
          .map((v) => ProductVariantModel.fromEntity(v))
          .toList(),
      stocks: e.stocks.map((s) => StockModel.fromEntity(s)).toList(),
      currentBranchStock: e.currentBranchStock,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse category join if present
    ProductCategoryModel? catModel;
    if (json['product_categories'] != null) {
      catModel = ProductCategoryModel.fromJson(
        json['product_categories'] as Map<String, dynamic>,
      );
    }

    // Parse variants if present
    final rawVariants = json['product_variants'] as List<dynamic>? ?? [];
    final variantsList = rawVariants
        .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
        .toList();

    // Parse stocks if present
    final rawStocks = json['stock'] as List<dynamic>? ?? [];
    final stocksList = rawStocks
        .map((s) => StockModel.fromJson(s as Map<String, dynamic>))
        .toList();

    final rawImages = json['image_urls'] as List<dynamic>? ?? [];
    final cachedStock = (json['current_branch_stock'] as num?)?.toInt() ?? 0;

    return ProductModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      categoryId: json['category_id'] as String?,
      category: catModel,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      costPrice: (json['cost_price'] as num?)?.toInt() ?? 0,
      sellingPrice: (json['selling_price'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'GHS',
      unit: (json['unit'] as String?) ?? 'pcs',
      reorderLevel: (json['reorder_level'] as num?)?.toInt() ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      imageUrls: rawImages.map((e) => e.toString()).toList(),
      variants: variantsList,
      stocks: stocksList,
      currentBranchStock: cachedStock,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Minimal JSON payload for remote database mutations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'currency': currency,
      'unit': unit,
      'reorder_level': reorderLevel,
      'is_active': isActive,
      'image_urls': imageUrls,
    };
  }

  /// Comprehensive JSON payload for offline local disk cache
  Map<String, dynamic> toCacheJson({int? overrideStock}) {
    return {
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      if (category != null) 'product_categories': category!.toJson(),
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'currency': currency,
      'unit': unit,
      'reorder_level': reorderLevel,
      'is_active': isActive,
      'image_urls': imageUrls,
      'product_variants': variants.map((v) => v.toJson()).toList(),
      'stock': stocks.map((s) => s.toJson()).toList(),
      'current_branch_stock': overrideStock ?? currentBranchStock,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductEntity toEntity({String? currentBranchId, int? cachedBranchStock}) {
    int branchStock = 0;
    if (cachedBranchStock != null) {
      branchStock = cachedBranchStock;
    } else if (currentBranchStock > 0) {
      branchStock = currentBranchStock;
    } else if (stocks.isNotEmpty) {
      if (currentBranchId != null) {
        branchStock = stocks
            .where((s) => s.branchId == currentBranchId)
            .fold<int>(0, (prev, s) => prev + s.quantity);
      } else {
        branchStock = stocks.fold<int>(0, (prev, s) => prev + s.quantity);
      }
    }

    return ProductEntity(
      id: id,
      businessId: businessId,
      categoryId: categoryId,
      category: category?.toEntity(),
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      currency: currency,
      unit: unit,
      reorderLevel: reorderLevel,
      isActive: isActive,
      imageUrls: imageUrls,
      variants: variants.map((v) => v.toEntity()).toList(),
      stocks: stocks.map((s) => s.toEntity()).toList(),
      currentBranchStock: branchStock,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
