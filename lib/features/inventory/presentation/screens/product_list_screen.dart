import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import '../widgets/category_selector.dart';
import 'barcode_scanner_screen.dart';
import '../../../users/presentation/providers/staff_provider.dart';
import '../../../users/domain/entities/staff_user_entity.dart';
import 'package:afri_bms/features/business/presentation/widgets/branch_selector.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/utils/currency_formatter.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final userRole = ref.watch(currentUserRoleProvider).value;
    final isStaff = userRole == UserRoleType.salesperson || userRole == UserRoleType.cashier;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: isStaff ? 'Product Catalog' : 'Inventory & Products',
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner_outlined),
          tooltip: 'Scan Barcode',
          onPressed: () async {
            final scanned = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
            );
            if (scanned != null && scanned.isNotEmpty) {
              setState(() {
                _searchController.text = scanned;
              });
              ref.read(productSearchQueryProvider.notifier).state = scanned;
            }
          },
        ),
      ],
      floatingActionButton: isStaff
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/inventory/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
      body: Column(
        children: [
          // Branch selector header
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: BranchSelector(),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                          ref.read(productSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                ref.read(productSearchQueryProvider.notifier).state = val;
              },
            ),
          ),

          // Category filter
          const CategorySelectorBar(),
          const SizedBox(height: 8),

          // Product list
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return EmptyStateWidget(
                    title: 'No products found',
                    subtitle: _searchController.text.isNotEmpty
                        ? 'No products match your search query.'
                        : 'Your inventory is empty. Add your first product to begin tracking stock and processing sales.',
                    icon: Icons.inventory_2_outlined,
                    action: FilledButton.icon(
                      onPressed: () => context.push('/inventory/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Product'),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(productsListProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = products[index];

                      // Stock status badge
                      Color stockBadgeColor;
                      Color stockTextColor;
                      String stockStatusText;

                      if (product.currentBranchStock <= 0) {
                        stockBadgeColor = colorScheme.errorContainer;
                        stockTextColor = colorScheme.onErrorContainer;
                        stockStatusText = 'Out of Stock';
                      } else if (product.isLowStock) {
                        stockBadgeColor = Colors.amber.shade100;
                        stockTextColor = Colors.amber.shade900;
                        stockStatusText = 'Low Stock (${product.currentBranchStock} ${product.unit})';
                      } else {
                        stockBadgeColor = Colors.green.shade50;
                        stockTextColor = Colors.green.shade800;
                        stockStatusText = '${product.currentBranchStock} ${product.unit} in stock';
                      }

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push('/inventory/${product.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail or Icon
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.inventory_2_outlined, size: 28),
                                ),
                                const SizedBox(width: 14),

                                // Product info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (product.category != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.secondaryContainer,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                product.category!.name,
                                                style: TextStyle(
                                                  color: colorScheme.onSecondaryContainer,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (product.variants.isNotEmpty)
                                            Text(
                                              '${product.variants.length} variants',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.outline,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            CurrencyFormatter.format(
                                              product.sellingPrice,
                                              currencyCode: product.currency,
                                            ),
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: stockBadgeColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              stockStatusText,
                                              style: TextStyle(
                                                color: stockTextColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorStateWidget(
                message: err.toString(),
                onRetry: () => ref.refresh(productsListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
