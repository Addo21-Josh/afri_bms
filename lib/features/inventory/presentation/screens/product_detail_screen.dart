import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import 'product_form_screen.dart';
import '../widgets/barcode_generator_dialog.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../users/presentation/providers/staff_provider.dart';
import '../../../users/domain/entities/staff_user_entity.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/subscription/domain/models/subscription_tier.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../domain/constants/product_unit.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  void _openBarcodeDialog(BuildContext context, WidgetRef ref, dynamic product) {
    final gate = ref.read(featureGateProvider);
    if (!gate.limits.barcodeGeneration) {
      UpgradePromptSheet.show(
        context,
        featureName: 'Barcode & QR Code Generation',
        customMessage: 'Generating and exporting barcodes and label sheets is available on Afri_BMS Pro & Enterprise.',
        currentTier: gate.tier,
        suggestedTier: SubscriptionTier.pro,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => BarcodeGeneratorDialog(
        product: product,
        currency: product.currency,
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, WidgetRef ref, int currentStock, String branchId, String unit) {
    final qtyCtrl = TextEditingController(text: currentStock.toString());
    final reasonCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    DateTime? selectedExpiry;
    String selectedType = 'adjustment';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adjust Branch Stock'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Reason / Type',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'adjustment', child: Text('Count Correction / Audit')),
                    DropdownMenuItem(value: 'restock', child: Text('Restock / New Shipment')),
                    DropdownMenuItem(value: 'damaged', child: Text('Damaged / Broken')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired Goods')),
                    DropdownMenuItem(value: 'return', child: Text('Customer Return')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  decoration: InputDecoration(
                    labelText: 'New Total Quantity in Stock',
                    prefixIcon: const Icon(Icons.warehouse_outlined),
                    suffixText: unit,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: batchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Batch / Lot Number (Optional)',
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Justification',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedExpiry ?? DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedExpiry = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date (Optional)',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      selectedExpiry != null
                          ? '${selectedExpiry!.day}/${selectedExpiry!.month}/${selectedExpiry!.year}'
                          : 'Not set',
                      style: TextStyle(
                        color: selectedExpiry != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final newQty = int.tryParse(qtyCtrl.text.trim());
                if (newQty != null) {
                  final success = await ref.read(inventoryControllerProvider.notifier).adjustStock(
                    productId: productId,
                    branchId: branchId,
                    newQuantity: newQty,
                    type: selectedType,
                    reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                    batchNumber: batchCtrl.text.trim().isNotEmpty ? batchCtrl.text.trim() : null,
                    expiryDate: selectedExpiry,
                  );
                  if (ctx.mounted) {
                    if (success) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock count and audit log updated successfully')),
                      );
                    } else {
                      final rawError = ref.read(inventoryControllerProvider).error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            UserFriendlyError.toFriendly(
                              rawError,
                              defaultMessage: 'Unable to update stock audit. Please try again.',
                            ),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save Audit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final currentBranch = ref.watch(currentBranchProvider);
    final userRole = ref.watch(currentUserRoleProvider).value;
    // Explicit permission: Only Admin and Branch Manager can edit products, adjust stock, or view cost prices
    final canManageProducts = userRole == UserRoleType.admin || userRole == UserRoleType.branchManager;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: 'Product Details',
      actions: [
        if (canManageProducts)
          productAsync.maybeWhen(
            data: (product) => Row(
            children: [
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                tooltip: 'Barcode & Labels',
                onPressed: () => _openBarcodeDialog(context, ref, product),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Product',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(existingProduct: product),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                tooltip: 'Delete Product',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Product?'),
                      content: Text('Are you sure you want to delete ${product.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final success = await ref.read(inventoryControllerProvider.notifier).deleteProduct(productId);
                    if (context.mounted && success) {
                      context.pop();
                    }
                  }
                },
              ),
            ],
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
      body: productAsync.when(
        data: (product) {
          final profitMargin = product.sellingPrice > 0
              ? (((product.sellingPrice - product.costPrice) / product.sellingPrice) * 100).toStringAsFixed(1)
              : '0.0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Header Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.inventory_2, size: 36, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (product.category != null)
                                        Chip(
                                          visualDensity: VisualDensity.compact,
                                          label: Text(product.category!.name, style: const TextStyle(fontSize: 12)),
                                        ),
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        avatar: const Icon(Icons.straighten, size: 14),
                                        label: Text(ProductUnits.format(product.unit), style: const TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (product.description != null && product.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            product.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pricing Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financials & Pricing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Selling Price', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            Text(
                              CurrencyFormatter.format(product.sellingPrice, currencyCode: product.currency),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                          ],
                        ),
                        if (canManageProducts) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Cost Price', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              Text(
                                CurrencyFormatter.format(product.costPrice, currencyCode: product.currency),
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Profit Margin', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              Text(
                                '$profitMargin%',
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stock Level at Active Branch Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Stock Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            if (canManageProducts && currentBranch != null)
                              TextButton.icon(
                                onPressed: () => _showAdjustStockDialog(
                                  context,
                                  ref,
                                  product.currentBranchStock,
                                  currentBranch.id,
                                  product.unit,
                                ),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Adjust Stock'),
                              ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentBranch != null ? currentBranch.name : 'All Branches Total',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              '${product.currentBranchStock} ${product.unit}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: product.isLowStock ? Colors.orange.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reorder Level Alert', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            Text('${product.reorderLevel} ${product.unit}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Variants Card (if any)
                if (product.variants.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Product Variants (${product.variants.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Divider(height: 24),
                          ...product.variants.map((v) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(v.sku != null ? 'SKU: ${v.sku}' : 'Default Variant'),
                                trailing: Text(
                                  CurrencyFormatter.format(v.sellingPrice, currencyCode: product.currency),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Codes Card (SKU / Barcode)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Identifiers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('SKU', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            Text(product.sku ?? 'Not set', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Barcode', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            Text(product.barcode ?? 'Not set', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openBarcodeDialog(context, ref, product),
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('View Barcode & Print Labels'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(productDetailProvider(productId)),
        ),
      ),
    );
  }
}
