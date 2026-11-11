import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/alert_entity.dart';
import '../providers/alerts_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final alerts = ref.watch(filteredAlertsProvider);
    final allAlerts = ref.watch(businessAlertsProvider);
    final activeFilter = ref.watch(selectedAlertFilterProvider);

    final lowStockCount = allAlerts
        .where(
          (a) => a.type == AlertType.lowStock || a.type == AlertType.outOfStock,
        )
        .length;
    final overdueCount = allAlerts
        .where((a) => a.type == AlertType.overdueDebt)
        .length;
    final salesCount = allAlerts
        .where((a) => a.type == AlertType.dailySalesTarget)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
        actions: [
          if (allAlerts.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                final allIds = allAlerts.map((a) => a.id).toSet();
                ref
                    .read(dismissedAlertIdsProvider.notifier)
                    .update((state) => {...state, ...allIds});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All alerts dismissed')),
                );
              },
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Dismiss All'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All (${allAlerts.length})'),
                    selected: activeFilter == null,
                    onSelected: (_) =>
                        ref.read(selectedAlertFilterProvider.notifier).state =
                            null,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: Text('Inventory ($lowStockCount)'),
                    selected: activeFilter == AlertType.lowStock,
                    onSelected: (selected) =>
                        ref.read(selectedAlertFilterProvider.notifier).state =
                            selected ? AlertType.lowStock : null,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.money_off, size: 16),
                    label: Text('Debts ($overdueCount)'),
                    selected: activeFilter == AlertType.overdueDebt,
                    onSelected: (selected) =>
                        ref.read(selectedAlertFilterProvider.notifier).state =
                            selected ? AlertType.overdueDebt : null,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.point_of_sale, size: 16),
                    label: Text('Sales ($salesCount)'),
                    selected: activeFilter == AlertType.dailySalesTarget,
                    onSelected: (selected) =>
                        ref.read(selectedAlertFilterProvider.notifier).state =
                            selected ? AlertType.dailySalesTarget : null,
                  ),
                ],
              ),
            ),
          ),

          // Alerts List or Empty State
          Expanded(
            child: alerts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All Clear!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No active alerts or critical issues requiring your attention.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Dismissible(
                        key: Key(alert.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red.shade400,
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          ref
                              .read(dismissedAlertIdsProvider.notifier)
                              .update((state) => {...state, alert.id});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Dismissed: ${alert.title}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: _AlertCard(alert: alert),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.alert});

  final BusinessAlertEntity alert;

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red.shade700;
      case AlertSeverity.warning:
        return Colors.orange.shade800;
      case AlertSeverity.info:
        return Colors.blue.shade700;
    }
  }

  IconData _getAlertIcon(AlertType type, AlertSeverity severity) {
    switch (type) {
      case AlertType.outOfStock:
        return Icons.error_outline;
      case AlertType.lowStock:
        return Icons.warning_amber_rounded;
      case AlertType.overdueDebt:
        return Icons.assignment_late_outlined;
      case AlertType.expiringProduct:
        return Icons.hourglass_bottom;
      case AlertType.dailySalesTarget:
        return Icons.insights;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _getSeverityColor(alert.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getAlertIcon(alert.type, alert.severity),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: alert.severity == AlertSeverity.critical
                                    ? Colors.red.shade900
                                    : null,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alert.severity.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM, HH:mm').format(alert.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alert.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (alert.actionRoute != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref
                          .read(dismissedAlertIdsProvider.notifier)
                          .update((s) => {...s, alert.id});
                    },
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.push(alert.actionRoute!),
                    child: Text(alert.actionLabel ?? 'Take Action'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
