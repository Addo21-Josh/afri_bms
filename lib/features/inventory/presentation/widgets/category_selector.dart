import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';

class CategorySelectorBar extends ConsumerWidget {
  const CategorySelectorBar({super.key});

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Beverages, Electronics',
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
              if (nameCtrl.text.trim().isNotEmpty) {
                final createdCat = await ref
                    .read(inventoryControllerProvider.notifier)
                    .createCategory(nameCtrl.text.trim(), description: descCtrl.text.trim());
                if (ctx.mounted && createdCat != null) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCat = ref.watch(selectedCategoryFilterProvider);

    return SizedBox(
      height: 48,
      child: categoriesAsync.when(
        data: (categories) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              FilterChip(
                selected: selectedCat == null,
                label: const Text('All Products'),
                onSelected: (_) {
                  ref.read(selectedCategoryFilterProvider.notifier).state = null;
                },
              ),
              const SizedBox(width: 8),
              ...categories.map((cat) {
                final isSelected = selectedCat == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat.name),
                    onSelected: (val) {
                      ref.read(selectedCategoryFilterProvider.notifier).state = val ? cat.id : null;
                    },
                  ),
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Add Category'),
                onPressed: () => _showAddCategoryDialog(context, ref),
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
