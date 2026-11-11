import 'package:equatable/equatable.dart';

enum StockMovementType {
  sale,
  restock,
  adjustment,
  damaged,
  expired,
  transfer,
  returned;

  static StockMovementType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'sale':
        return StockMovementType.sale;
      case 'restock':
        return StockMovementType.restock;
      case 'adjustment':
        return StockMovementType.adjustment;
      case 'damaged':
        return StockMovementType.damaged;
      case 'expired':
        return StockMovementType.expired;
      case 'transfer':
        return StockMovementType.transfer;
      case 'return':
      case 'returned':
        return StockMovementType.returned;
      default:
        return StockMovementType.adjustment;
    }
  }

  String get value {
    switch (this) {
      case StockMovementType.sale:
        return 'sale';
      case StockMovementType.restock:
        return 'restock';
      case StockMovementType.adjustment:
        return 'adjustment';
      case StockMovementType.damaged:
        return 'damaged';
      case StockMovementType.expired:
        return 'expired';
      case StockMovementType.transfer:
        return 'transfer';
      case StockMovementType.returned:
        return 'return';
    }
  }

  String get label {
    switch (this) {
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.restock:
        return 'Restock';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.damaged:
        return 'Damaged';
      case StockMovementType.expired:
        return 'Expired';
      case StockMovementType.transfer:
        return 'Transfer';
      case StockMovementType.returned:
        return 'Return';
    }
  }
}

class StockMovementEntity extends Equatable {
  final String id;
  final String businessId;
  final String branchId;
  final String productId;
  final String? variantId;
  final String? productName;
  final String? variantName;
  final int quantity; // Positive for additions, negative for deductions
  final StockMovementType type;
  final String? reason;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? userId;
  final String? userName;
  final DateTime createdAt;

  const StockMovementEntity({
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

  bool get isAddition => quantity > 0;

  @override
  List<Object?> get props => [
    id,
    businessId,
    branchId,
    productId,
    variantId,
    quantity,
    type,
    reason,
    batchNumber,
    expiryDate,
    userId,
    createdAt,
  ];
}
