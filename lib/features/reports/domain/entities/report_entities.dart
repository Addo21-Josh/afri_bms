import 'package:flutter/foundation.dart';

enum ReportDateFilter { today, thisWeek, thisMonth, thisYear, custom }

extension ReportDateFilterX on ReportDateFilter {
  String get label {
    switch (this) {
      case ReportDateFilter.today:
        return 'Today';
      case ReportDateFilter.thisWeek:
        return 'This Week';
      case ReportDateFilter.thisMonth:
        return 'This Month';
      case ReportDateFilter.thisYear:
        return 'This Year';
      case ReportDateFilter.custom:
        return 'Custom Range';
    }
  }
}

@immutable
class DailySalesPoint {
  const DailySalesPoint({
    required this.date,
    required this.totalAmount,
    required this.salesCount,
  });

  final DateTime date;
  final int totalAmount;
  final int salesCount;
}

@immutable
class ProductSalesStat {
  const ProductSalesStat({
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalProfit,
  });

  final String productId;
  final String productName;
  final String? sku;
  final int quantitySold;
  final int totalRevenue;
  final int totalProfit;
}

@immutable
class CategorySalesStat {
  const CategorySalesStat({
    required this.categoryName,
    required this.totalRevenue,
    required this.itemsCount,
    required this.percentage,
  });

  final String categoryName;
  final int totalRevenue;
  final int itemsCount;
  final double percentage;
}

@immutable
class StaffSalesStat {
  const StaffSalesStat({
    required this.staffId,
    required this.staffName,
    required this.totalRevenue,
    required this.salesCount,
  });

  final String staffId;
  final String staffName;
  final int totalRevenue;
  final int salesCount;
}

@immutable
class SalesReportData {
  const SalesReportData({
    required this.totalRevenue,
    required this.totalSalesCount,
    required this.averageOrderValue,
    required this.dailyPoints,
    required this.topProducts,
    required this.categoryStats,
    required this.staffStats,
  });

  final int totalRevenue;
  final int totalSalesCount;
  final int averageOrderValue;
  final List<DailySalesPoint> dailyPoints;
  final List<ProductSalesStat> topProducts;
  final List<CategorySalesStat> categoryStats;
  final List<StaffSalesStat> staffStats;
}

@immutable
class ExpenseCategoryStat {
  const ExpenseCategoryStat({
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
  });

  final String categoryName;
  final int totalAmount;
  final double percentage;
}

@immutable
class FinancialReportData {
  const FinancialReportData({
    required this.grossSales,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.grossMarginPercent,
    required this.totalExpenses,
    required this.netProfit,
    required this.netMarginPercent,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.netCashFlow,
    required this.expenseCategories,
  });

  final int grossSales;
  final int costOfGoodsSold;
  final int grossProfit;
  final double grossMarginPercent;
  final int totalExpenses;
  final int netProfit;
  final double netMarginPercent;
  final int totalCashIn;
  final int totalCashOut;
  final int netCashFlow;
  final List<ExpenseCategoryStat> expenseCategories;
}

@immutable
class InventoryReportData {
  const InventoryReportData({
    required this.totalSkus,
    required this.totalStockUnits,
    required this.totalCostValue,
    required this.totalRetailValue,
    required this.potentialProfit,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  final int totalSkus;
  final int totalStockUnits;
  final int totalCostValue;
  final int totalRetailValue;
  final int potentialProfit;
  final int lowStockCount;
  final int outOfStockCount;
}

@immutable
class CustomerStat {
  const CustomerStat({
    required this.customerId,
    required this.customerName,
    this.phone,
    required this.totalSpent,
    required this.ordersCount,
    required this.outstandingBalance,
  });

  final String customerId;
  final String customerName;
  final String? phone;
  final int totalSpent;
  final int ordersCount;
  final int outstandingBalance;
}

@immutable
class DebtAgingReportData {
  const DebtAgingReportData({
    required this.current30Days,
    required this.days31To60,
    required this.days61To90,
    required this.overdue90Plus,
    required this.totalReceivables,
  });

  final int current30Days;
  final int days31To60;
  final int days61To90;
  final int overdue90Plus;
  final int totalReceivables;
}
