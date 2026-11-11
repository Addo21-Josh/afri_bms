import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../../inventory/domain/entities/variant_entity.dart';

enum CartDiscountType {
  none,
  fixed, // Minor currency units
  percentage, // Integer percentage 0-100
}

class CartState {
  const CartState({
    this.items = const [],
    this.discountType = CartDiscountType.none,
    this.discountValue = 0,
    this.taxRatePercent = 0.0,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.notes,
  });

  final List<CartItem> items;
  final CartDiscountType discountType;
  final int discountValue; // Fixed minor units OR percentage (0-100)
  final double taxRatePercent; // e.g. 0.0 or 7.5%
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? notes;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  int get discountAmount {
    if (discountType == CartDiscountType.fixed) {
      return discountValue.clamp(0, subtotal);
    } else if (discountType == CartDiscountType.percentage) {
      return ((subtotal * discountValue) / 100).round().clamp(0, subtotal);
    }
    return 0;
  }

  int get taxableAmount =>
      (subtotal - discountAmount).clamp(0, double.maxFinite.toInt());

  int get taxAmount {
    if (taxRatePercent <= 0) return 0;
    return ((taxableAmount * taxRatePercent) / 100).round();
  }

  int get totalAmount => taxableAmount + taxAmount;

  CartState copyWith({
    List<CartItem>? items,
    CartDiscountType? discountType,
    int? discountValue,
    double? taxRatePercent,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
    );
  }
}

class PosCartNotifier extends StateNotifier<CartState> {
  PosCartNotifier() : super(const CartState());

  void addItem(
    ProductEntity product, {
    ProductVariantEntity? variant,
    int quantity = 1,
  }) {
    final effectivePrice = variant?.sellingPrice ?? product.sellingPrice;
    final effectiveCost = variant != null
        ? product.costPrice
        : product.costPrice;

    final existingIndex = state.items.indexWhere(
      (item) =>
          item.product.id == product.id && item.variant?.id == variant?.id,
    );

    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final updatedList = List<CartItem>.from(state.items);
      updatedList[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItem(
        product: product,
        variant: variant,
        unitPrice: effectivePrice,
        unitCostPrice: effectiveCost,
        quantity: quantity,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void incrementQuantity(String productId, String? variantId) {
    final index = state.items.indexWhere(
      (item) => item.product.id == productId && item.variant?.id == variantId,
    );
    if (index >= 0) {
      final item = state.items[index];
      final updatedList = List<CartItem>.from(state.items);
      updatedList[index] = item.copyWith(quantity: item.quantity + 1);
      state = state.copyWith(items: updatedList);
    }
  }

  void decrementQuantity(String productId, String? variantId) {
    final index = state.items.indexWhere(
      (item) => item.product.id == productId && item.variant?.id == variantId,
    );
    if (index >= 0) {
      final item = state.items[index];
      final updatedList = List<CartItem>.from(state.items);
      if (item.quantity > 1) {
        updatedList[index] = item.copyWith(quantity: item.quantity - 1);
        state = state.copyWith(items: updatedList);
      } else {
        removeItem(productId, variantId);
      }
    }
  }

  void setQuantity(String productId, String? variantId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId, variantId);
      return;
    }
    final index = state.items.indexWhere(
      (item) => item.product.id == productId && item.variant?.id == variantId,
    );
    if (index >= 0) {
      final item = state.items[index];
      final updatedList = List<CartItem>.from(state.items);
      updatedList[index] = item.copyWith(quantity: newQuantity);
      state = state.copyWith(items: updatedList);
    }
  }

  void removeItem(String productId, String? variantId) {
    state = state.copyWith(
      items: state.items
          .where(
            (item) =>
                !(item.product.id == productId &&
                    item.variant?.id == variantId),
          )
          .toList(),
    );
  }

  void setDiscount(CartDiscountType type, int value) {
    state = state.copyWith(discountType: type, discountValue: value);
  }

  void setTaxRate(double ratePercent) {
    state = state.copyWith(taxRatePercent: ratePercent);
  }

  void setCustomerInfo({String? customerId, String? name, String? phone}) {
    state = state.copyWith(
      customerId: customerId,
      customerName: name,
      customerPhone: phone,
    );
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void clearCart() {
    state = const CartState();
  }
}

final posCartProvider = StateNotifierProvider<PosCartNotifier, CartState>((
  ref,
) {
  return PosCartNotifier();
});
