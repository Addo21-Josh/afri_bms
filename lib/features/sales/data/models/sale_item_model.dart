import '../../domain/entities/sale_item_entity.dart';

class SaleItemModel {
  final String id;
  final String saleId;
  final String productId;
  final String? variantId;
  final String productName;
  final String? variantName;
  final int unitCostPrice;
  final int unitPrice;
  final int quantity;
  final int discountAmount;
  final int totalPrice;
  final DateTime createdAt;

  const SaleItemModel({
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

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as String,
      saleId: json['sale_id'] as String? ?? '',
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      productName: json['product_name'] as String? ?? 'Product',
      variantName: json['variant_name'] as String?,
      unitCostPrice: (json['unit_cost_price'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'variant_id': variantId,
      'product_name': productName,
      'variant_name': variantName,
      'unit_cost_price': unitCostPrice,
      'unit_price': unitPrice,
      'quantity': quantity,
      'discount_amount': discountAmount,
      'total_price': totalPrice,
    };
  }

  // To map for RPC payload
  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': productId,
      'variant_id': variantId,
      'product_name': productName,
      'variant_name': variantName,
      'unit_cost_price': unitCostPrice,
      'unit_price': unitPrice,
      'quantity': quantity,
      'discount_amount': discountAmount,
      'total_price': totalPrice,
    };
  }

  SaleItemEntity toEntity() {
    return SaleItemEntity(
      id: id,
      saleId: saleId,
      productId: productId,
      variantId: variantId,
      productName: productName,
      variantName: variantName,
      unitCostPrice: unitCostPrice,
      unitPrice: unitPrice,
      quantity: quantity,
      discountAmount: discountAmount,
      totalPrice: totalPrice,
      createdAt: createdAt,
    );
  }
}
