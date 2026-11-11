import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../sync/presentation/providers/sync_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final theme = Theme.of(context);

    if (syncState.isOnline && !syncState.isSyncing) {
      return const SizedBox.shrink();
    }

    if (!syncState.isOnline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.amber.shade800,
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                syncState.pendingCount > 0
                    ? 'Offline Mode — ${syncState.pendingCount} changes queued to sync'
                    : 'Offline Mode — Working from local storage',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/sync-center'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (syncState.isSyncing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: theme.colorScheme.primaryContainer,
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                syncState.statusMessage,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    if (syncState.isSyncing) {
      return IconButton(
        tooltip: 'Syncing changes...',
        icon: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        onPressed: () => context.push('/sync-center'),
      );
    }

    if (!syncState.isOnline) {
      return Badge(
        isLabelVisible: syncState.pendingCount > 0,
        label: Text('${syncState.pendingCount}'),
        backgroundColor: Colors.amber.shade900,
        child: IconButton(
          tooltip: 'Offline - Changes Queued',
          icon: const Icon(Icons.cloud_off_outlined, color: Colors.orange),
          onPressed: () => context.push('/sync-center'),
        ),
      );
    }

    if (syncState.pendingCount > 0) {
      return Badge(
        label: Text('${syncState.pendingCount}'),
        backgroundColor: Colors.blue,
        child: IconButton(
          tooltip: 'Pending Sync Items',
          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
          onPressed: () => context.push('/sync-center'),
        ),
      );
    }

    return IconButton(
      tooltip: 'All changes synced',
      icon: const Icon(Icons.cloud_done_outlined, color: Colors.green),
      onPressed: () => context.push('/sync-center'),
    );
  }
}
