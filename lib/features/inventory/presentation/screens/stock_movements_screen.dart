import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import '../../domain/entities/stock_movement_entity.dart';
import '../../../business/presentation/widgets/branch_selector.dart';

class StockMovementsScreen extends ConsumerWidget {
  const StockMovementsScreen({super.key});

  Color _getTypeColor(StockMovementType type) {
    switch (type) {
      case StockMovementType.sale:
        return Colors.blue;
      case StockMovementType.restock:
        return Colors.green;
      case StockMovementType.adjustment:
        return Colors.orange;
      case StockMovementType.damaged:
        return Colors.red;
      case StockMovementType.expired:
        return Colors.purple;
      case StockMovementType.transfer:
        return Colors.teal;
      case StockMovementType.returned:
        return Colors.amber.shade800;
    }
  }

  IconData _getTypeIcon(StockMovementType type) {
    switch (type) {
      case StockMovementType.sale:
        return Icons.point_of_sale;
      case StockMovementType.restock:
        return Icons.add_business;
      case StockMovementType.adjustment:
        return Icons.tune;
      case StockMovementType.damaged:
        return Icons.broken_image;
      case StockMovementType.expired:
        return Icons.event_busy;
      case StockMovementType.transfer:
        return Icons.swap_horiz;
      case StockMovementType.returned:
        return Icons.assignment_return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(stockMovementsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement Audit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(stockMovementsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Branch selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .3),
            child: Row(
              children: [
                Icon(Icons.store, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(child: BranchSelector()),
              ],
            ),
          ),
          Expanded(
            child: movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(stockMovementsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (movements) {
                if (movements.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No Stock Movements Yet',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Stock additions, sales, and manual adjustments will appear here in chronological order.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.outline),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: movements.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = movements[index];
                    final color = _getTypeColor(m.type);
                    final icon = _getTypeIcon(m.type);
                    final qtyText = m.quantity > 0 ? '+${m.quantity}' : '${m.quantity}';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          m.productName ?? 'Product Item',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: m.isAddition
                                              ? Colors.green.withValues(alpha: .12)
                                              : Colors.red.withValues(alpha: .12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          qtyText,
                                          style: TextStyle(
                                            color: m.isAddition
                                                ? Colors.green.shade800
                                                : Colors.red.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (m.variantName != null &&
                                      m.variantName!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Variant: ${m.variantName}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: .15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          m.type.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      if (m.batchNumber != null &&
                                          m.batchNumber!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          'Batch: ${m.batchNumber}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.outline,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                      if (m.userName != null) ...[
                                        const Spacer(),
                                        Text(
                                          'By: ${m.userName}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.outline,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (m.reason != null &&
                                      m.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      m.reason!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormat.format(m.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
