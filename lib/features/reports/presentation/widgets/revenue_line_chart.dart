import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/report_entities.dart';
import '../../../../core/utils/currency_formatter.dart';

class RevenueLineChart extends StatelessWidget {
  const RevenueLineChart({
    super.key,
    required this.dailyPoints,
    required this.currency,
  });

  final List<DailySalesPoint> dailyPoints;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (dailyPoints.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(
          'No sales transactions in this period yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
      );
    }

    // Convert daily points to spots
    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < dailyPoints.length; i++) {
      final yVal = dailyPoints[i].totalAmount / 100.0;
      if (yVal > maxY) maxY = yVal;
      spots.add(FlSpot(i.toDouble(), yVal));
    }

    if (maxY == 0) maxY = 100;
    final bufferMax = maxY * 1.25;

    return AspectRatio(
      aspectRatio: 1.8,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (bufferMax / 4).clamp(1.0, double.infinity),
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (dailyPoints.length / 5).clamp(
                    1.0,
                    double.infinity,
                  ),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < dailyPoints.length) {
                      final date = dailyPoints[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('d MMM').format(date),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (bufferMax / 4).clamp(1.0, double.infinity),
                  reservedSize: 55,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      CurrencyFormatter.format(
                        (value * 100).toInt(),
                        currencyCode: currency,
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (dailyPoints.length - 1).toDouble().clamp(
              0.0,
              double.infinity,
            ),
            minY: 0,
            maxY: bufferMax,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colorScheme.inverseSurface,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final point = index < dailyPoints.length
                        ? dailyPoints[index]
                        : null;
                    final dateStr = point != null
                        ? DateFormat('EEE, d MMM').format(point.date)
                        : '';
                    final amountFormatted = CurrencyFormatter.format(
                      (spot.y * 100).toInt(),
                      currencyCode: currency,
                    );

                    return LineTooltipItem(
                      '$dateStr\n$amountFormatted (${point?.salesCount ?? 0} sales)',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: colorScheme.primary,
                barWidth: 3.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: dailyPoints.length < 15,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 4,
                        color: colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: colorScheme.surface,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.3),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
