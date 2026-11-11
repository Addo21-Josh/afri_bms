import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expenses_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import 'expense_category_dialog.dart';
import '../../../../core/utils/user_friendly_error.dart';

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({super.key, this.expense});

  final ExpenseEntity? expense;

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _referenceController;
  late final TextEditingController _notesController;

  String? _selectedCategoryId;
  String _paymentMethod = 'cash';
  DateTime _expenseDate = DateTime.now();
  String? _receiptUrl;
  File? _localReceiptImage;
  bool _isUploadingImage = false;

  final List<String> _paymentMethods = [
    'cash',
    'mobile_money',
    'bank_transfer',
    'card',
    'cheque',
  ];

  @override
  void initState() {
    super.initState();
    final exp = widget.expense;
    _amountController = TextEditingController(
      text: exp != null ? (exp.amount / 100).toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(
      text: exp?.description ?? '',
    );
    _referenceController = TextEditingController(
      text: exp?.paymentReference ?? '',
    );
    _notesController = TextEditingController(text: exp?.notes ?? '');
    _selectedCategoryId = exp?.categoryId;
    _paymentMethod = exp?.paymentMethod ?? 'cash';
    _expenseDate = exp?.expenseDate ?? DateTime.now();
    _receiptUrl = exp?.receiptUrl;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
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
        return method;
    }
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 70);
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _localReceiptImage = file;
        _isUploadingImage = true;
      });

      // Attempt upload to Supabase storage receipts bucket
      final client = Supabase.instance.client;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final path = 'expenses/$fileName';

      try {
        await client.storage.from('receipts').upload(path, file);
        final publicUrl = client.storage.from('receipts').getPublicUrl(path);
        setState(() {
          _receiptUrl = publicUrl;
          _isUploadingImage = false;
        });
      } catch (_) {
        // Fallback to storing file path if bucket is offline or not created
        setState(() {
          _receiptUrl = picked.path;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyError.toFriendly(
                e,
                defaultMessage:
                    'Unable to attach receipt. Please try another image.',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid expense amount')),
      );
      return;
    }

    final amountMinor = (parsedAmount * 100).round();
    final notifier = ref.read(expenseControllerProvider.notifier);

    bool success;
    if (widget.expense == null) {
      success = await notifier.createExpense(
        categoryId: _selectedCategoryId,
        amount: amountMinor,
        description: _descriptionController.text.trim(),
        paymentMethod: _paymentMethod,
        paymentReference: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
        expenseDate: _expenseDate,
        receiptUrl: _receiptUrl,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    } else {
      final updated = ExpenseEntity(
        id: widget.expense!.id,
        businessId: widget.expense!.businessId,
        branchId: widget.expense!.branchId,
        categoryId: _selectedCategoryId,
        amount: amountMinor,
        description: _descriptionController.text.trim(),
        paymentMethod: _paymentMethod,
        paymentReference: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : null,
        expenseDate: _expenseDate,
        receiptUrl: _receiptUrl,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: widget.expense!.createdAt,
        updatedAt: DateTime.now(),
      );
      success = await notifier.updateExpense(updated);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        final err = ref.read(expenseControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyError.toFriendly(
                err,
                defaultMessage: 'Unable to save expense. Please try again.',
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
    final categories = ref.watch(expenseCategoriesProvider).value ?? [];
    final controllerState = ref.watch(expenseControllerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.expense == null ? Icons.add_card : Icons.edit_note,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.expense == null
                          ? 'Record Business Expense'
                          : 'Edit Expense',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Expense Amount *',
                          prefixText: '$currency ',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          hintText: '0.00',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter the expense amount';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a positive amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description / Purpose *',
                          hintText:
                              'e.g. Monthly shop rent, Fuel for generator, Store bags',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Category Row + Add Category Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              isExpanded: true,
                              initialValue: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Uncategorized'),
                                ),
                                ...categories.map(
                                  (cat) => DropdownMenuItem<String?>(
                                    value: cat.id,
                                    child: Text(
                                      cat.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedCategoryId = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Add new category',
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              final created = await showDialog<bool>(
                                context: context,
                                builder: (_) => const ExpenseCategoryDialog(),
                              );
                              if (created == true) {
                                await ref
                                    .read(expenseCategoriesProvider.notifier)
                                    .refresh();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Date & Payment Method Row
                      Row(
                        children: [
                          // Expense Date Picker
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _expenseDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                );
                                if (picked != null) {
                                  setState(() => _expenseDate = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Expense Date',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 20,
                                  ),
                                ),
                                child: Text(
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(_expenseDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Payment Method Dropdown
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Paid Via',
                                prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 20,
                                ),
                              ),
                              items: _paymentMethods.map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    _formatPaymentMethod(m),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _paymentMethod = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Payment Reference / Check / MoMo Ref
                      TextFormField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText:
                              'Payment Reference / Transaction ID (Optional)',
                          hintText:
                              'e.g. MoMo Transaction ID, Check #, Receipt #',
                          prefixIcon: Icon(Icons.receipt_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Receipt Photo Attachment
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.attach_file, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Receipt Photo / Document',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_receiptUrl != null ||
                                    _localReceiptImage != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _receiptUrl = null;
                                        _localReceiptImage = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isUploadingImage)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_localReceiptImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _localReceiptImage!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (_receiptUrl != null &&
                                _receiptUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _receiptUrl!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Text('Attachment saved'),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickReceipt(ImageSource.camera),
                                    icon: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Camera'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickReceipt(ImageSource.gallery),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Gallery'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes (Optional)',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: controllerState.isLoading ? null : _submit,
                  child: controllerState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.expense == null
                              ? 'Save Expense'
                              : 'Update Expense',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
