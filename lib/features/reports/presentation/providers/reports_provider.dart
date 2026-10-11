import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/report_entities.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../debts/presentation/providers/debts_provider.dart';
import '../../../debts/domain/entities/debt_entity.dart';

final reportDateFilterProvider = StateProvider<ReportDateFilter>((ref) {
  return ReportDateFilter.thisMonth;
});

class CustomDateRange {
  const CustomDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

final customDateRangeProvider = StateProvider<CustomDateRange>((ref) {
  final now = DateTime.now();
  return CustomDateRange(
    start: DateTime(now.year, now.month, 1),
    end: DateTime(now.year, now.month, now.day, 23, 59, 59),
  );
});

// Helper function to check if a date falls within the selected filter
bool _isDateInRange(DateTime date, ReportDateFilter filter, CustomDateRange customRange) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (filter) {
    case ReportDateFilter.today:
      return date.isAfter(startOfToday.subtract(const Duration(seconds: 1))) &&
          date.isBefore(endOfToday.add(const Duration(seconds: 1)));
    case ReportDateFilter.thisWeek:
      final monday = startOfToday.subtract(Duration(days: startOfToday.weekday - 1));
      return date.isAfter(monday.subtract(const Duration(seconds: 1))) &&
          date.isBefore(endOfToday.add(const Duration(seconds: 1)));
    case ReportDateFilter.thisMonth:
      final startOfMonth = DateTime(now.year, now.month, 1);
      return date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
          date.isBefore(endOfToday.add(const Duration(seconds: 1)));
    case ReportDateFilter.thisYear:
      final startOfYear = DateTime(now.year, 1, 1);
      return date.isAfter(startOfYear.subtract(const Duration(seconds: 1))) &&
          date.isBefore(endOfToday.add(const Duration(seconds: 1)));
    case ReportDateFilter.custom:
      return date.isAfter(customRange.start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(customRange.end.add(const Duration(seconds: 1)));
  }
}

// Sales Report Provider
final salesReportProvider = Provider<AsyncValue<SalesReportData>>((ref) {
  final salesAsync = ref.watch(salesListProvider);
  final filter = ref.watch(reportDateFilterProvider);
  final customRange = ref.watch(customDateRangeProvider);
  final productsAsync = ref.watch(productsListProvider);

  return salesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (allSales) {
      final filteredSales = allSales.where((s) => _isDateInRange(s.createdAt, filter, customRange)).toList();

      int totalRevenue = 0;
      final Map<String, int> dailyTotals = {};
      final Map<String, int> dailyCounts = {};
      final Map<String, _ProductAgg> productMap = {};
      final Map<String, int> categoryTotals = {};
      final Map<String, int> categoryCounts = {};
      final Map<String, _StaffAgg> staffMap = {};

      for (final sale in filteredSales) {
        totalRevenue += sale.totalAmount;

        final dayKey = '${sale.createdAt.year}-${sale.createdAt.month.toString().padLeft(2, '0')}-${sale.createdAt.day.toString().padLeft(2, '0')}';
        dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + sale.totalAmount;
        dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;

        final staffName = sale.cashierName ?? 'Staff #${sale.cashierId.substring(0, 4)}';
        final current = staffMap[sale.cashierId] ?? _StaffAgg(staffName, 0, 0);
        staffMap[sale.cashierId] = _StaffAgg(staffName, current.total + sale.totalAmount, current.count + 1);

        for (final item in sale.items) {
          final pAgg = productMap[item.productId] ?? _ProductAgg(item.productName, item.variantName, 0, 0, 0);
          final profit = (item.unitPrice - item.unitCostPrice) * item.quantity;
          productMap[item.productId] = _ProductAgg(
            item.productName,
            item.variantName,
            pAgg.qty + item.quantity,
            pAgg.revenue + item.totalPrice,
            pAgg.profit + profit,
          );
        }
      }

      // Map categories from products if available
      final products = productsAsync.value ?? [];
      for (final p in products) {
        final catName = p.category?.name ?? 'Uncategorized';
        final agg = productMap[p.id];
        if (agg != null) {
          categoryTotals[catName] = (categoryTotals[catName] ?? 0) + agg.revenue;
          categoryCounts[catName] = (categoryCounts[catName] ?? 0) + agg.qty;
        }
      }

      final dailyPoints = dailyTotals.entries.map((e) {
        final parts = e.key.split('-');
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        return DailySalesPoint(
          date: d,
          totalAmount: e.value,
          salesCount: dailyCounts[e.key] ?? 0,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final topProducts = productMap.entries.map((e) {
        return ProductSalesStat(
          productId: e.key,
          productName: e.value.name,
          sku: e.value.sku,
          quantitySold: e.value.qty,
          totalRevenue: e.value.revenue,
          totalProfit: e.value.profit,
        );
      }).toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      final categoryStats = categoryTotals.entries.map((e) {
        final pct = totalRevenue > 0 ? (e.value / totalRevenue) * 100 : 0.0;
        return CategorySalesStat(
          categoryName: e.key,
          totalRevenue: e.value,
          itemsCount: categoryCounts[e.key] ?? 0,
          percentage: pct,
        );
      }).toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      final staffStats = staffMap.entries.map((e) {
        return StaffSalesStat(
          staffId: e.key,
          staffName: e.value.name,
          totalRevenue: e.value.total,
          salesCount: e.value.count,
        );
      }).toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      final count = filteredSales.length;
      final avg = count > 0 ? (totalRevenue / count).round() : 0;

      return AsyncValue.data(
        SalesReportData(
          totalRevenue: totalRevenue,
          totalSalesCount: count,
          averageOrderValue: avg,
          dailyPoints: dailyPoints,
          topProducts: topProducts,
          categoryStats: categoryStats,
          staffStats: staffStats,
        ),
      );
    },
  );
});

// Financial Report Provider (P&L, Cash flow, Margin)
final financialReportProvider = Provider<AsyncValue<FinancialReportData>>((ref) {
  final salesReportAsync = ref.watch(salesReportProvider);
  final expensesAsync = ref.watch(expensesListProvider);
  final filter = ref.watch(reportDateFilterProvider);
  final customRange = ref.watch(customDateRangeProvider);

  if (salesReportAsync.isLoading || expensesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (salesReportAsync.hasError) {
    return AsyncValue.error(salesReportAsync.error!, salesReportAsync.stackTrace!);
  }

  if (expensesAsync.hasError) {
    return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  }

  final salesData = salesReportAsync.value!;
  final allExpenses = expensesAsync.value ?? [];
  final filteredExpenses = allExpenses.where((e) => _isDateInRange(e.expenseDate, filter, customRange)).toList();

  int totalExpenses = 0;
  final Map<String, int> expenseByCat = {};

  for (final exp in filteredExpenses) {
    totalExpenses += exp.amount;
    final catName = exp.categoryName ?? 'Other Expenses';
    expenseByCat[catName] = (expenseByCat[catName] ?? 0) + exp.amount;
  }

  final grossSales = salesData.totalRevenue;
  int totalItemProfit = 0;
  for (final p in salesData.topProducts) {
    totalItemProfit += p.totalProfit;
  }
  final cogs = (grossSales - totalItemProfit).clamp(0, grossSales);
  final grossProfit = grossSales - cogs;
  final grossMarginPct = grossSales > 0 ? (grossProfit / grossSales) * 100 : 0.0;

  final netProfit = grossProfit - totalExpenses;
  final netMarginPct = grossSales > 0 ? (netProfit / grossSales) * 100 : 0.0;

  final expenseCategoryStats = expenseByCat.entries.map((e) {
    final pct = totalExpenses > 0 ? (e.value / totalExpenses) * 100 : 0.0;
    return ExpenseCategoryStat(
      categoryName: e.key,
      totalAmount: e.value,
      percentage: pct,
    );
  }).toList()
    ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

  final totalCashIn = grossSales;
  final totalCashOut = totalExpenses + cogs;
  final netCashFlow = totalCashIn - totalCashOut;

  return AsyncValue.data(
    FinancialReportData(
      grossSales: grossSales,
      costOfGoodsSold: cogs,
      grossProfit: grossProfit,
      grossMarginPercent: grossMarginPct,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      netMarginPercent: netMarginPct,
      totalCashIn: totalCashIn,
      totalCashOut: totalCashOut,
      netCashFlow: netCashFlow,
      expenseCategories: expenseCategoryStats,
    ),
  );
});

// Inventory Valuation & Health Report Provider
final inventoryReportProvider = Provider<AsyncValue<InventoryReportData>>((ref) {
  final productsAsync = ref.watch(productsListProvider);

  return productsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (products) {
      int totalUnits = 0;
      int totalCost = 0;
      int totalRetail = 0;
      int lowStock = 0;
      int outOfStock = 0;

      for (final p in products) {
        final stock = p.currentBranchStock;
        totalUnits += stock;
        totalCost += p.costPrice * stock;
        totalRetail += p.sellingPrice * stock;

        if (stock <= 0) {
          outOfStock++;
        } else if (p.isLowStock) {
          lowStock++;
        }
      }

      final potentialProfit = totalRetail - totalCost;

      return AsyncValue.data(
        InventoryReportData(
          totalSkus: products.length,
          totalStockUnits: totalUnits,
          totalCostValue: totalCost,
          totalRetailValue: totalRetail,
          potentialProfit: potentialProfit,
          lowStockCount: lowStock,
          outOfStockCount: outOfStock,
        ),
      );
    },
  );
});

// Customer & Debt Aging Report Provider
final customerSupplierReportProvider = Provider<AsyncValue<DebtAgingReportData>>((ref) {
  final debtsAsync = ref.watch(debtsListProvider);

  return debtsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (debts) {
      int current30 = 0;
      int days31To60 = 0;
      int days61To90 = 0;
      int overdue90 = 0;
      int totalRec = 0;

      final receivables = debts.where((d) => d.debtType == DebtType.receivable && d.status != DebtStatus.paid);

      for (final r in receivables) {
        final bal = r.remainingBalance;
        totalRec += bal;
        switch (r.agingBucket) {
          case AgingBucket.current:
            current30 += bal;
            break;
          case AgingBucket.thirtyDays:
            days31To60 += bal;
            break;
          case AgingBucket.sixtyDays:
            days61To90 += bal;
            break;
          case AgingBucket.ninetyDaysPlus:
            overdue90 += bal;
            break;
        }
      }

      return AsyncValue.data(
        DebtAgingReportData(
          current30Days: current30,
          days31To60: days31To60,
          days61To90: days61To90,
          overdue90Plus: overdue90,
          totalReceivables: totalRec,
        ),
      );
    },
  );
});

// Private helper classes for internal aggregation
class _ProductAgg {
  _ProductAgg(this.name, this.sku, this.qty, this.revenue, this.profit);

  final String name;
  final String? sku;
  final int qty;
  final int revenue;
  final int profit;
}

class _StaffAgg {
  _StaffAgg(this.name, this.total, this.count);

  final String name;
  final int total;
  final int count;
}
