import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/business_provider.dart';
import '../../domain/entities/business_entity.dart';

void showBusinessSwitcherModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const BusinessSwitcherSheet(),
  );
}

class BusinessSwitcherSheet extends ConsumerStatefulWidget {
  const BusinessSwitcherSheet({super.key});

  @override
  ConsumerState<BusinessSwitcherSheet> createState() => _BusinessSwitcherSheetState();
}

class _BusinessSwitcherSheetState extends ConsumerState<BusinessSwitcherSheet> {
  String? _deletingBusinessId;

  Future<void> _confirmDelete(BuildContext context, BusinessEntity business) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Business'),
        content: Text(
          'Are you sure you want to permanently delete "${business.name}"? '
          'This will remove this business and its branches. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _deletingBusinessId = business.id);
      final success = await ref
          .read(businessControllerProvider.notifier)
          .deleteBusiness(business.id);

      if (mounted) {
        setState(() => _deletingBusinessId = null);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${business.name}" deleted successfully.')),
          );
        } else {
          final errorMsg = ref.read(businessControllerProvider).error?.toString() ??
              'Failed to delete business. Check network or admin privileges.';
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

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(userBusinessesProvider);
    final currentBiz = ref.watch(currentBusinessProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Switch Business Workspace',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose which business you want to view and manage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Businesses List
            businessesAsync.when(
              data: (businesses) {
                if (businesses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No businesses found on this account.'),
                    ),
                  );
                }

                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: businesses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final biz = businesses[index];
                      final isSelected = currentBiz?.id == biz.id;
                      final isOwner = currentUserId != null && biz.ownerId == currentUserId;
                      final isDeleting = _deletingBusinessId == biz.id;

                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        color: isSelected
                            ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                            : colorScheme.surface,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: isDeleting
                              ? null
                              : () {
                                  ref.read(currentBusinessProvider.notifier).select(biz);
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Switched to "${biz.name}"'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                // Business Icon Avatar
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Business Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              biz.name,
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? colorScheme.primary : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  color: colorScheme.onPrimary,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Currency: ${biz.defaultCurrency}${biz.taxNumber != null ? ' • Tax: ${biz.taxNumber}' : ''}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.outline,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions: Delete (if owner and not sole business or if accidental)
                                if (isDeleting)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else if (isOwner && businesses.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    tooltip: 'Delete Business',
                                    onPressed: () => _confirmDelete(context, biz),
                                  )
                                else if (isSelected)
                                  Icon(Icons.check_circle, color: colorScheme.primary, size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Error loading businesses: $err', style: TextStyle(color: colorScheme.error)),
              ),
            ),
            const SizedBox(height: 20),

            // Add Business Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Add Another Business'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/business-setup');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
