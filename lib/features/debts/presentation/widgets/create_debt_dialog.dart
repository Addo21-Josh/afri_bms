import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/debt_entity.dart';
import '../providers/debts_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../suppliers/presentation/providers/suppliers_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/user_friendly_error.dart';

class CreateDebtDialog extends ConsumerStatefulWidget {
  const CreateDebtDialog({super.key, this.initialType = DebtType.receivable});

  final DebtType initialType;

  @override
  ConsumerState<CreateDebtDialog> createState() => _CreateDebtDialogState();
}

class _CreateDebtDialogState extends ConsumerState<CreateDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  late DebtType _debtType;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCustomerId;
  String? _selectedSupplierId;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _debtType = widget.initialType;
    // Default due date: 30 days from now
    _dueDate = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid debt amount')),
      );
      return;
    }

    final amountMinor = (parsedAmount * 100).round();
    setState(() => _isLoading = true);

    final success = await ref.read(debtControllerProvider.notifier).createDebt(
      debtType: _debtType,
      customerId: _debtType == DebtType.receivable ? _selectedCustomerId : null,
      supplierId: _debtType == DebtType.payable ? _selectedSupplierId : null,
      personName: _nameController.text.trim(),
      personPhone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      amount: amountMinor,
      dueDate: _dueDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        final err = ref.read(debtControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyError.toFriendly(
                err,
                defaultMessage: 'Unable to record debt. Please check the details and try again.',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);
    final currency = business?.defaultCurrency ?? 'GHS';
    final customers = ref.watch(customersListProvider).value ?? [];
    final suppliers = ref.watch(suppliersListProvider).value ?? [];

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment_late_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Add Debt / Credit Entry',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Button: Receivable vs Payable
              SegmentedButton<DebtType>(
                segments: const [
                  ButtonSegment(
                    value: DebtType.receivable,
                    icon: Icon(Icons.call_received, size: 16),
                    label: Text('Receivable (Customer)'),
                  ),
                  ButtonSegment(
                    value: DebtType.payable,
                    icon: Icon(Icons.call_made, size: 16),
                    label: Text('Payable (Supplier)'),
                  ),
                ],
                selected: {_debtType},
                onSelectionChanged: (set) {
                  setState(() {
                    _debtType = set.first;
                    _nameController.clear();
                    _phoneController.clear();
                    _selectedCustomerId = null;
                    _selectedSupplierId = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Registered Contact Picker
              if (_debtType == DebtType.receivable && customers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Select Customer (Optional)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Manual / Unregistered Customer'),
                      ),
                      ...customers.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (id) {
                      setState(() {
                        _selectedCustomerId = id;
                        if (id != null) {
                          final match = customers.where((c) => c.id == id).firstOrNull;
                          if (match != null) {
                            _nameController.text = match.name;
                            _phoneController.text = match.phone ?? '';
                          }
                        }
                      });
                    },
                  ),
                ),

              if (_debtType == DebtType.payable && suppliers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: _selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Select Supplier (Optional)',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Manual / Unregistered Supplier'),
                      ),
                      ...suppliers.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (id) {
                      setState(() {
                        _selectedSupplierId = id;
                        if (id != null) {
                          final match = suppliers.where((s) => s.id == id).firstOrNull;
                          if (match != null) {
                            _nameController.text = match.name;
                            _phoneController.text = match.phone ?? '';
                          }
                        }
                      });
                    },
                  ),
                ),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _debtType == DebtType.receivable ? 'Customer Name *' : 'Supplier / Vendor Name *',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Debt Amount *',
                  prefixText: '$currency ',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Amount is required';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Due Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Due Date (Optional)',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _dueDate != null ? DateFormat('MMM d, yyyy').format(_dueDate!) : 'Not set',
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Reason for credit (Optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Entry'),
        ),
      ],
    );
  }
}
