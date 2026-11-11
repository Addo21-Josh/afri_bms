import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/product_entity.dart';
import '../../../business/domain/entities/business_entity.dart';

class LabelPrintingService {
  /// Generate a PDF sheet containing multiple barcode price tags for a product
  static Future<Uint8List> generateProductLabelsPdf({
    required ProductEntity product,
    required String currency,
    BusinessEntity? business,
    int labelCount = 24,
  }) async {
    final doc = pw.Document();
    final priceFormatted = (product.sellingPrice / 100).toStringAsFixed(2);
    final barcodeData = product.barcode?.isNotEmpty == true
        ? product.barcode!
        : (product.sku?.isNotEmpty == true
              ? product.sku!
              : product.id.substring(0, 8));

    // A4 grid with 3 columns x 8 rows = 24 labels
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.GridView(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: List.generate(labelCount, (index) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      business?.name ?? 'Afri_BMS Store',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      product.name,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '$currency $priceFormatted',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(
                      data: barcodeData,
                      barcode: pw.Barcode.code128(),
                      width: 120,
                      height: 28,
                      drawText: true,
                      textStyle: const pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );

    return doc.save();
  }

  /// Trigger direct printing of labels to a label printer or standard printer
  static Future<void> printProductLabels({
    required ProductEntity product,
    required String currency,
    BusinessEntity? business,
    int labelCount = 24,
  }) async {
    final pdfBytes = await generateProductLabelsPdf(
      product: product,
      currency: currency,
      business: business,
      labelCount: labelCount,
    );

    await Printing.layoutPdf(
      name: 'Labels_${product.name}',
      onLayout: (format) async => pdfBytes,
    );
  }
}
