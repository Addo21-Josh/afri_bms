import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expenses_provider.dart';
import '../widgets/expense_form_dialog.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _activeDateFilter = 'month'; // 'today', 'week', 'month', 'custom'

  void _setDatePreset(String preset) {
    setState(() => _activeDateFilter = preset);
    final now = DateTime.now();
    final filterNotifier = ref.read(expenseFilterProvider.notifier);

    switch (preset) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        filterNotifier.update((s) => s.copyWith(startDate: start, endDate: now));
        break;
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeek = DateTime(start.year, start.month, start.day);
        filterNotifier.update((s) => s.copyWith(startDate: startOfWeek, endDate: now));
        break;
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        filterNotifier.update((s) => s.copyWith(startDate: startOfMonth, endDate: now));
        break;
      case 'all':
        filterNotifier.update((s) => s.copyWith(clearDates: true));
        break;
    }
  }

  Future<void> _pickCustomDateRange() async {
    final filter = ref.read(expenseFilterProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: filter.startDate != null && filter.endDate != null
          ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
          : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );

    if (picked != null) {
      setState(() => _activeDateFilter = 'custom');
      ref.read(expenseFilterProvider.notifier).update(
            (s) => s.copyWith(startDate: picked.start, endDate: picked.end),
          );
    }
  }

  void _openExpenseForm([ExpenseEntity? expense]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ExpenseFormDialog(expense: expense),
    );
    if (result == true) {
      ref.read(expensesListProvider.notifier).refresh();
    }
  }

  void _confirmDeleteExpense(ExpenseEntity expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(expenseControllerProvider.notifier).deleteExpense(expense.id);
      if (mounted && !success) {
        final err = ref.read(expenseControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Failed to delete expense')),
        );
      }
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'apartment':
        return Icons.apartment;
      case 'people':
        return Icons.people;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'campaign':
        return Icons.campaign;
      case 'build':
        return Icons.build;
      case 'store':
        return Icons.store;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);
    final currency = business?.defaultCurrency ?? 'GHS';

    final expensesAsync = ref.watch(expensesListProvider);
    final categories = ref.watch(expenseCategoriesProvider).value ?? [];
    final currentFilter = ref.watch(expenseFilterProvider);
    final totalSpentMinor = ref.watch(expensesTotalAmountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses & Outflows'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(expensesListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Expense'),
      ),
      body: Column(
        children: [
          // Total Spent Summary Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.errorContainer,
                  colorScheme.errorContainer.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_down, color: colorScheme.error, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL EXPENSES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.format(totalSpentMinor, currencyCode: currency),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Filter by date range',
                  icon: const Icon(Icons.date_range),
                  onPressed: _pickCustomDateRange,
                ),
              ],
            ),
          ),

          // Date Presets Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('This Month'),
                  selected: _activeDateFilter == 'month',
                  onSelected: (val) {
                    if (val) _setDatePreset('month');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('This Week'),
                  selected: _activeDateFilter == 'week',
                  onSelected: (val) {
                    if (val) _setDatePreset('week');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _activeDateFilter == 'today',
                  onSelected: (val) {
                    if (val) _setDatePreset('today');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('All Time'),
                  selected: _activeDateFilter == 'all',
                  onSelected: (val) {
                    if (val) _setDatePreset('all');
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month, size: 16),
                  label: Text(_activeDateFilter == 'custom' && currentFilter.startDate != null
                      ? '${DateFormat('MMM d').format(currentFilter.startDate!)} - ${DateFormat('MMM d').format(currentFilter.endDate!)}'
                      : 'Custom Dates'),
                  onPressed: _pickCustomDateRange,
                ),
              ],
            ),
          ),

          // Category Filter Chips
          if (categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Categories'),
                    selected: currentFilter.categoryId == null,
                    onSelected: (val) {
                      ref.read(expenseFilterProvider.notifier).update((s) => s.copyWith(clearCategory: true));
                    },
                  ),
                  const SizedBox(width: 6),
                  ...categories.map((cat) {
                    final isSelected = currentFilter.categoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (val) {
                          ref.read(expenseFilterProvider.notifier).update(
                                (s) => s.copyWith(categoryId: val ? cat.id : null, clearCategory: !val),
                              );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

          const Divider(height: 12),

          // Expenses List
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading expenses: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.read(expensesListProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_outlined, size: 64, color: colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses found',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Track business costs like rent, utilities, fuel, and salaries.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _openExpenseForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Expense'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: expenses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    final dateFormatted = DateFormat('MMM d, yyyy').format(exp.expenseDate);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_getCategoryIcon(null), color: colorScheme.error, size: 22),
                        ),
                        title: Text(
                          exp.description,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('$dateFormatted • ${exp.categoryName ?? 'Uncategorized'}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    exp.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (exp.receiptUrl != null && exp.receiptUrl!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.attachment, size: 14, color: colorScheme.primary),
                                ],
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '- ${CurrencyFormatter.format(exp.amount, currencyCode: currency)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: colorScheme.error,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              padding: EdgeInsets.zero,
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _openExpenseForm(exp);
                                } else if (val == 'delete') {
                                  _confirmDeleteExpense(exp);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
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
