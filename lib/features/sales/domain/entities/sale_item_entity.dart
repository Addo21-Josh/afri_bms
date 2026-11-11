import 'package:equatable/equatable.dart';

class SaleItemEntity extends Equatable {
  final String id;
  final String saleId;
  final String productId;
  final String? variantId;
  final String productName;
  final String? variantName;
  final int unitCostPrice; // Minor units
  final int unitPrice; // Minor units
  final int quantity;
  final int discountAmount; // Minor units
  final int totalPrice; // Minor units
  final DateTime createdAt;

  const SaleItemEntity({
    required this.id,
    required this.saleId,
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantName,
    required this.unitCostPrice,
    required this.unitPrice,
    required this.quantity,
    this.discountAmount = 0,
    required this.totalPrice,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    saleId,
    productId,
    variantId,
    productName,
    variantName,
    unitCostPrice,
    unitPrice,
    quantity,
    discountAmount,
    totalPrice,
    createdAt,
  ];
}
