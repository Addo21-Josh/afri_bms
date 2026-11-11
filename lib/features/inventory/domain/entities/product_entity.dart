import 'package:equatable/equatable.dart';
import 'category_entity.dart';
import 'variant_entity.dart';
import 'stock_entity.dart';

class ProductEntity extends Equatable {
  final String id;
  final String businessId;
  final String? categoryId;
  final ProductCategoryEntity? category;
  final String name;
  final String? description;
  final String? sku;
  final String? barcode;
  final int costPrice; // Minor units (kobo/cents)
  final int sellingPrice; // Minor units (kobo/cents)
  final String currency;
  final String unit; // pcs, kg, litre, etc.
  final int reorderLevel;
  final bool isActive;
  final List<String> imageUrls;
  final List<ProductVariantEntity> variants;
  final List<StockEntity> stocks;
  final int currentBranchStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
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

  bool get isLowStock => currentBranchStock <= reorderLevel;

  @override
  List<Object?> get props => [
    id,
    businessId,
    categoryId,
    category,
    name,
    description,
    sku,
    barcode,
    costPrice,
    sellingPrice,
    currency,
    unit,
    reorderLevel,
    isActive,
    imageUrls,
    variants,
    stocks,
    currentBranchStock,
    createdAt,
    updatedAt,
  ];
}
