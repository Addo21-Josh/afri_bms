import 'package:flutter/foundation.dart';
import '../../../inventory/domain/entities/product_entity.dart';

@immutable
class AutoReorderItem {
  const AutoReorderItem({
    required this.product,
    required this.currentStock,
    required this.reorderLevel,
    required this.suggestedQuantity,
    required this.unitCostPrice,
    required this.estimatedTotalCost,
  });

  final ProductEntity product;
  final int currentStock;
  final int reorderLevel;
  final int suggestedQuantity;
  final int unitCostPrice;
  final int estimatedTotalCost;
}

@immutable
class SalesVelocityItem {
  const SalesVelocityItem({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.unitsSold,
    required this.velocityPerDay,
    required this.daysRemaining,
  });

  final String productId;
  final String productName;
  final int currentStock;
  final int unitsSold;
  final double velocityPerDay;
  final int? daysRemaining; // Null if velocity is 0
}

@immutable
class BranchPerformanceItem {
  const BranchPerformanceItem({
    required this.branchId,
    required this.branchName,
    required this.totalRevenue,
    required this.ordersCount,
    required this.averageOrderValue,
  });

  final String branchId;
  final String branchName;
  final int totalRevenue;
  final int ordersCount;
  final int averageOrderValue;
}

@immutable
class ProductProfitabilityItem {
  const ProductProfitabilityItem({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.profitMarginPercent,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final int totalRevenue;
  final int totalCost;
  final int totalProfit;
  final double profitMarginPercent;
}

@immutable
class CustomerPatternItem {
  const CustomerPatternItem({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.ordersCount,
    required this.totalSpent,
    required this.averageSpend,
    required this.preferredPaymentMethod,
    required this.lastOrderDate,
  });

  final String customerId;
  final String customerName;
  final String? phone;
  final int ordersCount;
  final int totalSpent;
  final int averageSpend;
  final String preferredPaymentMethod;
  final DateTime? lastOrderDate;
}
