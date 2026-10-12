import '../../domain/entities/variant_entity.dart';

class ProductVariantModel {
  final String id;
  final String productId;
  final String name;
  final String? sku;
  final String? barcode;
  final int costPrice;
  final int sellingPrice;
  final Map<String, dynamic> attributes;
  final bool isActive;
  final DateTime createdAt;

  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    this.attributes = const {},
    this.isActive = true,
    required this.createdAt,
  });

  factory ProductVariantModel.fromEntity(ProductVariantEntity e) {
    return ProductVariantModel(
      id: e.id,
      productId: e.productId,
      name: e.name,
      sku: e.sku,
      barcode: e.barcode,
      costPrice: e.costPrice,
      sellingPrice: e.sellingPrice,
      attributes: e.attributes,
      isActive: e.isActive,
      createdAt: e.createdAt,
    );
  }

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      costPrice: (json['cost_price'] as num?)?.toInt() ?? 0,
      sellingPrice: (json['selling_price'] as num?)?.toInt() ?? 0,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'attributes': attributes,
      'is_active': isActive,
    };
  }

  ProductVariantEntity toEntity() {
    return ProductVariantEntity(
      id: id,
      productId: productId,
      name: name,
      sku: sku,
      barcode: barcode,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      attributes: attributes,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}
