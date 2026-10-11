import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/report_entities.dart';
import '../../../../core/utils/currency_formatter.dart';

class ExpensePieChart extends StatefulWidget {
  const ExpensePieChart({
    super.key,
    required this.categories,
    required this.currency,
    required this.totalExpenses,
  });

  final List<ExpenseCategoryStat> categories;
  final String currency;
  final int totalExpenses;

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int _touchedIndex = -1;

  final List<Color> _palette = const [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFF3949AB),
    Color(0xFFD81B60),
    Color(0xFF7CB342),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.categories.isEmpty || widget.totalExpenses == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No expenses recorded in this period',
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 46,
              sections: List.generate(widget.categories.length, (i) {
                final isTouched = i == _touchedIndex;
                final fontSize = isTouched ? 14.0 : 11.0;
                final radius = isTouched ? 65.0 : 54.0;
                final cat = widget.categories[i];
                final color = _palette[i % _palette.length];

                return PieChartSectionData(
                  color: color,
                  value: cat.totalAmount.toDouble(),
                  title: '${cat.percentage.toStringAsFixed(1)}%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend List
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(widget.categories.length, (i) {
            final cat = widget.categories[i];
            final color = _palette[i % _palette.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '${cat.categoryName}: ${CurrencyFormatter.format(cat.totalAmount, currencyCode: widget.currency)}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
