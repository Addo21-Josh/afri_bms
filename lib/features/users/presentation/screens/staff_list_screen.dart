import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/staff_user_entity.dart';
import '../providers/staff_provider.dart';
import '../widgets/assign_role_dialog.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/subscription/domain/models/subscription_tier.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  void _onAddStaff(BuildContext context, WidgetRef ref, int currentCount) {
    final gate = ref.read(featureGateProvider);
    final check = gate.checkStaffLimit(currentCount);
    if (check.isBlocked) {
      UpgradePromptSheet.show(
        context,
        featureName: check.featureName ?? 'Staff Accounts',
        customMessage: check.reason,
        currentTier: gate.tier,
        suggestedTier: check.requiredTier,
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => const AssignRoleDialog(),
    );
  }

  Color _getRoleColor(UserRoleType role, ColorScheme colors) {
    switch (role) {
      case UserRoleType.admin:
        return colors.primary;
      case UserRoleType.branchManager:
        return colors.secondary;
      case UserRoleType.salesperson:
        return colors.tertiary;
      case UserRoleType.cashier:
        return Colors.teal;
      default:
        return colors.outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffListAsync = ref.watch(businessStaffListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: 'Staff & Team',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final count = staffListAsync.value?.length ?? 0;
          _onAddStaff(context, ref, count);
        },
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Staff'),
      ),
      body: staffListAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return EmptyStateWidget(
              title: 'No staff members yet',
              subtitle: 'Add staff accounts to collaborate in managing sales and inventory across your branches.',
              icon: Icons.people_outline,
              action: FilledButton.icon(
                onPressed: () => _onAddStaff(context, ref, 0),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add First Staff Member'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(businessStaffListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: staffList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final staff = staffList[index];
                final roleColor = _getRoleColor(staff.role, colorScheme);

                return Card(
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
                              radius: 22,
                              backgroundColor: roleColor.withValues(alpha: 0.15),
                              child: Text(
                                staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    staff.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                staff.role.displayName,
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.store_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      staff.branchName ?? 'All Branches',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: 'Edit Role',
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AssignRoleDialog(existingStaff: staff),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                              tooltip: 'Remove',
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Remove Staff Member?'),
                                    content: Text('Are you sure you want to remove ${staff.fullName} from this business?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await ref.read(staffControllerProvider.notifier).removeStaff(staff.roleId);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.refresh(businessStaffListProvider),
        ),
      ),
    );
  }
}
