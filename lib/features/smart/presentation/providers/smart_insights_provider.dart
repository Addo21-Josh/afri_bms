import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/smart_insights_entity.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';

// Auto-Reorder Suggestions Provider
final autoReorderListProvider = Provider<List<AutoReorderItem>>((ref) {
  final products = ref.watch(productsListProvider).value ?? [];

  final List<AutoReorderItem> reorderItems = [];

  for (final product in products) {
    final stock = product.currentBranchStock;
    final reorder = product.reorderLevel;

    if (stock <= reorder) {
      final suggestedQty = ((reorder * 2) - stock).clamp(1, 99999);
      final estimatedCost = suggestedQty * product.costPrice;

      reorderItems.add(AutoReorderItem(
        product: product,
        currentStock: stock,
        reorderLevel: reorder,
        suggestedQuantity: suggestedQty,
        unitCostPrice: product.costPrice,
        estimatedTotalCost: estimatedCost,
      ));
    }
  }

  // Sort by urgency: lowest current stock percentage of reorder level first
  reorderItems.sort((a, b) {
    final aRatio = a.reorderLevel > 0 ? a.currentStock / a.reorderLevel : 0.0;
    final bRatio = b.reorderLevel > 0 ? b.currentStock / b.reorderLevel : 0.0;
    return aRatio.compareTo(bRatio);
  });

  return reorderItems;
});

// Sales Velocity & Stockout Run-Out Forecast Provider (Past 30 Days)
final salesVelocityProvider = Provider<List<SalesVelocityItem>>((ref) {
  final products = ref.watch(productsListProvider).value ?? [];
  final sales = ref.watch(salesListProvider).value ?? [];

  final now = DateTime.now();
  final past30Days = now.subtract(const Duration(days: 30));
  final recentSales = sales.where((s) => s.createdAt.isAfter(past30Days)).toList();

  final Map<String, int> productUnitsSold = {};
  for (final s in recentSales) {
    for (final item in s.items) {
      productUnitsSold[item.productId] = (productUnitsSold[item.productId] ?? 0) + item.quantity;
    }
  }

  final List<SalesVelocityItem> velocityItems = [];
  for (final product in products) {
    final units = productUnitsSold[product.id] ?? 0;
    final velocity = units / 30.0;
    final daysRemaining = velocity > 0 ? (product.currentBranchStock / velocity).round() : null;

    velocityItems.add(SalesVelocityItem(
      productId: product.id,
      productName: product.name,
      currentStock: product.currentBranchStock,
      unitsSold: units,
      velocityPerDay: velocity,
      daysRemaining: daysRemaining,
    ));
  }

  // Sort by shortest days remaining (highest risk of running out first)
  velocityItems.sort((a, b) {
    if (a.daysRemaining == null && b.daysRemaining == null) return b.unitsSold.compareTo(a.unitsSold);
    if (a.daysRemaining == null) return 1;
    if (b.daysRemaining == null) return -1;
    return a.daysRemaining!.compareTo(b.daysRemaining!);
  });

  return velocityItems;
});

// Branch Performance Comparison Provider
final branchPerformanceProvider = Provider<List<BranchPerformanceItem>>((ref) {
  final branches = ref.watch(businessBranchesProvider).value ?? [];
  final sales = ref.watch(salesListProvider).value ?? [];

  final Map<String, int> branchRevenue = {};
  final Map<String, int> branchOrders = {};

  for (final s in sales) {
    branchRevenue[s.branchId] = (branchRevenue[s.branchId] ?? 0) + s.totalAmount;
    branchOrders[s.branchId] = (branchOrders[s.branchId] ?? 0) + 1;
  }

  final List<BranchPerformanceItem> items = [];
  for (final branch in branches) {
    final rev = branchRevenue[branch.id] ?? 0;
    final orders = branchOrders[branch.id] ?? 0;
    final aov = orders > 0 ? (rev / orders).round() : 0;

    items.add(BranchPerformanceItem(
      branchId: branch.id,
      branchName: branch.name,
      totalRevenue: rev,
      ordersCount: orders,
      averageOrderValue: aov,
    ));
  }

  items.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
  return items;
});

// Most Profitable Products Ranking Provider
final productProfitabilityProvider = Provider<List<ProductProfitabilityItem>>((ref) {
  final sales = ref.watch(salesListProvider).value ?? [];

  final Map<String, _ProfitAgg> aggMap = {};

  for (final s in sales) {
    for (final item in s.items) {
      final revenue = item.totalPrice;
      final cost = item.unitCostPrice * item.quantity;
      final profit = revenue - cost;

      final cur = aggMap[item.productId] ?? _ProfitAgg(item.productName, 0, 0, 0, 0);
      aggMap[item.productId] = _ProfitAgg(
        item.productName,
        cur.qty + item.quantity,
        cur.revenue + revenue,
        cur.cost + cost,
        cur.profit + profit,
      );
    }
  }

  final List<ProductProfitabilityItem> items = aggMap.entries.map((e) {
    final margin = e.value.revenue > 0 ? (e.value.profit / e.value.revenue) * 100 : 0.0;
    return ProductProfitabilityItem(
      productId: e.key,
      productName: e.value.name,
      quantitySold: e.value.qty,
      totalRevenue: e.value.revenue,
      totalCost: e.value.cost,
      totalProfit: e.value.profit,
      profitMarginPercent: margin,
    );
  }).toList()
    ..sort((a, b) => b.totalProfit.compareTo(a.totalProfit));

  return items;
});

// Customer Purchase Patterns Provider
final customerPatternsProvider = Provider<List<CustomerPatternItem>>((ref) {
  final customers = ref.watch(customersListProvider).value ?? [];
  final sales = ref.watch(salesListProvider).value ?? [];

  final Map<String, List<dynamic>> customerSales = {};

  for (final s in sales) {
    if (s.customerId != null) {
      customerSales.putIfAbsent(s.customerId!, () => []).add(s);
    }
  }

  final List<CustomerPatternItem> patterns = [];

  for (final c in customers) {
    final mySales = customerSales[c.id] ?? [];
    int totalSpend = 0;
    DateTime? lastDate;
    final Map<String, int> methodCounts = {};

    for (final s in mySales) {
      totalSpend += (s.totalAmount as int);
      final dt = s.createdAt as DateTime;
      if (lastDate == null || dt.isAfter(lastDate)) {
        lastDate = dt;
      }
      final method = s.paymentMethod.name as String;
      methodCounts[method] = (methodCounts[method] ?? 0) + 1;
    }

    String topMethod = 'Cash';
    int maxCount = 0;
    for (final entry in methodCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        topMethod = entry.key.toUpperCase();
      }
    }

    final count = mySales.length;
    final aov = count > 0 ? (totalSpend / count).round() : 0;

    patterns.add(CustomerPatternItem(
      customerId: c.id,
      customerName: c.name,
      phone: c.phone,
      ordersCount: count,
      totalSpent: totalSpend,
      averageSpend: aov,
      preferredPaymentMethod: topMethod,
      lastOrderDate: lastDate,
    ));
  }

  patterns.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
  return patterns;
});

class _ProfitAgg {
  _ProfitAgg(this.name, this.qty, this.revenue, this.cost, this.profit);

  final String name;
  final int qty;
  final int revenue;
  final int cost;
  final int profit;
}
