import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../domain/entities/product_entity.dart';
import '../services/label_printing_service.dart';
import '../../../business/presentation/providers/business_provider.dart';

class BarcodeGeneratorDialog extends ConsumerStatefulWidget {
  const BarcodeGeneratorDialog({
    super.key,
    required this.product,
    required this.currency,
  });

  final ProductEntity product;
  final String currency;

  @override
  ConsumerState<BarcodeGeneratorDialog> createState() =>
      _BarcodeGeneratorDialogState();
}

class _BarcodeGeneratorDialogState
    extends ConsumerState<BarcodeGeneratorDialog> {
  bool _useQrCode = false;
  int _labelCount = 24;
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);

    final barcodeData = widget.product.barcode?.isNotEmpty == true
        ? widget.product.barcode!
        : (widget.product.sku?.isNotEmpty == true
              ? widget.product.sku!
              : widget.product.id.substring(0, 8));

    final priceFormatted = (widget.product.sellingPrice / 100).toStringAsFixed(
      2,
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Row(
        children: [
          Icon(Icons.qr_code_2, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Barcode & Price Label',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.currency} $priceFormatted',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Barcode Widget Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: BarcodeWidget(
                        barcode: _useQrCode
                            ? Barcode.qrCode()
                            : Barcode.code128(),
                        data: barcodeData,
                        width: _useQrCode ? 130 : 210,
                        height: _useQrCode ? 130 : 65,
                        drawText: !_useQrCode,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: barcodeData));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Barcode copied to clipboard'),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              barcodeData,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Barcode Type Toggle
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('Code-128'),
                    selected: !_useQrCode,
                    onSelected: (val) => setState(() => _useQrCode = !val),
                  ),
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: const Text('QR Code'),
                    selected: _useQrCode,
                    onSelected: (val) => setState(() => _useQrCode = val),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Labels per Sheet
              Row(
                children: [
                  const Text('Quantity:'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _labelCount,
                          isExpanded: true,
                          isDense: true,
                          items: const [
                            DropdownMenuItem(
                              value: 12,
                              child: Text('12 Labels'),
                            ),
                            DropdownMenuItem(
                              value: 24,
                              child: Text('24 Labels (A4)'),
                            ),
                            DropdownMenuItem(
                              value: 48,
                              child: Text('48 Labels'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _labelCount = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: _isPrinting
              ? null
              : () async {
                  setState(() => _isPrinting = true);
                  try {
                    await LabelPrintingService.printProductLabels(
                      product: widget.product,
                      currency: widget.currency,
                      business: business,
                      labelCount: _labelCount,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Print error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isPrinting = false);
                  }
                },
          icon: _isPrinting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.print),
          label: const Text('Print Labels'),
        ),
      ],
    );
  }
}
