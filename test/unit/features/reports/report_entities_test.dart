import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/features/reports/domain/entities/report_entities.dart';

void main() {
  group('Report Entities', () {
    test('ReportDateFilter labels are user-friendly', () {
      expect(ReportDateFilter.today.label, equals('Today'));
      expect(ReportDateFilter.thisWeek.label, equals('This Week'));
      expect(ReportDateFilter.thisMonth.label, equals('This Month'));
      expect(ReportDateFilter.thisYear.label, equals('This Year'));
      expect(ReportDateFilter.custom.label, equals('Custom Range'));
    });

    test(
      'FinancialReportData correctly holds profit and cash flow metrics',
      () {
        const financial = FinancialReportData(
          grossSales: 500000, // 5,000.00 GHS
          costOfGoodsSold: 300000, // 3,000.00 GHS
          grossProfit: 200000, // 2,000.00 GHS
          grossMarginPercent: 40.0,
          totalExpenses: 50000, // 500.00 GHS
          netProfit: 150000, // 1,500.00 GHS
          netMarginPercent: 30.0,
          totalCashIn: 480000,
          totalCashOut: 350000,
          netCashFlow: 130000,
          expenseCategories: [
            ExpenseCategoryStat(
              categoryName: 'Utilities',
              totalAmount: 30000,
              percentage: 60.0,
            ),
            ExpenseCategoryStat(
              categoryName: 'Transport',
              totalAmount: 20000,
              percentage: 40.0,
            ),
          ],
        );

        expect(
          financial.grossProfit,
          equals(financial.grossSales - financial.costOfGoodsSold),
        );
        expect(
          financial.netProfit,
          equals(financial.grossProfit - financial.totalExpenses),
        );
        expect(
          financial.netCashFlow,
          equals(financial.totalCashIn - financial.totalCashOut),
        );
        expect(financial.expenseCategories.length, equals(2));
      },
    );

    test('InventoryReportData holds valuation and stock counters', () {
      const inventory = InventoryReportData(
        totalSkus: 45,
        totalStockUnits: 820,
        totalCostValue: 410000,
        totalRetailValue: 656000,
        potentialProfit: 246000,
        lowStockCount: 4,
        outOfStockCount: 1,
      );

      expect(
        inventory.potentialProfit,
        equals(inventory.totalRetailValue - inventory.totalCostValue),
      );
      expect(inventory.totalSkus, equals(45));
      expect(inventory.lowStockCount, equals(4));
    });
  });
}
