import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/debt_entity.dart';
import '../providers/debts_provider.dart';
import '../widgets/record_debt_payment_dialog.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key, required this.debtId});

  final String debtId;

  Color _getAgingColor(AgingBucket bucket) {
    switch (bucket) {
      case AgingBucket.current:
        return Colors.green;
      case AgingBucket.thirtyDays:
        return Colors.blue;
      case AgingBucket.sixtyDays:
        return Colors.orange;
      case AgingBucket.ninetyDaysPlus:
        return Colors.red;
    }
  }

  void _launchCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  void _launchWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);
    final currency = business?.defaultCurrency ?? 'GHS';

    final debtAsync = ref.watch(debtDetailProvider(debtId));
    final paymentsAsync = ref.watch(debtPaymentsListProvider(debtId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Record Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(debtDetailProvider(debtId));
              ref.invalidate(debtPaymentsListProvider(debtId));
            },
          ),
        ],
      ),
      body: debtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading debt details: $err'),
          ),
        ),
        data: (debt) {
          final isReceivable = debt.debtType == DebtType.receivable;
          final progress = debt.initialAmount > 0
              ? (debt.paidAmount / debt.initialAmount).clamp(0.0, 1.0)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Person Info Card
                Card(
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
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: isReceivable
                                  ? colorScheme.primaryContainer
                                  : colorScheme.secondaryContainer,
                              child: Icon(
                                isReceivable
                                    ? Icons.person
                                    : Icons.local_shipping,
                                color: isReceivable
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    debt.personName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (debt.personPhone != null)
                                    Text(
                                      debt.personPhone!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final agingColor = _getAgingColor(
                                  debt.agingBucket,
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: debt.status == DebtStatus.paid
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : (debt.isOverdue
                                              ? Colors.red.withValues(
                                                  alpha: 0.1,
                                                )
                                              : agingColor.withValues(
                                                  alpha: 0.1,
                                                )),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: debt.status == DebtStatus.paid
                                          ? Colors.green.shade300
                                          : (debt.isOverdue
                                                ? Colors.red.shade300
                                                : agingColor.withValues(
                                                    alpha: 0.4,
                                                  )),
                                    ),
                                  ),
                                  child: Text(
                                    debt.status == DebtStatus.paid
                                        ? 'PAID'
                                        : (debt.isOverdue
                                              ? 'OVERDUE'
                                              : debt.agingBucket.label),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: debt.status == DebtStatus.paid
                                          ? Colors.green.shade900
                                          : (debt.isOverdue
                                                ? Colors.red.shade900
                                                : agingColor),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        if (debt.personPhone != null &&
                            debt.personPhone!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _launchCall(context, debt.personPhone!),
                                icon: const Icon(Icons.call, size: 16),
                                label: const Text('Call'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _launchWhatsApp(context, debt.personPhone!),
                                icon: const Icon(Icons.chat, size: 16),
                                label: const Text('WhatsApp'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Balance & Progress Card
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BALANCE & PROGRESS',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Initial Debt',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(
                                      debt.initialAmount,
                                      currencyCode: currency,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Paid',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(
                                      debt.paidAmount,
                                      currencyCode: currency,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Remaining',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(
                                      debt.remainingBalance,
                                      currencyCode: currency,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Progress Bar
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                          backgroundColor: Colors.grey.shade200,
                          color: progress >= 1.0
                              ? Colors.green
                              : colorScheme.primary,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}% Repaid',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (debt.dueDate != null)
                              Text(
                                'Due: ${DateFormat('MMM d, yyyy').format(debt.dueDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: debt.isOverdue
                                      ? Colors.red
                                      : Colors.grey.shade700,
                                  fontWeight: debt.isOverdue
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons (Record Repayment, Mark Bad Debt, Cancel)
                if (debt.status == DebtStatus.active &&
                    debt.remainingBalance > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final recorded = await showDialog<bool>(
                          context: context,
                          builder: (_) => RecordDebtPaymentDialog(
                            debt: debt,
                            currency: currency,
                          ),
                        );
                        if (recorded == true) {
                          ref.invalidate(debtDetailProvider(debtId));
                          ref.invalidate(debtPaymentsListProvider(debtId));
                        }
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        'Record Repayment',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Mark as Bad Debt?'),
                                content: const Text(
                                  'This writes off the remaining balance as an unrecoverable loss.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Mark Bad Debt'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(debtControllerProvider.notifier)
                                  .updateDebtStatus(debt, DebtStatus.badDebt);
                            }
                          },
                          child: const Text(
                            'Write-off Bad Debt',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Payment History Section
                Text(
                  'Repayment History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                paymentsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading payments: $err'),
                  data: (payments) {
                    if (payments.isEmpty) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              'No repayments recorded yet for this debt.',
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final p = payments[idx];
                        final dateStr = DateFormat(
                          'MMM d, yyyy • h:mm a',
                        ).format(p.createdAt);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              CurrencyFormatter.format(
                                p.amount,
                                currencyCode: currency,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '$dateStr\n${p.paymentMethod.toUpperCase()} ${p.paymentReference != null ? '• ${p.paymentReference}' : ''}',
                            ),
                            isThreeLine: p.notes != null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
