import '../../domain/entities/stock_entity.dart';

class StockModel {
  final String id;
  final String productId;
  final String? variantId;
  final String branchId;
  final int quantity;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime updatedAt;

  const StockModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.branchId,
    required this.quantity,
    this.batchNumber,
    this.expiryDate,
    required this.updatedAt,
  });

  factory StockModel.fromEntity(StockEntity e) {
    return StockModel(
      id: e.id,
      productId: e.productId,
      variantId: e.variantId,
      branchId: e.branchId,
      quantity: e.quantity,
      batchNumber: e.batchNumber,
      expiryDate: e.expiryDate,
      updatedAt: e.updatedAt,
    );
  }

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      branchId: json['branch_id'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      batchNumber: json['batch_number'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'branch_id': branchId,
      'quantity': quantity,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }

  StockEntity toEntity() {
    return StockEntity(
      id: id,
      productId: productId,
      variantId: variantId,
      branchId: branchId,
      quantity: quantity,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      updatedAt: updatedAt,
    );
  }
}
