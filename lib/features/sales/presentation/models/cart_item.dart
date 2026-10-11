import 'package:equatable/equatable.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../../inventory/domain/entities/variant_entity.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.product,
    this.variant,
    required this.unitPrice,
    required this.unitCostPrice,
    this.quantity = 1,
    this.discountAmount = 0,
  });

  final ProductEntity product;
  final ProductVariantEntity? variant;
  final int unitPrice; // Minor units
  final int unitCostPrice; // Minor units
  final int quantity;
  final int discountAmount; // Minor units per item

  String get id => variant != null ? '${product.id}_${variant!.id}' : product.id;

  String get displayName =>
      variant != null ? '${product.name} (${variant!.name})' : product.name;

  int get effectiveUnitPrice => (unitPrice - discountAmount).clamp(0, double.maxFinite.toInt());

  int get lineTotal => effectiveUnitPrice * quantity;

  int get availableStock =>
      variant != null ? product.currentBranchStock : product.currentBranchStock;

  bool get exceedsAvailableStock => quantity > availableStock;

  CartItem copyWith({
    ProductEntity? product,
    ProductVariantEntity? variant,
    int? unitPrice,
    int? unitCostPrice,
    int? quantity,
    int? discountAmount,
  }) {
    return CartItem(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCostPrice: unitCostPrice ?? this.unitCostPrice,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  @override
  List<Object?> get props => [
        product.id,
        variant?.id,
        unitPrice,
        unitCostPrice,
        quantity,
        discountAmount,
      ];
}
