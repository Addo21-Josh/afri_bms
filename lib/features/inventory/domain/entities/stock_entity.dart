import 'package:equatable/equatable.dart';

class StockEntity extends Equatable {
  final String id;
  final String productId;
  final String? variantId;
  final String branchId;
  final int quantity;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime updatedAt;

  const StockEntity({
    required this.id,
    required this.productId,
    this.variantId,
    required this.branchId,
    required this.quantity,
    this.batchNumber,
    this.expiryDate,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    variantId,
    branchId,
    quantity,
    batchNumber,
    expiryDate,
    updatedAt,
  ];
}
