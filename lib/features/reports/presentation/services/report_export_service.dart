import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/report_entities.dart';
import '../../../sales/domain/entities/sale_entity.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../../../core/utils/currency_formatter.dart';

class ReportExportService {
  /// Converts a matrix of rows into standard RFC-4180 CSV format
  static String toCsvString(List<List<dynamic>> rows) {
    final sb = StringBuffer();
    for (final row in rows) {
      final line = row.map((field) {
        final str = field?.toString() ?? '';
        if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
      sb.writeln(line);
    }
    return sb.toString();
  }

  /// Exports Sales Transactions as CSV and shares
  static Future<void> exportSalesCsv({
    required List<SaleEntity> sales,
    required String currency,
    required String businessName,
  }) async {
    final rows = <List<dynamic>>[
      ['Sale Number', 'Date', 'Time', 'Cashier', 'Customer', 'Payment Method', 'Items Count', 'Subtotal', 'Tax', 'Discount', 'Total Amount'],
    ];

    for (final s in sales) {
      final dateStr = DateFormat('yyyy-MM-dd').format(s.createdAt);
      final timeStr = DateFormat('HH:mm:ss').format(s.createdAt);
      final subtotal = (s.subtotal / 100.0).toStringAsFixed(2);
      final tax = (s.taxAmount / 100.0).toStringAsFixed(2);
      final disc = (s.discountAmount / 100.0).toStringAsFixed(2);
      final total = (s.totalAmount / 100.0).toStringAsFixed(2);

      rows.add([
        s.saleNumber,
        dateStr,
        timeStr,
        s.cashierName ?? s.cashierId,
        s.customerName ?? 'Walk-in',
        s.paymentMethod.name.toUpperCase(),
        s.items.length,
        subtotal,
        tax,
        disc,
        total,
      ]);
    }

    final csvContent = toCsvString(rows);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Sales_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvContent);

    await Share.shareXFiles([XFile(file.path)], text: 'Sales Report - $businessName ($currency)');
  }

  /// Exports Inventory Valuation Sheet as CSV
  static Future<void> exportInventoryCsv({
    required List<ProductEntity> products,
    required String currency,
    required String businessName,
  }) async {
    final rows = <List<dynamic>>[
      ['Product Name', 'SKU', 'Category', 'Unit', 'Stock Qty', 'Reorder Level', 'Cost Price', 'Selling Price', 'Total Cost Valuation', 'Total Retail Valuation', 'Stock Status'],
    ];

    for (final p in products) {
      final cost = (p.costPrice / 100.0).toStringAsFixed(2);
      final sell = (p.sellingPrice / 100.0).toStringAsFixed(2);
      final totalCost = ((p.costPrice * p.currentBranchStock) / 100.0).toStringAsFixed(2);
      final totalSell = ((p.sellingPrice * p.currentBranchStock) / 100.0).toStringAsFixed(2);
      final status = p.currentBranchStock == 0 ? 'Out of Stock' : (p.isLowStock ? 'Low Stock' : 'In Stock');

      rows.add([
        p.name,
        p.sku ?? '',
        p.category?.name ?? 'General',
        p.unit,
        p.currentBranchStock,
        p.reorderLevel,
        cost,
        sell,
        totalCost,
        totalSell,
        status,
      ]);
    }

    final csvContent = toCsvString(rows);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Inventory_Valuation_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvContent);

    await Share.shareXFiles([XFile(file.path)], text: 'Inventory Valuation - $businessName ($currency)');
  }

  /// Generates and Shares an Executive Summary PDF Report
  static Future<void> exportExecutiveSummaryPdf({
    required SalesReportData salesData,
    required FinancialReportData financialData,
    required InventoryReportData inventoryData,
    required String currency,
    required String businessName,
    String? branchName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(businessName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                  pw.SizedBox(height: 4),
                  pw.Text('Executive Performance & Financial Summary', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                  if (branchName != null)
                    pw.Text('Branch: $branchName', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Date Generated:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(DateFormat('dd MMM yyyy, HH:mm').format(now), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Currency: $currency', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.Divider(height: 24, thickness: 1.5, color: PdfColors.indigo900),

          // P&L Statement Section
          pw.Text('1. Profit & Loss Statement', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Line Item', 'Amount ($currency)', 'Margin %'],
            data: [
              ['Gross Sales Revenue', CurrencyFormatter.format(financialData.grossSales, currencyCode: currency), '100.0%'],
              ['Less: Cost of Goods Sold (COGS)', '- ${CurrencyFormatter.format(financialData.costOfGoodsSold, currencyCode: currency)}', '-'],
              ['Gross Profit', CurrencyFormatter.format(financialData.grossProfit, currencyCode: currency), '${financialData.grossMarginPercent.toStringAsFixed(1)}%'],
              ['Less: Operating Expenses', '- ${CurrencyFormatter.format(financialData.totalExpenses, currencyCode: currency)}', '-'],
              ['Net Operating Profit', CurrencyFormatter.format(financialData.netProfit, currencyCode: currency), '${financialData.netMarginPercent.toStringAsFixed(1)}%'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),

          // Inventory Valuation Section
          pw.Text('2. Inventory Asset Valuation & Health', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Products (SKUs)', '${inventoryData.totalSkus}'],
              ['Total Physical Units in Stock', '${inventoryData.totalStockUnits} units'],
              ['Asset Valuation at Cost Price', CurrencyFormatter.format(inventoryData.totalCostValue, currencyCode: currency)],
              ['Asset Valuation at Retail Selling Price', CurrencyFormatter.format(inventoryData.totalRetailValue, currencyCode: currency)],
              ['Potential Gross Inventory Profit', CurrencyFormatter.format(inventoryData.potentialProfit, currencyCode: currency)],
              ['Low Stock Alerts Count', '${inventoryData.lowStockCount} items'],
              ['Out of Stock Items', '${inventoryData.outOfStockCount} items'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 20),

          // Top Products by Revenue
          if (salesData.topProducts.isNotEmpty) ...[
            pw.Text('3. Top 5 Performing Products', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Rank', 'Product Name', 'Units Sold', 'Total Revenue ($currency)'],
              data: salesData.topProducts.take(5).toList().asMap().entries.map((e) {
                final idx = e.key + 1;
                final p = e.value;
                return [
                  '$idx',
                  p.productName,
                  '${p.quantitySold}',
                  CurrencyFormatter.format(p.totalRevenue, currencyCode: currency),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ],
          pw.SizedBox(height: 24),

          // Footer
          pw.Divider(color: PdfColors.grey400),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Report produced automatically by Afri_BMS', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ),
        ],
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Executive_Report_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Executive Report - $businessName ($currency)');
  }
}
