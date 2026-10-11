import 'package:flutter/material.dart';
import '../../domain/entities/report_entities.dart';
import '../../../../core/utils/currency_formatter.dart';

class TopProductsBarChart extends StatelessWidget {
  const TopProductsBarChart({
    super.key,
    required this.products,
    required this.currency,
    this.maxItems = 5,
  });

  final List<ProductSalesStat> products;
  final String currency;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayList = products.take(maxItems).toList();

    if (displayList.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          'No product sales recorded in this period',
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    final maxRevenue = displayList.first.totalRevenue;

    return Column(
      children: displayList.asMap().entries.map((entry) {
        final index = entry.key;
        final p = entry.value;
        final ratio = maxRevenue > 0 ? (p.totalRevenue / maxRevenue).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(p.totalRevenue, currencyCode: currency),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          index == 0
                              ? colorScheme.primary
                              : (index == 1 ? Colors.indigo : Colors.teal),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${p.quantitySold} units',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
