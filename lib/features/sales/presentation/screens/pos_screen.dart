import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pos_cart_provider.dart';
import '../widgets/checkout_dialog.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../../inventory/domain/entities/variant_entity.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/presentation/screens/barcode_scanner_screen.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../business/presentation/widgets/branch_selector.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/shared_widgets.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(String code, List<ProductEntity> products) {
    final cleanCode = code.trim();
    ProductEntity? matchedProduct;
    ProductVariantEntity? matchedVariant;

    for (final p in products) {
      if (p.barcode?.trim() == cleanCode || p.sku?.trim() == cleanCode) {
        matchedProduct = p;
        break;
      }
      for (final v in p.variants) {
        if (v.sku?.trim() == cleanCode) {
          matchedProduct = p;
          matchedVariant = v;
          break;
        }
      }
      if (matchedProduct != null) break;
    }

    if (matchedProduct != null) {
      if (matchedVariant != null) {
        ref.read(posCartProvider.notifier).addItem(matchedProduct, variant: matchedVariant);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${matchedProduct.name} (${matchedVariant.name})" to cart'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else if (matchedProduct.variants.isNotEmpty) {
        _showVariantPicker(matchedProduct);
      } else {
        ref.read(posCartProvider.notifier).addItem(matchedProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${matchedProduct.name}" to cart'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found with barcode "$cleanCode"'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  void _showVariantPicker(ProductEntity product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Variant for ${product.name}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...product.variants.map((v) => ListTile(
                  leading: const Icon(Icons.style_outlined),
                  title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(v.sku ?? ''),
                  trailing: Text(
                    CurrencyFormatter.format(v.sellingPrice, currencyCode: product.currency),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onTap: () {
                    ref.read(posCartProvider.notifier).addItem(product, variant: v);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${product.name} (${v.name})" to cart'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CartBottomSheet(currency: currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final currentBiz = ref.watch(currentBusinessProvider);
    final cart = ref.watch(posCartProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = currentBiz?.defaultCurrency ?? 'GHS';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale (POS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Barcode',
            onPressed: () async {
              final scannedCode = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
              );
              if (scannedCode != null && mounted) {
                productsAsync.whenData((prods) {
                  _onBarcodeScanned(scannedCode, prods);
                });
              }
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: cart.isNotEmpty,
              label: Text('${cart.totalItemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => _showCartBottomSheet(context, currency),
          ),
        ],
      ),
      body: Column(
        children: [
          // Branch selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                Icon(Icons.storefront, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(child: BranchSelector()),
              ],
            ),
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Categories Filter Chips
          categoriesAsync.maybeWhen(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All Items'),
                        selected: _selectedCategory == null,
                        onSelected: (_) => setState(() => _selectedCategory = null),
                      ),
                    ),
                    ...categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat.name),
                            selected: _selectedCategory == cat.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat.id : null;
                              });
                            },
                          ),
                        )),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // Products Grid / Catalog
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorStateWidget(
                message: err.toString(),
                onRetry: () => ref.refresh(productsListProvider),
              ),
              data: (products) {
                final query = _searchController.text.trim().toLowerCase();
                var filtered = products;

                if (_selectedCategory != null) {
                  filtered = filtered.where((p) => p.categoryId == _selectedCategory).toList();
                }

                if (query.isNotEmpty) {
                  filtered = filtered.where((p) {
                    final matchesName = p.name.toLowerCase().contains(query);
                    final matchesSku = p.sku?.toLowerCase().contains(query) ?? false;
                    final matchesBarcode = p.barcode?.toLowerCase().contains(query) ?? false;
                    return matchesName || matchesSku || matchesBarcode;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 64, color: colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try adjusting your search query or category filter.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Adaptive grid column count
                    final crossAxisCount = constraints.maxWidth > 800
                        ? 4
                        : (constraints.maxWidth > 500 ? 3 : 2);

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final isOutOfStock = product.currentBranchStock <= 0;

                        return InkWell(
                          onTap: () {
                            if (product.variants.isNotEmpty) {
                              _showVariantPicker(product);
                            } else {
                              ref.read(posCartProvider.notifier).addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added "${product.name}" to cart'),
                                  duration: const Duration(milliseconds: 800),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withOpacity(0.6),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product visual placeholder or stock badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          product.variants.isNotEmpty
                                              ? Icons.style_outlined
                                              : Icons.inventory_2_outlined,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      // Stock Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOutOfStock
                                              ? Colors.red.withOpacity(0.12)
                                              : (product.isLowStock
                                                  ? Colors.orange.withOpacity(0.12)
                                                  : Colors.green.withOpacity(0.12)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isOutOfStock
                                              ? 'Out'
                                              : '${product.currentBranchStock} ${product.unit}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isOutOfStock
                                                ? Colors.red.shade800
                                                : (product.isLowStock
                                                    ? Colors.orange.shade800
                                                    : Colors.green.shade800),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Product Name
                                  Text(
                                    product.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (product.variants.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${product.variants.length} variants',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  // Price
                                  Text(
                                    CurrencyFormatter.format(
                                      product.sellingPrice,
                                      currencyCode: product.currency,
                                    ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Sticky Bottom Cart Bar
      bottomSheet: cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.totalItemCount} items in cart',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        ),
                        Text(
                          CurrencyFormatter.format(cart.totalAmount, currencyCode: currency),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _showCartBottomSheet(context, currency),
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('View Cart / Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _CartBottomSheet extends ConsumerStatefulWidget {
  const _CartBottomSheet({required this.currency});

  final String currency;

  @override
  ConsumerState<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends ConsumerState<_CartBottomSheet> {
  void _showDiscountDialog(BuildContext context) {
    final cart = ref.read(posCartProvider);
    final discCtrl = TextEditingController(
      text: cart.discountValue > 0 ? cart.discountValue.toString() : '',
    );
    CartDiscountType selectedType = cart.discountType == CartDiscountType.none
        ? CartDiscountType.percentage
        : cart.discountType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Apply Order Discount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<CartDiscountType>(
                segments: const [
                  ButtonSegment(
                    value: CartDiscountType.percentage,
                    label: Text('% Percentage'),
                  ),
                  ButtonSegment(
                    value: CartDiscountType.fixed,
                    label: Text('Fixed Amount'),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (set) => setDlgState(() => selectedType = set.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: selectedType == CartDiscountType.percentage
                      ? 'Discount Percentage (e.g. 10)'
                      : 'Fixed Amount in Major Units (e.g. 50)',
                  suffixText: selectedType == CartDiscountType.percentage ? '%' : widget.currency,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(posCartProvider.notifier).setDiscount(CartDiscountType.none, 0);
                Navigator.pop(ctx);
              },
              child: const Text('Remove Discount'),
            ),
            FilledButton(
              onPressed: () {
                final val = int.tryParse(discCtrl.text.trim()) ?? 0;
                if (selectedType == CartDiscountType.fixed) {
                  // Convert major to minor units
                  ref.read(posCartProvider.notifier).setDiscount(selectedType, val * 100);
                } else {
                  ref.read(posCartProvider.notifier).setDiscount(selectedType, val);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posCartProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
            child: Row(
              children: [
                Text(
                  'Cart Items (${cart.totalItemCount})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: cart.isEmpty
                      ? null
                      : () => ref.read(posCartProvider.notifier).clearCart(),
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('Clear'),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cart Items List
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('Your cart is empty', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text('Tap items in catalog or scan barcodes to add.'),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(item.unitPrice, currencyCode: widget.currency),
                                  style: TextStyle(color: colorScheme.outline, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          // Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () => ref
                                      .read(posCartProvider.notifier)
                                      .decrementQuantity(item.product.id, item.variant?.id),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () => ref
                                      .read(posCartProvider.notifier)
                                      .incrementQuantity(item.product.id, item.variant?.id),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Total Price
                          Text(
                            CurrencyFormatter.format(item.lineTotal, currencyCode: widget.currency),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Financial Summary & Actions
          if (cart.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.2),
                border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text(CurrencyFormatter.format(cart.subtotal, currencyCode: widget.currency)),
                    ],
                  ),
                  if (cart.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(color: Colors.green)),
                        Text(
                          '-${CurrencyFormatter.format(cart.discountAmount, currencyCode: widget.currency)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                  if (cart.taxAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax:'),
                        Text(
                          '+${CurrencyFormatter.format(cart.taxAmount, currencyCode: widget.currency)}',
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.local_offer_outlined, size: 16),
                        label: Text(
                          cart.discountAmount > 0 ? 'Edit Discount' : 'Add Discount',
                        ),
                        onPressed: () => _showDiscountDialog(context),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.receipt_outlined, size: 16),
                        label: Text(
                          cart.taxRatePercent > 0 ? 'Tax: ${cart.taxRatePercent}%' : 'Add Tax',
                        ),
                        onPressed: () {
                          final newRate = cart.taxRatePercent > 0 ? 0.0 : 7.5;
                          ref.read(posCartProvider.notifier).setTaxRate(newRate);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Grand Total:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        CurrencyFormatter.format(cart.totalAmount, currencyCode: widget.currency),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close cart sheet
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => CheckoutDialog(currency: widget.currency),
                        );
                      },
                      icon: const Icon(Icons.payment),
                      label: Text(
                        'Proceed to Checkout (${CurrencyFormatter.format(cart.totalAmount, currencyCode: widget.currency)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
