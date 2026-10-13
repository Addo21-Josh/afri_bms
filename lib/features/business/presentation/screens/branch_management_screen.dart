import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afri_bms/core/utils/validators.dart';
import 'package:afri_bms/core/widgets/shared_widgets.dart';
import '../providers/business_provider.dart';
import '../../domain/entities/branch_entity.dart';
import '../../../../core/subscription/domain/models/subscription_tier.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';

class BranchManagementScreen extends ConsumerWidget {
  const BranchManagementScreen({super.key});

  void _showBranchDialog(BuildContext context, WidgetRef ref, [BranchEntity? branch]) {
    final isEditing = branch != null;
    if (!isEditing) {
      final currentCount = ref.read(businessBranchesProvider).value?.length ?? 0;
      final gate = ref.read(featureGateProvider);
      final check = gate.checkBranchLimit(currentCount);
      if (check.isBlocked) {
        UpgradePromptSheet.show(
          context,
          featureName: check.featureName ?? 'Branch Locations',
          customMessage: check.reason,
          currentTier: gate.tier,
          suggestedTier: check.requiredTier,
        );
        return;
      }
    }

    final nameController = TextEditingController(text: branch?.name ?? '');
    final addressController = TextEditingController(text: branch?.address ?? '');
    final phoneController = TextEditingController(text: branch?.phone ?? '');
    final currencyController = TextEditingController(
      text: branch?.currency ?? ref.read(currentBusinessProvider)?.defaultCurrency ?? 'GHS',
    );
    bool isMain = branch?.isMain ?? false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Branch' : 'Add New Branch'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Branch Name'),
                      validator: (val) => Validators.required(val, 'Branch name is required'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currencyController,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      validator: (val) => Validators.required(val, 'Currency is required'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone (optional)'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address (optional)'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Main Branch'),
                      value: isMain,
                      onChanged: (val) => setState(() => isMain = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  final currentBiz = ref.read(currentBusinessProvider);
                  if (currentBiz == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No active business found')),
                    );
                    return;
                  }

                  if (isEditing) {
                    final updated = branch.copyWith(
                      name: nameController.text.trim(),
                      currency: currencyController.text.trim().toUpperCase(),
                      address: addressController.text.trim(),
                      phone: phoneController.text.trim(),
                      isMain: isMain,
                    );
                    ref.read(branchControllerProvider.notifier).updateBranch(updated);
                  } else {
                    ref.read(branchControllerProvider.notifier).createBranch(
                      businessId: currentBiz.id,
                      name: nameController.text.trim(),
                      currency: currencyController.text.trim().toUpperCase(),
                      address: addressController.text.trim(),
                      phone: phoneController.text.trim(),
                      isMain: isMain,
                    );
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? 'Branch updated' : 'Branch created successfully')),
                  );
                },
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(businessBranchesProvider);
    final currentBranch = ref.watch(currentBranchProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Branches'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBranchDialog(context, ref),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Branch'),
      ),
      body: branchesAsync.when(
        data: (branches) {
          if (branches.isEmpty) {
            return EmptyStateWidget(
              title: 'No Branches Found',
              subtitle: 'Add your first branch to start organizing your inventory and sales.',
              icon: Icons.store_mall_directory_outlined,
              action: FilledButton.icon(
                onPressed: () => _showBranchDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create Branch'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: branches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final branch = branches[index];
              final isSelected = currentBranch?.id == branch.id;

              return Card(
                elevation: isSelected ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: branch.isMain
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: branch.isMain
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    child: Icon(
                      branch.isMain ? Icons.store_rounded : Icons.location_city_outlined,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          branch.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (branch.isMain)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Main Branch',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (branch.address != null && branch.address!.isNotEmpty)
                        Text(
                          branch.address!,
                          style: theme.textTheme.bodySmall,
                        ),
                      Text(
                        'Currency: ${branch.currency}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Branch',
                        onPressed: () => _showBranchDialog(context, ref, branch),
                      ),
                      if (!isSelected)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          tooltip: 'Switch to this branch',
                          onPressed: () {
                            ref.read(currentBranchProvider.notifier).select(branch);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Switched to ${branch.name}')),
                            );
                          },
                        ),
                    ],
                  ),
                  onTap: () {
                    ref.read(currentBranchProvider.notifier).select(branch);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(businessBranchesProvider),
        ),
      ),
    );
  }
}
