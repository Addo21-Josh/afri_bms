import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/sync_provider.dart';
import '../../domain/models/sync_queue_item.dart';
import '../../../utils/user_friendly_error.dart';

class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syncState = ref.watch(syncProvider);
    final syncNotifier = ref.read(syncProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync & Offline Center'),
        actions: [
          IconButton(
            tooltip: 'Refresh Queue',
            icon: const Icon(Icons.refresh),
            onPressed: () => syncNotifier.refreshQueue(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'retry') {
                syncNotifier.retryFailed();
              } else if (value == 'clear') {
                syncNotifier.clearCompleted();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'retry',
                child: Text('Retry All Failed'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Completed History'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => syncNotifier.triggerSync(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: syncState.isOnline
                      ? colorScheme.outlineVariant
                      : Colors.orange.shade300,
                ),
              ),
              color: syncState.isOnline
                  ? colorScheme.surface
                  : Colors.amber.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: syncState.isOnline
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.orange.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            syncState.isOnline
                                ? Icons.cloud_done
                                : Icons.cloud_off,
                            color: syncState.isOnline
                                ? Colors.green
                                : Colors.orange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                syncState.isOnline
                                    ? 'Online Connection'
                                    : 'Offline Mode Active',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                syncState.isOnline
                                    ? 'Connected to Afri_BMS cloud infrastructure.'
                                    : 'All operations are queued locally and safely preserved.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(
                          context,
                          label: 'Pending Queue',
                          value: '${syncState.pendingCount} items',
                          color: syncState.pendingCount > 0
                              ? Colors.orange
                              : Colors.green,
                        ),
                        _buildStat(
                          context,
                          label: 'Last Synchronized',
                          value: syncState.lastSyncTime != null
                              ? DateFormat(
                                  'HH:mm:ss, d MMM',
                                ).format(syncState.lastSyncTime!)
                              : 'Not yet synced',
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    if (syncState.isSyncing) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: syncState.progress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        syncState.statusMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Button
            FilledButton.icon(
              onPressed: syncState.isSyncing
                  ? null
                  : () async {
                      final isOnline = await syncNotifier
                          .checkLiveConnectivity();
                      if (!isOnline && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cannot sync: No internet connection detected.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      await syncNotifier.triggerSync();
                    },
              icon: syncState.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                syncState.isSyncing ? 'Syncing...' : 'Sync All Changes Now',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Queue Items Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local Queue Items (${syncState.queueItems.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (syncState.queueItems.isNotEmpty)
                  TextButton(
                    onPressed: () => syncNotifier.clearCompleted(),
                    child: const Text(
                      'Clear Completed',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Queue Items List
            if (syncState.queueItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sync Queue is Empty',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All operations are fully synced with the cloud.',
                        style: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...syncState.queueItems.reversed.map((item) {
                return _buildQueueItemCard(context, item);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItemCard(BuildContext context, SyncQueueItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.hourglass_empty;
    String statusLabel = 'Pending';

    switch (item.status) {
      case SyncItemStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusLabel = 'Pending';
        break;
      case SyncItemStatus.processing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        statusLabel = 'Syncing';
        break;
      case SyncItemStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusLabel = 'Failed';
        break;
      case SyncItemStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Completed';
        break;
    }

    Color opColor = Colors.blue;
    if (item.operation == SyncOperation.insert) opColor = Colors.green;
    if (item.operation == SyncOperation.delete) opColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: opColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.operation.name.toUpperCase(),
                    style: TextStyle(
                      color: opColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.table.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Record ID: ${item.recordId.isNotEmpty ? item.recordId : item.id}',
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
            Text(
              'Queued at: ${DateFormat('d MMM, HH:mm:ss').format(item.createdAt)} • Attempts: ${item.attempts}',
              style: TextStyle(color: colorScheme.outline, fontSize: 11),
            ),
            if (item.lastError != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Notice: ${UserFriendlyError.toFriendly(item.lastError)}',
                  style: TextStyle(color: Colors.red.shade800, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
