import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/sale_entity.dart';
import '../services/pdf_receipt_service.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/subscription/domain/models/subscription_tier.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';

class PdfReceiptPreviewScreen extends ConsumerStatefulWidget {
  const PdfReceiptPreviewScreen({
    super.key,
    required this.sale,
    required this.currency,
  });

  final SaleEntity sale;
  final String currency;

  @override
  ConsumerState<PdfReceiptPreviewScreen> createState() =>
      _PdfReceiptPreviewScreenState();
}

class _PdfReceiptPreviewScreenState
    extends ConsumerState<PdfReceiptPreviewScreen> {
  bool _isThermalFormat = false;

  Future<void> _shareReceiptPdf() async {
    final business = ref.read(currentBusinessProvider);
    final branch = ref.read(currentBranchProvider);

    final pdfBytes = await PdfReceiptService.generateReceiptPdf(
      sale: widget.sale,
      currency: widget.currency,
      business: business,
      branch: branch,
      isThermal: _isThermalFormat,
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Receipt_${widget.sale.saleNumber}.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Digital Receipt - ${widget.sale.saleNumber}',
      text: 'Here is your sales receipt for order #${widget.sale.saleNumber}',
    );
  }

  Future<void> _sendWhatsAppReceipt() async {
    final phone = widget.sale.customerPhone;
    final totalFormatted = (widget.sale.totalAmount / 100).toStringAsFixed(2);
    final bizName = ref.read(currentBusinessProvider)?.name ?? 'Our Store';

    final text =
        'Hello ${widget.sale.customerName ?? 'Customer'}! Thank you for shopping with $bizName. '
        'Your receipt #${widget.sale.saleNumber} total is ${widget.currency} $totalFormatted. '
        'View receipt online: https://afribms.app/receipt/${widget.sale.saleNumber}';

    final encoded = Uri.encodeComponent(text);
    Uri uri;
    if (phone != null && phone.isNotEmpty) {
      final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      uri = Uri.parse('https://wa.me/$clean?text=$encoded');
    } else {
      uri = Uri.parse('https://wa.me/?text=$encoded');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  Future<void> _sendSmsReceipt() async {
    final phone = widget.sale.customerPhone;
    final totalFormatted = (widget.sale.totalAmount / 100).toStringAsFixed(2);
    final bizName = ref.read(currentBusinessProvider)?.name ?? 'Our Store';

    final body =
        'Receipt from $bizName: Sale #${widget.sale.saleNumber}. '
        'Total: ${widget.currency} $totalFormatted. Paid: ${widget.sale.paymentMethod.label}. '
        'Thank you!';

    final uri = Uri(
      scheme: 'sms',
      path: phone ?? '',
      queryParameters: {'body': body},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open SMS app')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider);
    final branch = ref.watch(currentBranchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt #${widget.sale.saleNumber}'),
        actions: [
          IconButton(
            tooltip: _isThermalFormat
                ? 'Switch to A5 Page'
                : 'Switch to Thermal 80mm',
            icon: Icon(
              _isThermalFormat ? Icons.receipt_long : Icons.print_outlined,
            ),
            onPressed: () {
              if (!_isThermalFormat) {
                final gate = ref.read(featureGateProvider);
                if (!gate.limits.thermalPrinting) {
                  UpgradePromptSheet.show(
                    context,
                    featureName: 'Thermal Receipt Printing',
                    customMessage:
                        'Thermal 80mm/58mm printing is available on Afri_BMS Pro & Enterprise.',
                    currentTier: gate.tier,
                    suggestedTier: SubscriptionTier.pro,
                  );
                  return;
                }
              }
              setState(() => _isThermalFormat = !_isThermalFormat);
            },
          ),
          IconButton(
            tooltip: 'Share via WhatsApp',
            icon: const Icon(Icons.chat_outlined),
            onPressed: _sendWhatsAppReceipt,
          ),
          IconButton(
            tooltip: 'Send SMS',
            icon: const Icon(Icons.sms_outlined),
            onPressed: _sendSmsReceipt,
          ),
          IconButton(
            tooltip: 'Share PDF File',
            icon: const Icon(Icons.share),
            onPressed: _shareReceiptPdf,
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfReceiptService.generateReceiptPdf(
          sale: widget.sale,
          currency: widget.currency,
          business: business,
          branch: branch,
          isThermal: _isThermalFormat,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        dynamicLayout: false,
      ),
    );
  }
}
