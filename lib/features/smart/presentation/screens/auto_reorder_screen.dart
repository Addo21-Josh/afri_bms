import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/smart_insights_provider.dart';
import '../../domain/entities/smart_insights_entity.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class AutoReorderScreen extends ConsumerStatefulWidget {
  const AutoReorderScreen({super.key});

  @override
  ConsumerState<AutoReorderScreen> createState() => _AutoReorderScreenState();
}

class _AutoReorderScreenState extends ConsumerState<AutoReorderScreen> {
  final Map<String, int> _customQuantities = {};

  void _sharePurchaseOrder(String businessName, String currency, List<AutoReorderItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('📋 *PURCHASE ORDER - $businessName*');
    buffer.writeln('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n');
    buffer.writeln('Please fulfill the following restock items:');
    buffer.writeln('--------------------------------');

    int totalEstimate = 0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final int qty = _customQuantities[item.product.id] ?? item.suggestedQuantity;
      final int lineCost = qty * item.unitCostPrice;
      totalEstimate += lineCost;
      final costFormatted = CurrencyFormatter.format(lineCost, currencyCode: currency);

      buffer.writeln('${i + 1}. *${item.product.name}*');
      buffer.writeln('   Quantity: $qty ${item.product.unit} (Est. $costFormatted)');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('*Total Estimated Cost:* ${CurrencyFormatter.format(totalEstimate, currencyCode: currency)}\n');
    buffer.writeln('Sent via Afri_BMS');

    Share.share(buffer.toString(), subject: 'Purchase Order - $businessName');
  }

  void _sendViaWhatsApp(String businessName, String currency, List<AutoReorderItem> items) async {
    final buffer = StringBuffer();
    buffer.writeln('📋 *PURCHASE ORDER - $businessName*%0A');
    buffer.writeln('Please fulfill the following restock items:%0A');
    for (final item in items) {
      final int qty = _customQuantities[item.product.id] ?? item.suggestedQuantity;
      buffer.writeln('• ${item.product.name}: $qty ${item.product.unit}%0A');
    }
    final url = Uri.parse('https://wa.me/?text=${buffer.toString()}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reorderItems = ref.watch(autoReorderListProvider);
    final business = ref.watch(currentBusinessProvider);
    final currency = business?.defaultCurrency ?? 'GHS';
    final businessName = business?.name ?? 'Afri_BMS Store';

    int grandTotal = 0;
    int totalUnits = 0;
    for (final item in reorderItems) {
      final qty = _customQuantities[item.product.id] ?? item.suggestedQuantity;
      grandTotal += qty * item.unitCostPrice;
      totalUnits += qty;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Reorder Generator'),
        actions: [
          if (reorderItems.isNotEmpty) ...[
            IconButton(
              tooltip: 'Send via WhatsApp',
              icon: const Icon(Icons.chat_outlined),
              onPressed: () => _sendViaWhatsApp(businessName, currency, reorderItems),
            ),
            IconButton(
              tooltip: 'Share Purchase Order',
              icon: const Icon(Icons.share),
              onPressed: () => _sharePurchaseOrder(businessName, currency, reorderItems),
            ),
          ],
        ],
      ),
      body: reorderItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
                    const SizedBox(height: 16),
                    Text('Inventory Well Stocked!', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'None of your products are currently below their reorder threshold.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Top Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Suggested Order Total', style: TextStyle(color: colorScheme.outline, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(grandTotal, currencyCode: currency),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Items & Units', style: TextStyle(color: colorScheme.outline, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${reorderItems.length} items ($totalUnits units)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Reorder Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reorderItems.length,
                    itemBuilder: (context, index) {
                      final item = reorderItems[index];
                      final currentQty = _customQuantities[item.product.id] ?? item.suggestedQuantity;
                      final lineTotal = currentQty * item.unitCostPrice;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stock: ${item.currentStock} ${item.product.unit} • Threshold: ${item.reorderLevel}',
                                          style: TextStyle(
                                            color: item.currentStock == 0 ? Colors.red.shade800 : Colors.orange.shade800,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward, size: 18),
                                    tooltip: 'Product Details',
                                    onPressed: () => context.push('/inventory/${item.product.id}'),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Quantity Counter Controls
                                  Row(
                                    children: [
                                      IconButton.filledTonal(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.remove, size: 16),
                                        onPressed: () {
                                          if (currentQty > 1) {
                                            setState(() {
                                              _customQuantities[item.product.id] = currentQty - 1;
                                            });
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          '$currentQty ${item.product.unit}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.add, size: 16),
                                        onPressed: () {
                                          setState(() {
                                            _customQuantities[item.product.id] = currentQty + 1;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  Text(
                                    CurrencyFormatter.format(lineTotal, currencyCode: currency),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: reorderItems.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _sharePurchaseOrder(businessName, currency, reorderItems),
                  icon: const Icon(Icons.send),
                  label: const Text('Export & Send Purchase Order'),
                ),
              ),
            )
          : null,
    );
  }
}
