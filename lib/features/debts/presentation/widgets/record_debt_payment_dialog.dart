import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/debt_entity.dart';
import '../providers/debts_provider.dart';
import '../../../../core/utils/currency_formatter.dart';

class RecordDebtPaymentDialog extends ConsumerStatefulWidget {
  const RecordDebtPaymentDialog({
    super.key,
    required this.debt,
    required this.currency,
  });

  final DebtEntity debt;
  final String currency;

  @override
  ConsumerState<RecordDebtPaymentDialog> createState() => _RecordDebtPaymentDialogState();
}

class _RecordDebtPaymentDialogState extends ConsumerState<RecordDebtPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'cash';
  bool _isLoading = false;

  final List<String> _methods = [
    'cash',
    'mobile_money',
    'bank_transfer',
    'card',
    'cheque',
  ];

  @override
  void initState() {
    super.initState();
    // Default to paying the entire remaining balance
    _amountController = TextEditingController(
      text: (widget.debt.remainingBalance / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatMethod(String m) {
    switch (m) {
      case 'cash':
        return 'Cash';
      case 'mobile_money':
        return 'Mobile Money';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'card':
        return 'Card / POS';
      case 'cheque':
        return 'Cheque';
      default:
        return m;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount')),
      );
      return;
    }

    final amountMinor = (parsedAmount * 100).round();
    if (amountMinor > widget.debt.remainingBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount cannot exceed the remaining balance')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref.read(debtControllerProvider.notifier).recordPayment(
      debtId: widget.debt.id,
      amount: amountMinor,
      paymentMethod: _paymentMethod,
      paymentReference: _referenceController.text.trim().isNotEmpty
          ? _referenceController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        final err = ref.read(debtControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Failed to record repayment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final remainingFormatted = CurrencyFormatter.format(widget.debt.remainingBalance, currencyCode: widget.currency);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Record Repayment',
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
              Text(
                'Person: ${widget.debt.personName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Remaining Balance: $remainingFormatted',
                style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Payment Amount *',
                  prefixText: '${widget.currency} ',
                  prefixIcon: const Icon(Icons.money),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: _methods.map((m) {
                  return DropdownMenuItem(value: m, child: Text(_formatMethod(m)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Reference (Optional)',
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'e.g. MoMo ID, Receipt #',
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
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
              : const Text('Confirm Payment'),
        ),
      ],
    );
  }
}
