import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/business_provider.dart';
import '../../domain/entities/branch_entity.dart';

class BranchSelector extends ConsumerWidget {
  const BranchSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(businessBranchesProvider);
    final currentBranch = ref.watch(currentBranchProvider);
    final theme = Theme.of(context);

    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BranchEntity>(
              value: currentBranch ?? branches.first,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              isDense: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              items: branches.map((branch) {
                return DropdownMenuItem<BranchEntity>(
                  value: branch,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        branch.isMain ? Icons.store_rounded : Icons.location_on_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(branch.name),
                      if (branch.isMain) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(Main)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: (selected) {
                if (selected != null) {
                  ref.read(currentBranchProvider.notifier).select(selected);
                }
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
