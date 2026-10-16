import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sale_entity.dart';
import '../providers/pos_cart_provider.dart';
import '../providers/sales_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../screens/sale_receipt_screen.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../customers/domain/entities/customer_entity.dart';
import '../../../customers/presentation/widgets/customer_form_dialog.dart';
import '../../../../core/utils/user_friendly_error.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  const CheckoutDialog({
    super.key,
    required this.currency,
  });

  final String currency;

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  final _amountTenderedController = TextEditingController();
  final _referenceController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCustomerId;
  String _selectedMomoProvider = 'MTN Mobile Money';
  final List<String> _momoProviders = [
    'MTN Mobile Money',
    'Telecel Cash',
    'AirtelTigo Money',
    'M-Pesa',
  ];

  @override
  void initState() {
    super.initState();
    final cart = ref.read(posCartProvider);
    _selectedCustomerId = cart.customerId;
    _customerNameController.text = cart.customerName ?? '';
    _customerPhoneController.text = cart.customerPhone ?? '';
    _notesController.text = cart.notes ?? '';

    // Pre-fill tendered with total amount in major units
    final totalMajor = (cart.totalAmount / 100).toStringAsFixed(2);
    _amountTenderedController.text = totalMajor;
  }

  @override
  void dispose() {
    _amountTenderedController.dispose();
    _referenceController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _parsedTenderedMinor {
    final text = _amountTenderedController.text.trim();
    final val = double.tryParse(text);
    if (val == null) return 0;
    return (val * 100).round();
  }

  void _addCashDenomination(int amountMajor) {
    final current = double.tryParse(_amountTenderedController.text.trim()) ?? 0.0;
    final next = current + amountMajor;
    setState(() {
      _amountTenderedController.text = next.toStringAsFixed(2);
    });
  }

  void _setExactCash(int totalMinor) {
    setState(() {
      _amountTenderedController.text = (totalMinor / 100).toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posCartProvider);
    final checkoutState = ref.watch(salesCheckoutControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalMinor = cart.totalAmount;
    final tenderedMinor = _selectedMethod == PaymentMethod.cash
        ? _parsedTenderedMinor
        : totalMinor;
    final changeMinor = (tenderedMinor - totalMinor).clamp(0, double.maxFinite.toInt());
    final isCashShort = _selectedMethod == PaymentMethod.cash && tenderedMinor < totalMinor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.point_of_sale, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete Payment',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Due Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.primaryContainer),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'AMOUNT DUE',
                            style: theme.textTheme.labelMedium?.copyWith(
                              letterSpacing: 1.2,
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyFormatter.format(totalMinor, currencyCode: widget.currency),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          if (cart.discountAmount > 0 || cart.taxAmount > 0) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Subtotal: ${CurrencyFormatter.format(cart.subtotal, currencyCode: widget.currency)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (cart.discountAmount > 0)
                                  Text(
                                    '-${CurrencyFormatter.format(cart.discountAmount, currencyCode: widget.currency)} disc',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.green.shade800),
                                  ),
                                if (cart.taxAmount > 0)
                                  Text(
                                    '+${CurrencyFormatter.format(cart.taxAmount, currencyCode: widget.currency)} tax',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Method Tabs
                    Text('Select Payment Method', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<PaymentMethod>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: PaymentMethod.cash,
                          icon: Icon(Icons.money, size: 18),
                          label: Text('Cash'),
                        ),
                        ButtonSegment(
                          value: PaymentMethod.mobileMoney,
                          icon: Icon(Icons.phone_android, size: 18),
                          label: Text('MoMo'),
                        ),
                        ButtonSegment(
                          value: PaymentMethod.card,
                          icon: Icon(Icons.credit_card, size: 18),
                          label: Text('Card/POS'),
                        ),
                        ButtonSegment(
                          value: PaymentMethod.credit,
                          icon: Icon(Icons.receipt_long, size: 18),
                          label: Text('Credit'),
                        ),
                      ],
                      selected: {_selectedMethod},
                      onSelectionChanged: (set) {
                        setState(() => _selectedMethod = set.first);
                      },
                    ),
                    const SizedBox(height: 18),

                    // CASH TENDER SECTION
                    if (_selectedMethod == PaymentMethod.cash) ...[
                      Text('Amount Tendered', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountTenderedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: widget.currency,
                          hintText: '0.00',
                          errorText: isCashShort ? 'Amount tendered is less than total due' : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),

                      // Quick Cash Denomination Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: const Text('Exact'),
                            onPressed: () => _setExactCash(totalMinor),
                          ),
                          ActionChip(
                            label: const Text('+10'),
                            onPressed: () => _addCashDenomination(10),
                          ),
                          ActionChip(
                            label: const Text('+20'),
                            onPressed: () => _addCashDenomination(20),
                          ),
                          ActionChip(
                            label: const Text('+50'),
                            onPressed: () => _addCashDenomination(50),
                          ),
                          ActionChip(
                            label: const Text('+100'),
                            onPressed: () => _addCashDenomination(100),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Change Calculator Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCashShort
                              ? Colors.red.withValues(alpha: 0.08)
                              : Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCashShort ? Colors.red.shade300 : Colors.green.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isCashShort ? 'Balance Remaining:' : 'Change to Customer:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCashShort ? Colors.red.shade900 : Colors.green.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isCashShort
                                    ? CurrencyFormatter.format(totalMinor - tenderedMinor, currencyCode: widget.currency)
                                    : CurrencyFormatter.format(changeMinor, currencyCode: widget.currency),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isCashShort ? Colors.red.shade900 : Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // MOBILE MONEY SECTION
                    if (_selectedMethod == PaymentMethod.mobileMoney) ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedMomoProvider,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Money Provider',
                          prefixIcon: Icon(Icons.network_cell),
                        ),
                        items: _momoProviders
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMomoProvider = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Customer MoMo Number',
                          prefixIcon: Icon(Icons.phone),
                          hintText: 'e.g. 0244123456 / 08012345678',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Transaction ID / Approval Code',
                          prefixIcon: Icon(Icons.tag),
                          hintText: 'e.g. TXN-948271',
                        ),
                      ),
                    ],

                    // CARD / POS SECTION
                    if (_selectedMethod == PaymentMethod.card) ...[
                      TextField(
                        controller: _referenceController,
                        decoration: const InputDecoration(
                          labelText: 'POS Terminal Auth Code / Reference',
                          prefixIcon: Icon(Icons.receipt_long),
                          hintText: 'e.g. AUTH-58291',
                        ),
                      ),
                    ],

                    // STORE CREDIT / DEBT SECTION
                    if (_selectedMethod == PaymentMethod.credit) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This sale will be logged as Customer Debt. A receivable ledger entry will be automatically generated.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountTenderedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Down-payment Tendered (Optional)',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: widget.currency,
                          hintText: '0.00',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Customer Details Section (Optional)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Customer Info (Optional)',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final newCust = await showDialog<CustomerEntity>(
                              context: context,
                              builder: (_) => const CustomerFormDialog(),
                            );
                            if (newCust != null) {
                              setState(() {
                                _selectedCustomerId = newCust.id;
                                _customerNameController.text = newCust.name;
                                _customerPhoneController.text = newCust.phone ?? '';
                              });
                            }
                          },
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('New', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quick Customer Selector Dropdown
                    Consumer(
                      builder: (context, ref, _) {
                        final customersAsync = ref.watch(customersListProvider);
                        final customersList = customersAsync.hasValue ? customersAsync.value! : <CustomerEntity>[];
                        if (customersList.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DropdownButtonFormField<String?>(
                            isExpanded: true,
                            initialValue: _selectedCustomerId,
                            decoration: const InputDecoration(
                              labelText: 'Select Registered Customer',
                              prefixIcon: Icon(Icons.people_outline),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Walk-in / Unregistered Customer', overflow: TextOverflow.ellipsis),
                              ),
                              ...customersList.map(
                                (c) => DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (c.hasDebt) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Text(
                                            'Debt: ${CurrencyFormatter.format(c.outstandingBalance, currencyCode: widget.currency)}',
                                            style: TextStyle(
                                              color: Colors.red.shade800,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (selectedId) {
                              setState(() {
                                _selectedCustomerId = selectedId;
                                if (selectedId != null) {
                                  final match = customersList.where((c) => c.id == selectedId).firstOrNull;
                                  if (match != null) {
                                    _customerNameController.text = match.name;
                                    _customerPhoneController.text = match.phone ?? '';
                                  }
                                } else {
                                  _customerNameController.clear();
                                  _customerPhoneController.clear();
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),

                    TextField(
                      controller: _customerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        prefixIcon: Icon(Icons.person_outline),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedMethod != PaymentMethod.mobileMoney) ...[
                      TextField(
                        controller: _customerPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Phone',
                          prefixIcon: Icon(Icons.phone_outlined),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Sale Notes',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modal Footer / Confirm Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: isCashShort || checkoutState.isLoading
                      ? null
                      : () async {
                          final refStr = _selectedMethod == PaymentMethod.mobileMoney
                              ? '$_selectedMomoProvider: ${_referenceController.text.trim()}'
                              : _referenceController.text.trim();

                          final completedSale = await ref
                              .read(salesCheckoutControllerProvider.notifier)
                              .completeCheckout(
                                paymentMethod: _selectedMethod,
                                amountTendered: tenderedMinor,
                                changeGiven: changeMinor,
                                customerId: _selectedCustomerId,
                                paymentReference: refStr.isNotEmpty ? refStr : null,
                                customerName: _customerNameController.text.trim().isNotEmpty
                                    ? _customerNameController.text.trim()
                                    : null,
                                customerPhone: _customerPhoneController.text.trim().isNotEmpty
                                    ? _customerPhoneController.text.trim()
                                    : null,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              );

                          if (context.mounted) {
                            if (completedSale != null) {
                              Navigator.pop(context); // Close checkout dialog
                              // Open Digital Receipt Screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SaleReceiptScreen(
                                    sale: completedSale,
                                    currency: widget.currency,
                                  ),
                                ),
                              );
                            } else {
                              final rawError = ref.read(salesCheckoutControllerProvider).error;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    UserFriendlyError.toFriendly(
                                      rawError,
                                      defaultMessage: 'Unable to complete sale. Please check details and try again.',
                                    ),
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                  icon: checkoutState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Flexible(
                    child: Text(
                      checkoutState.isLoading
                          ? 'Processing Sale...'
                          : 'Complete Sale (${CurrencyFormatter.format(totalMinor, currencyCode: widget.currency)})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
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
