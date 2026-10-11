import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/customer_entity.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_form_dialog.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../sales/presentation/screens/sale_receipt_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  void _openEditDialog(CustomerEntity customer) {
    showDialog<CustomerEntity>(
      context: context,
      builder: (_) => CustomerFormDialog(customerToEdit: customer),
    );
  }

  void _confirmDelete(CustomerEntity customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Are you sure you want to remove "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(customerControllerProvider.notifier)
                  .deleteCustomer(customer.id);
              if (success && mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer removed.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openDebtRepaymentDialog(CustomerEntity customer) {
    final amountController = TextEditingController(
      text: (customer.outstandingBalance / 100).toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Debt Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer currently owes: ${(customer.outstandingBalance / 100).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Repayment Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  final parsed = double.tryParse(val ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid payment amount';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final val = double.parse(amountController.text.trim());
              final minorAmount = (val * 100).round();
              Navigator.of(ctx).pop();

              final updated = await ref
                  .read(customerControllerProvider.notifier)
                  .recordDebtRepayment(
                    customerId: customer.id,
                    paymentAmount: minorAmount,
                  );

              if (updated != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debt repayment recorded successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final salesAsync = ref.watch(customerSalesHistoryProvider(widget.customerId));
    final currentBiz = ref.watch(currentBusinessProvider);
    final currency = currentBiz?.defaultCurrency ?? 'NGN';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return customerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Error loading customer: $err'),
        ),
      ),
      data: (customer) {
        final balanceFormatted = (customer.outstandingBalance / 100).toStringAsFixed(2);
        final creditLimitFormatted = (customer.creditLimit / 100).toStringAsFixed(2);

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Profile',
                onPressed: () => _openEditDialog(customer),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(customer),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerDetailProvider(widget.customerId));
              ref.invalidate(customerSalesHistoryProvider(widget.customerId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile & Contact Card
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
                              radius: 28,
                              backgroundColor: customer.hasDebt
                                  ? Colors.red.shade100
                                  : colorScheme.primaryContainer,
                              child: Text(
                                customer.initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: customer.hasDebt
                                      ? Colors.red.shade900
                                      : colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (customer.phone != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      customer.phone!,
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                  ],
                                  if (customer.email != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      customer.email!,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (customer.address != null && customer.address!.isNotEmpty) ...[
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on_outlined, size: 18, color: colorScheme.outline),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  customer.address!,
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes_outlined, size: 18, color: colorScheme.outline),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  customer.notes!,
                                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Balance & Debt Card
                Card(
                  elevation: 0,
                  color: customer.hasDebt ? Colors.red.shade50 : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: customer.hasDebt ? Colors.red.shade200 : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Outstanding Debt',
                                  style: TextStyle(
                                    color: customer.hasDebt ? Colors.red.shade800 : colorScheme.outline,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currency $balanceFormatted',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: customer.hasDebt ? Colors.red.shade900 : colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            if (customer.creditLimit > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Credit Limit',
                                    style: TextStyle(color: colorScheme.outline, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$currency $creditLimitFormatted',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (customer.hasDebt) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
                              onPressed: () => _openDebtRepaymentDialog(customer),
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('Record Debt Payment'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Purchase History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Purchase History',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${salesAsync.value?.length ?? 0} orders',
                      style: TextStyle(color: colorScheme.outline, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                salesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Could not load purchase history: $err'),
                    ),
                  ),
                  data: (sales) {
                    if (sales.isEmpty) {
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 40, color: colorScheme.outline),
                              const SizedBox(height: 8),
                              const Text('No past purchases recorded for this customer yet.'),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final sale = sales[idx];
                        final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(sale.createdAt);
                        final totalFormatted = (sale.totalAmount / 100).toStringAsFixed(2);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SaleReceiptScreen(sale: sale, currency: currency),
                                ),
                              );
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.receipt, color: colorScheme.onPrimaryContainer, size: 20),
                            ),
                            title: Text(sale.saleNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$dateStr\n${sale.items.length} item(s) • ${sale.paymentMethod.label}'),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$currency $totalFormatted',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
