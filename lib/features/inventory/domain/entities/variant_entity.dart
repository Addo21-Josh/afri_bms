import 'package:equatable/equatable.dart';

class ProductVariantEntity extends Equatable {
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

  const ProductVariantEntity({
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

  @override
  List<Object?> get props => [
    id,
    productId,
    name,
    sku,
    barcode,
    costPrice,
    sellingPrice,
    attributes,
    isActive,
    createdAt,
  ];
}
