import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/alert_entity.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../debts/presentation/providers/debts_provider.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

final selectedAlertFilterProvider = StateProvider<AlertType?>((ref) => null);

// Dismissed alert IDs store
final dismissedAlertIdsProvider = StateProvider<Set<String>>(
  (ref) => <String>{},
);

final businessAlertsProvider = Provider<List<BusinessAlertEntity>>((ref) {
  final products = ref.watch(productsListProvider).value ?? [];
  final debts = ref.watch(debtsListProvider).value ?? [];
  final sales = ref.watch(salesListProvider).value ?? [];
  final dismissed = ref.watch(dismissedAlertIdsProvider);
  final currentBiz = ref.watch(currentBusinessProvider);
  final currency = currentBiz?.defaultCurrency ?? 'GHS';

  final List<BusinessAlertEntity> alerts = [];
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  // 1. Inventory Alerts (Out of Stock & Low Stock)
  for (final product in products) {
    final stock = product.currentBranchStock;
    final reorder = product.reorderLevel;

    if (stock <= 0) {
      final alertId = 'out_of_stock_${product.id}';
      if (!dismissed.contains(alertId)) {
        alerts.add(
          BusinessAlertEntity(
            id: alertId,
            type: AlertType.outOfStock,
            severity: AlertSeverity.critical,
            title: 'Out of Stock: ${product.name}',
            message:
                '${product.name} has 0 units in stock! Sales are blocked or running at deficit.',
            timestamp: now,
            actionRoute: '/inventory/${product.id}',
            actionLabel: 'Restock / Adjust',
            metadata: {'productId': product.id, 'productName': product.name},
          ),
        );
      }
    } else if (stock <= reorder) {
      final alertId = 'low_stock_${product.id}';
      if (!dismissed.contains(alertId)) {
        final deficit = (reorder * 2) - stock;
        alerts.add(
          BusinessAlertEntity(
            id: alertId,
            type: AlertType.lowStock,
            severity: AlertSeverity.warning,
            title: 'Low Stock Alert: ${product.name}',
            message:
                'Only $stock ${product.unit} left (reorder threshold is $reorder). Suggested order: $deficit ${product.unit}.',
            timestamp: now,
            actionRoute: '/inventory/${product.id}',
            actionLabel: 'View Product',
            metadata: {
              'productId': product.id,
              'productName': product.name,
              'stock': stock,
              'reorder': reorder,
            },
          ),
        );
      }
    }
  }

  // 2. Overdue Debt Alerts
  for (final debt in debts) {
    if (debt.debtType == DebtType.receivable &&
        debt.status == DebtStatus.active &&
        debt.dueDate != null) {
      final due = debt.dueDate!;
      if (due.isBefore(startOfToday)) {
        final daysOverdue = startOfToday.difference(due).inDays;
        final alertId = 'overdue_debt_${debt.id}';

        if (!dismissed.contains(alertId)) {
          final isCritical = daysOverdue >= 30;
          final amountStr = CurrencyFormatter.format(
            debt.remainingBalance,
            currencyCode: currency,
          );

          alerts.add(
            BusinessAlertEntity(
              id: alertId,
              type: AlertType.overdueDebt,
              severity: isCritical
                  ? AlertSeverity.critical
                  : AlertSeverity.warning,
              title: isCritical
                  ? 'Critically Overdue Debt ($daysOverdue Days): ${debt.personName}'
                  : 'Overdue Receivable: ${debt.personName}',
              message:
                  '${debt.personName} owes $amountStr, which was due on ${due.day}/${due.month}/${due.year} ($daysOverdue days ago).',
              timestamp: due,
              actionRoute: '/debts/${debt.id}',
              actionLabel: 'View Ledger & Collect',
              metadata: {
                'debtId': debt.id,
                'personName': debt.personName,
                'phone': debt.personPhone,
                'balance': debt.remainingBalance,
              },
            ),
          );
        }
      }
    }
  }

  // 3. Daily Sales Performance Milestone
  int todaySalesTotal = 0;
  int todayCount = 0;
  for (final s in sales) {
    if (s.createdAt.isAfter(startOfToday)) {
      todaySalesTotal += s.totalAmount;
      todayCount++;
    }
  }

  final summaryAlertId =
      'daily_sales_${startOfToday.toIso8601String().substring(0, 10)}';
  if (!dismissed.contains(summaryAlertId) && todayCount > 0) {
    alerts.add(
      BusinessAlertEntity(
        id: summaryAlertId,
        type: AlertType.dailySalesTarget,
        severity: AlertSeverity.info,
        title: "Today's Sales Performance",
        message:
            'Recorded $todayCount completed sales today totaling ${CurrencyFormatter.format(todaySalesTotal, currencyCode: currency)}.',
        timestamp: now,
        actionRoute: '/reports',
        actionLabel: 'View Analytics',
        metadata: {'todaySales': todaySalesTotal, 'salesCount': todayCount},
      ),
    );
  }

  // Sort: Critical first, then Warning, then Info, then by timestamp descending
  alerts.sort((a, b) {
    final severityComp = a.severity.index.compareTo(b.severity.index);
    if (severityComp != 0) return severityComp;
    return b.timestamp.compareTo(a.timestamp);
  });

  return alerts;
});

final filteredAlertsProvider = Provider<List<BusinessAlertEntity>>((ref) {
  final allAlerts = ref.watch(businessAlertsProvider);
  final filter = ref.watch(selectedAlertFilterProvider);

  if (filter == null) return allAlerts;
  return allAlerts.where((a) => a.type == filter).toList();
});

final unreadAlertsCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(businessAlertsProvider);
  return alerts.length;
});
