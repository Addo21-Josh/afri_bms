import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/variant_entity.dart';
import '../providers/inventory_provider.dart';
import 'barcode_scanner_screen.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';
import '../../../users/domain/entities/staff_user_entity.dart';
import '../../../users/presentation/providers/staff_provider.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../domain/constants/product_unit.dart';
import '../widgets/unit_picker_sheet.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.existingProduct});

  final ProductEntity? existingProduct;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _reorderLevelController;
  late final TextEditingController _initialStockController;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String _unit = 'pcs';
  final List<ProductVariantEntity> _variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _costPriceController = TextEditingController(
      text: p != null ? (p.costPrice / 100).toStringAsFixed(2) : '',
    );
    _sellingPriceController = TextEditingController(
      text: p != null ? (p.sellingPrice / 100).toStringAsFixed(2) : '',
    );
    _reorderLevelController = TextEditingController(
      text: p != null ? p.reorderLevel.toString() : '10',
    );
    _initialStockController = TextEditingController(
      text: p != null ? p.currentBranchStock.toString() : '0',
    );

    _selectedCategoryId = p?.categoryId;
    _selectedCategoryName = p?.category?.name;
    _unit = p?.unit ?? 'pcs';
    if (p != null) {
      _variants.addAll(p.variants);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _reorderLevelController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  void _addVariantDialog() {
    final vNameCtrl = TextEditingController();
    final vCostCtrl = TextEditingController(text: _costPriceController.text);
    final vSellCtrl = TextEditingController(text: _sellingPriceController.text);
    final vSkuCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product Variant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: vNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Variant Name (e.g. Large / Red)',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vSkuCtrl,
              decoration: const InputDecoration(
                labelText: 'Variant SKU (Optional)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: vCostCtrl,
                    decoration: const InputDecoration(labelText: 'Cost Price'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: vSellCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (vNameCtrl.text.trim().isNotEmpty) {
                final cost =
                    ((double.tryParse(vCostCtrl.text.trim()) ?? 0) * 100)
                        .round();
                final sell =
                    ((double.tryParse(vSellCtrl.text.trim()) ?? 0) * 100)
                        .round();
                setState(() {
                  _variants.add(
                    ProductVariantEntity(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      productId: widget.existingProduct?.id ?? '',
                      name: vNameCtrl.text.trim(),
                      sku: vSkuCtrl.text.trim().isNotEmpty
                          ? vSkuCtrl.text.trim()
                          : null,
                      costPrice: cost,
                      sellingPrice: sell,
                      createdAt: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Variant'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name *',
                hintText: 'e.g. Beverages, Provisions, Shoes',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final catName = nameCtrl.text.trim();
              if (catName.isNotEmpty) {
                final newCat = await ref
                    .read(inventoryControllerProvider.notifier)
                    .createCategory(catName, description: descCtrl.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted && newCat != null) {
                  setState(() {
                    _selectedCategoryId = newCat.id;
                    _selectedCategoryName = newCat.name;
                  });
                  ref.invalidate(productCategoriesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Category "$catName" created and selected!',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _scanBarcode() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() {
        _barcodeController.text = scanned;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned barcode: $scanned'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final currentBiz = ref.read(currentBusinessProvider);
      final currency = currentBiz?.defaultCurrency ?? 'GHS';

      final cost =
          ((double.tryParse(_costPriceController.text.trim()) ?? 0) * 100)
              .round();
      final sell =
          ((double.tryParse(_sellingPriceController.text.trim()) ?? 0) * 100)
              .round();
      final reorder = int.tryParse(_reorderLevelController.text.trim()) ?? 10;
      final initialStock =
          int.tryParse(_initialStockController.text.trim()) ?? 0;

      if (widget.existingProduct == null) {
        final currentCount = ref.read(productsListProvider).value?.length ?? 0;
        final gate = ref.read(featureGateProvider);
        final check = gate.checkProductLimit(currentCount);
        if (check.isBlocked) {
          UpgradePromptSheet.show(
            context,
            featureName: check.featureName ?? 'Product Catalog',
            customMessage: check.reason,
            currentTier: gate.tier,
            suggestedTier: check.requiredTier,
          );
          return;
        }

        final newProduct = await ref
            .read(inventoryControllerProvider.notifier)
            .createProduct(
              categoryId: _selectedCategoryId,
              name: _nameController.text.trim(),
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : null,
              sku: _skuController.text.trim().isNotEmpty
                  ? _skuController.text.trim()
                  : null,
              barcode: _barcodeController.text.trim().isNotEmpty
                  ? _barcodeController.text.trim()
                  : null,
              costPrice: cost,
              sellingPrice: sell,
              currency: currency,
              unit: _unit,
              reorderLevel: reorder,
              initialStock: initialStock,
              variants: _variants,
            );

        if (mounted) {
          if (newProduct != null) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product created successfully!')),
            );
          } else {
            final rawError = ref.read(inventoryControllerProvider).error;
            final errorMsg = UserFriendlyError.toFriendly(
              rawError ?? 'Unable to create product. Please try again.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } else {
        final updated = ProductEntity(
          id: widget.existingProduct!.id,
          businessId: widget.existingProduct!.businessId,
          categoryId: _selectedCategoryId,
          name: _nameController.text.trim(),
          description: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          sku: _skuController.text.trim().isNotEmpty
              ? _skuController.text.trim()
              : null,
          barcode: _barcodeController.text.trim().isNotEmpty
              ? _barcodeController.text.trim()
              : null,
          costPrice: cost,
          sellingPrice: sell,
          currency: currency,
          unit: _unit,
          reorderLevel: reorder,
          variants: _variants,
          createdAt: widget.existingProduct!.createdAt,
          updatedAt: DateTime.now(),
        );

        final success = await ref
            .read(inventoryControllerProvider.notifier)
            .updateProduct(updated);
        if (mounted) {
          if (success) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product updated successfully!')),
            );
          } else {
            final rawError = ref.read(inventoryControllerProvider).error;
            final errorMsg = UserFriendlyError.toFriendly(
              rawError ?? 'Unable to update product. Please try again.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final invState = ref.watch(inventoryControllerProvider);
    final userRole = ref.watch(currentUserRoleProvider).value;
    final canManageProducts =
        userRole == UserRoleType.admin ||
        userRole == UserRoleType.branchManager;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!canManageProducts) {
      return AppScaffold(
        title: 'Access Restricted',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Permission Denied',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only Business Administrators and Branch Managers are authorized to add or edit products.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: widget.existingProduct == null ? 'Add Product' : 'Edit Product',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (invState.hasError) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          UserFriendlyError.toFriendly(invState.error),
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                      if (UserFriendlyError.isLimitOrUpgradeError(
                        invState.error,
                      )) ...[
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => UpgradePromptSheet.show(
                            context,
                            featureName: 'Product Limit',
                            customMessage: UserFriendlyError.toFriendly(
                              invState.error,
                            ),
                          ),
                          child: const Text('Upgrade'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Product Basic Information
              Text(
                'General Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Golden Penny Spaghetti 500g',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (val) =>
                    Validators.required(val, 'Product name is required'),
              ),
              const SizedBox(height: 16),

              // Category & Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Builder(
                      builder: (context) {
                        final cats = categoriesAsync.value ?? [];
                        final hasSelected =
                            _selectedCategoryId == null ||
                            cats.any((c) => c.id == _selectedCategoryId);

                        return DropdownButtonFormField<String?>(
                          initialValue: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.category_outlined),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Add New Category',
                              onPressed: _showAddCategoryDialog,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Uncategorized'),
                            ),
                            ...cats.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                            if (!hasSelected && _selectedCategoryId != null)
                              DropdownMenuItem<String?>(
                                value: _selectedCategoryId,
                                child: Text(
                                  _selectedCategoryName ?? 'Selected Category',
                                ),
                              ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedCategoryId = val;
                              _selectedCategoryName = cats
                                  .where((c) => c.id == val)
                                  .firstOrNull
                                  ?.name;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () {
                        ProductUnitPickerSheet.show(
                          context,
                          currentUnit: _unit,
                          onSelected: (val) => setState(() => _unit = val),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          ProductUnits.formatShort(_unit),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Pricing Section
              Text(
                'Pricing',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price *',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.price_check_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) => Validators.nonNegativeNumber(
                        val,
                        fieldName: 'Cost price',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price *',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) => Validators.nonNegativeNumber(
                        val,
                        fieldName: 'Selling price',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stock & Inventory Tracking
              Text(
                'Stock & Codes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.existingProduct == null) ...[
                    Expanded(
                      child: TextFormField(
                        controller: _initialStockController,
                        decoration: InputDecoration(
                          labelText: 'Initial Stock Quantity',
                          prefixIcon: const Icon(Icons.warehouse_outlined),
                          suffixText: _unit,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) => Validators.nonNegativeInteger(
                          val,
                          fieldName: 'Initial stock',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: TextFormField(
                      controller: _reorderLevelController,
                      decoration: InputDecoration(
                        labelText: 'Low Stock Alert Level',
                        prefixIcon: const Icon(
                          Icons.notification_important_outlined,
                        ),
                        suffixText: _unit,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => Validators.nonNegativeInteger(
                        val,
                        fieldName: 'Reorder level',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU (Stock Keeping Unit)',
                        hintText: 'e.g. BEV-001',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        hintText: 'Scan or type',
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Scan Barcode with Camera',
                          onPressed: _scanBarcode,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Product Variants Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Variants (${_variants.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addVariantDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Variant'),
                  ),
                ],
              ),
              if (_variants.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: BorderStyle.none == BorderStyle.solid
                        ? null
                        : Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    'No variants added yet (e.g., Size, Color, Flavors). Tap "Add Variant" to configure variants.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._variants.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final v = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        v.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Sell: ${(v.sellingPrice / 100).toStringAsFixed(2)} | Cost: ${(v.costPrice / 100).toStringAsFixed(2)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _variants.removeAt(idx)),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: invState.isLoading ? null : _submit,
                  child: invState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.existingProduct == null
                              ? 'Save Product'
                              : 'Update Product',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
