import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/debt_entity.dart';
import '../providers/debts_provider.dart';
import '../widgets/create_debt_dialog.dart';
import 'debt_detail_screen.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getAgingBadgeColor(AgingBucket bucket) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);
    final currency = business?.defaultCurrency ?? 'GHS';

    final currentFilter = ref.watch(debtFilterProvider);
    final debtsAsync = ref.watch(debtsListProvider);

    final isReceivable = currentFilter.debtType == DebtType.receivable;
    final totalReceivables = ref.watch(totalReceivablesSummaryProvider).value ?? 0;
    final totalPayables = ref.watch(totalPayablesSummaryProvider).value ?? 0;
    final activeTotal = isReceivable ? totalReceivables : totalPayables;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt & Credit Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(debtsListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => CreateDebtDialog(initialType: currentFilter.debtType),
          );
          if (created == true) {
            ref.read(debtsListProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(isReceivable ? 'New Receivable' : 'New Payable'),
      ),
      body: Column(
        children: [
          // Top Segmented Type Picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<DebtType>(
              segments: const [
                ButtonSegment(
                  value: DebtType.receivable,
                  icon: Icon(Icons.call_received, size: 18),
                  label: Text('Receivables (Customers)'),
                ),
                ButtonSegment(
                  value: DebtType.payable,
                  icon: Icon(Icons.call_made, size: 18),
                  label: Text('Payables (Suppliers)'),
                ),
              ],
              selected: {currentFilter.debtType},
              onSelectionChanged: (set) {
                ref.read(debtFilterProvider.notifier).update(
                      (s) => s.copyWith(debtType: set.first),
                    );
              },
            ),
          ),

          // Total Balance Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isReceivable
                    ? [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withValues(alpha: 0.6),
                      ]
                    : [
                        colorScheme.tertiaryContainer,
                        colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  isReceivable ? Icons.account_balance_wallet : Icons.receipt_long,
                  color: isReceivable ? colorScheme.primary : colorScheme.tertiary,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceivable ? 'TOTAL UNCOLLECTED RECEIVABLES' : 'TOTAL UNPAID SUPPLIER PAYABLES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: isReceivable ? colorScheme.onPrimaryContainer : colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.format(activeTotal, currencyCode: currency),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isReceivable ? colorScheme.primary : colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isReceivable ? 'Search customer name or phone...' : 'Search supplier name...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(debtFilterProvider.notifier).update((s) => s.copyWith(searchQuery: ''));
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(debtFilterProvider.notifier).update((s) => s.copyWith(searchQuery: val));
              },
            ),
          ),

          // Aging Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Aging'),
                  selected: currentFilter.agingBucket == null,
                  onSelected: (val) {
                    ref.read(debtFilterProvider.notifier).update((s) => s.copyWith(clearAging: true));
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Current (< 30d)'),
                  selected: currentFilter.agingBucket == AgingBucket.current,
                  onSelected: (val) {
                    ref.read(debtFilterProvider.notifier).update(
                          (s) => s.copyWith(agingBucket: val ? AgingBucket.current : null, clearAging: !val),
                        );
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('30 - 59d'),
                  selected: currentFilter.agingBucket == AgingBucket.thirtyDays,
                  onSelected: (val) {
                    ref.read(debtFilterProvider.notifier).update(
                          (s) => s.copyWith(agingBucket: val ? AgingBucket.thirtyDays : null, clearAging: !val),
                        );
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('60 - 89d'),
                  selected: currentFilter.agingBucket == AgingBucket.sixtyDays,
                  onSelected: (val) {
                    ref.read(debtFilterProvider.notifier).update(
                          (s) => s.copyWith(agingBucket: val ? AgingBucket.sixtyDays : null, clearAging: !val),
                        );
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('90d+ (Overdue)'),
                  selected: currentFilter.agingBucket == AgingBucket.ninetyDaysPlus,
                  avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                  onSelected: (val) {
                    ref.read(debtFilterProvider.notifier).update(
                          (s) => s.copyWith(agingBucket: val ? AgingBucket.ninetyDaysPlus : null, clearAging: !val),
                        );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 12),

          // Debts List View
          Expanded(
            child: debtsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error loading debts: $err'),
                ),
              ),
              data: (debts) {
                if (debts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isReceivable ? Icons.check_circle_outline : Icons.sentiment_satisfied_alt,
                            size: 64,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isReceivable ? 'No outstanding receivables!' : 'No unpaid supplier bills!',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isReceivable
                                ? 'All customers are fully settled up.'
                                : 'All supplier payables are up to date.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: debts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final debt = debts[index];
                    final dateCreated = DateFormat('MMM d, yyyy').format(debt.createdAt);
                    final agingColor = _getAgingBadgeColor(debt.agingBucket);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: debt.isOverdue ? Colors.red.shade300 : colorScheme.outlineVariant,
                          width: debt.isOverdue ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DebtDetailScreen(debtId: debt.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: agingColor.withValues(alpha: 0.15),
                                    child: Icon(
                                      isReceivable ? Icons.person : Icons.local_shipping,
                                      color: agingColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          debt.personName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '$dateCreated • ${debt.daysElapsed}d elapsed',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: agingColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: agingColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      debt.agingBucket.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: agingColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Balance and Progress
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining: ${CurrencyFormatter.format(debt.remainingBalance, currencyCode: currency)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: debt.isOverdue ? Colors.red.shade900 : colorScheme.error,
                                    ),
                                  ),
                                  Text(
                                    'Initial: ${CurrencyFormatter.format(debt.initialAmount, currencyCode: currency)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: debt.initialAmount > 0
                                    ? (debt.paidAmount / debt.initialAmount).clamp(0.0, 1.0)
                                    : 0.0,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                                backgroundColor: Colors.grey.shade200,
                                color: debt.status == DebtStatus.paid ? Colors.green : colorScheme.primary,
                              ),
                            ],
                          ),
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
