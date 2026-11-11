import '../../domain/entities/stock_movement_entity.dart';

class StockMovementModel {
  final String id;
  final String businessId;
  final String branchId;
  final String productId;
  final String? variantId;
  final String? productName;
  final String? variantName;
  final int quantity;
  final String type;
  final String? reason;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? userId;
  final String? userName;
  final DateTime createdAt;

  const StockMovementModel({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.productId,
    this.variantId,
    this.productName,
    this.variantName,
    required this.quantity,
    required this.type,
    this.reason,
    this.batchNumber,
    this.expiryDate,
    this.userId,
    this.userName,
    required this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    // Check if product join is present
    String? prodName;
    if (json['products'] != null && json['products'] is Map<String, dynamic>) {
      prodName = json['products']['name'] as String?;
    }

    // Check if variant join is present
    String? varName;
    if (json['product_variants'] != null &&
        json['product_variants'] is Map<String, dynamic>) {
      varName = json['product_variants']['name'] as String?;
    }

    // Check if user profile join is present
    String? uName;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      uName = json['profiles']['full_name'] as String?;
    }

    return StockMovementModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      productName: prodName,
      variantName: varName,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'adjustment',
      reason: json['reason'] as String?,
      batchNumber: json['batch_number'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      userId: json['user_id'] as String?,
      userName: uName,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'branch_id': branchId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'type': type,
      'reason': reason,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'user_id': userId,
    };
  }

  StockMovementEntity toEntity() {
    return StockMovementEntity(
      id: id,
      businessId: businessId,
      branchId: branchId,
      productId: productId,
      variantId: variantId,
      productName: productName,
      variantName: variantName,
      quantity: quantity,
      type: StockMovementType.fromString(type),
      reason: reason,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      userId: userId,
      userName: userName,
      createdAt: createdAt,
    );
  }
}
