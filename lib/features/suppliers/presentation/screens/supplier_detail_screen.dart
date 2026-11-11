import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/supplier_entity.dart';
import '../providers/suppliers_provider.dart';
import '../widgets/supplier_form_dialog.dart';
import '../../../business/presentation/providers/business_provider.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  void _openEditDialog(SupplierEntity supplier) {
    showDialog<SupplierEntity>(
      context: context,
      builder: (_) => SupplierFormDialog(supplierToEdit: supplier),
    );
  }

  void _confirmDelete(SupplierEntity supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier?'),
        content: Text('Are you sure you want to remove "${supplier.name}"?'),
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
                  .read(supplierControllerProvider.notifier)
                  .deleteSupplier(supplier.id);
              if (success && mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Supplier removed.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openPaymentDialog(SupplierEntity supplier) {
    final amountController = TextEditingController(
      text: (supplier.outstandingBalance / 100).toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment to Supplier'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current balance owed: ${(supplier.outstandingBalance / 100).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                  .read(supplierControllerProvider.notifier)
                  .recordSupplierPayment(
                    supplierId: supplier.id,
                    paymentAmount: minorAmount,
                  );

              if (updated != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supplier payment recorded successfully.'),
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
    final supplierAsync = ref.watch(supplierDetailProvider(widget.supplierId));
    final currentBiz = ref.watch(currentBusinessProvider);
    final currency = currentBiz?.defaultCurrency ?? 'GHS';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return supplierAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error loading supplier: $err')),
      ),
      data: (supplier) {
        final balanceFormatted = (supplier.outstandingBalance / 100)
            .toStringAsFixed(2);

        return Scaffold(
          appBar: AppBar(
            title: Text(supplier.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Profile',
                onPressed: () => _openEditDialog(supplier),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(supplier),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(supplierDetailProvider(widget.supplierId));
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
                              backgroundColor: colorScheme.secondaryContainer,
                              child: Text(
                                supplier.initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplier.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (supplier.contactPerson != null &&
                                      supplier.contactPerson!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Contact: ${supplier.contactPerson}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                  if (supplier.phone != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      supplier.phone!,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  if (supplier.email != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      supplier.email!,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (supplier.address != null &&
                            supplier.address!.isNotEmpty) ...[
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  supplier.address!,
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (supplier.notes != null &&
                            supplier.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.notes_outlined,
                                size: 18,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  supplier.notes!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
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
                  color: supplier.hasBalance
                      ? Colors.orange.shade50
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: supplier.hasBalance
                          ? Colors.orange.shade300
                          : colorScheme.outlineVariant,
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
                                  'Payable Balance Owed',
                                  style: TextStyle(
                                    color: supplier.hasBalance
                                        ? Colors.orange.shade900
                                        : colorScheme.outline,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currency $balanceFormatted',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: supplier.hasBalance
                                        ? Colors.orange.shade900
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 32,
                              color: supplier.hasBalance
                                  ? Colors.orange.shade800
                                  : colorScheme.outline,
                            ),
                          ],
                        ),
                        if (supplier.hasBalance) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.orange.shade900,
                              ),
                              onPressed: () => _openPaymentDialog(supplier),
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('Record Payout / Settlement'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
