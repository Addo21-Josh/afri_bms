import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/sale_entity.dart';
import '../../../business/domain/entities/business_entity.dart';
import '../../../business/domain/entities/branch_entity.dart';

class PdfReceiptService {
  /// Generate a PDF receipt document.
  /// [isThermal]: if true, formats as an 80mm or 58mm thermal receipt roll.
  static Future<Uint8List> generateReceiptPdf({
    required SaleEntity sale,
    required String currency,
    BusinessEntity? business,
    BranchEntity? branch,
    bool isThermal = false,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(sale.createdAt);

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load(
        'assets/logo/monochrome_logo.jpg',
      );
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      // Fallback gracefully if asset is unavailable or in a test environment
    }

    final subtotalFormatted = (sale.subtotal / 100).toStringAsFixed(2);
    final totalFormatted = (sale.totalAmount / 100).toStringAsFixed(2);
    final tenderedFormatted = (sale.amountTendered / 100).toStringAsFixed(2);
    final changeFormatted = (sale.changeGiven / 100).toStringAsFixed(2);
    final discountFormatted = (sale.discountAmount / 100).toStringAsFixed(2);
    final taxFormatted = (sale.taxAmount / 100).toStringAsFixed(2);

    final pageFormat = isThermal ? PdfPageFormat.roll80 : PdfPageFormat.a5;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null) ...[
                pw.Center(
                  child: pw.Image(
                    logoImage,
                    width: isThermal ? 40 : 50,
                    height: isThermal ? 40 : 50,
                  ),
                ),
                pw.SizedBox(height: 6),
              ],
              // Business Header
              pw.Text(
                business?.name ?? 'Afri_BMS Store',
                style: pw.TextStyle(
                  fontSize: isThermal ? 16 : 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (branch?.name != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(branch!.name, style: const pw.TextStyle(fontSize: 10)),
              ],
              if (business?.address != null &&
                  business!.address!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  business.address!,
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (business?.phone != null && business!.phone!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Tel: ${business.phone!}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Sale Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Receipt #: ${sale.saleNumber}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    formattedDate,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              if (sale.cashierName != null) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Cashier: ${sale.cashierName}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
              if (sale.customerName != null &&
                  sale.customerName!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Customer: ${sale.customerName!}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 6),

              // Line Items Header
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      'ITEM',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'QTY',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'PRICE',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'TOTAL',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),

              // Line Items
              ...sale.items.map((item) {
                final itemUnit = (item.unitPrice / 100).toStringAsFixed(2);
                final itemTotal = (item.totalPrice / 100).toStringAsFixed(2);
                final displayName = item.variantName != null
                    ? '${item.productName} (${item.variantName})'
                    : item.productName;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          displayName,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${item.quantity}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          itemUnit,
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          itemTotal,
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),

              // Totals Breakdown
              _buildSummaryRow('Subtotal', '$currency $subtotalFormatted'),
              if (sale.discountAmount > 0)
                _buildSummaryRow('Discount', '-$currency $discountFormatted'),
              if (sale.taxAmount > 0)
                _buildSummaryRow('Tax', '+$currency $taxFormatted'),

              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL DUE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '$currency $totalFormatted',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 4),

              // Payment Details
              _buildSummaryRow('Payment Method', sale.paymentMethod.label),
              if (sale.paymentReference != null &&
                  sale.paymentReference!.isNotEmpty)
                _buildSummaryRow('Reference / Code', sale.paymentReference!),
              if (sale.paymentMethod == PaymentMethod.cash) ...[
                _buildSummaryRow(
                  'Amount Tendered',
                  '$currency $tenderedFormatted',
                ),
                _buildSummaryRow(
                  'Change Returned',
                  '$currency $changeFormatted',
                ),
              ],
              if (sale.paymentMethod == PaymentMethod.credit) ...[
                _buildSummaryRow(
                  'Initial Paid',
                  '$currency $tenderedFormatted',
                ),
                _buildSummaryRow(
                  'Balance Due (Credit)',
                  '$currency ${((sale.totalAmount - sale.amountTendered) / 100).toStringAsFixed(2)}',
                ),
              ],

              pw.SizedBox(height: 12),

              // QR Code Validation
              pw.BarcodeWidget(
                data: 'https://afribms.app/receipt/${sale.saleNumber}',
                barcode: pw.Barcode.qrCode(),
                width: 60,
                height: 60,
              ),

              pw.SizedBox(height: 8),
              pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Afri_BMS • Retail Operating System',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
