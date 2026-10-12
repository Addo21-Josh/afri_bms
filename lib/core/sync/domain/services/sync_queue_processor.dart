import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sync_queue_item.dart';
import '../../data/local/sync_queue_storage.dart';
import 'conflict_resolver.dart';
import '../../../../core/utils/logger.dart';

typedef SyncProgressCallback = void Function(int processed, int total, double progress);

class SyncBatchResult {
  final int totalProcessed;
  final int successful;
  final int failed;
  final List<String> errors;

  const SyncBatchResult({
    required this.totalProcessed,
    required this.successful,
    required this.failed,
    required this.errors,
  });
}

class SyncQueueProcessor {
  final SyncQueueStorage _storage;
  final ConflictResolver _conflictResolver;
  final SupabaseClient _supabase;

  static const int maxAttempts = 5;

  SyncQueueProcessor({
    required SyncQueueStorage storage,
    required ConflictResolver conflictResolver,
    required SupabaseClient supabase,
  })  : _storage = storage,
        _conflictResolver = conflictResolver,
        _supabase = supabase;

  /// Processes all pending items in the sync queue with progress reporting and batching
  Future<SyncBatchResult> processQueue({
    String? businessId,
    SyncProgressCallback? onProgress,
  }) async {
    final pendingItems = await _storage.getPendingItems(businessId: businessId);
    if (pendingItems.isEmpty) {
      return const SyncBatchResult(totalProcessed: 0, successful: 0, failed: 0, errors: []);
    }

    int successCount = 0;
    int failedCount = 0;
    final List<String> errors = [];
    final total = pendingItems.length;

    AppLogger.i('Starting sync queue processing for $total items...');

    // Group items by table where applicable, while preserving chronological order
    for (int i = 0; i < total; i++) {
      final item = pendingItems[i];

      // Skip items that exceeded max retry limit
      if (item.attempts >= maxAttempts) {
        AppLogger.w('Skipping item ${item.id} (${item.table}) - exceeded max retry attempts ($maxAttempts)');
        failedCount++;
        continue;
      }

      await _storage.updateItemStatus(item.id, SyncItemStatus.processing);

      try {
        // 1. Conflict check
        final decision = await _conflictResolver.resolveConflict(item);
        if (decision == ResolutionDecision.keepServer) {
          // Server record is newer, mark completed locally
          await _storage.updateItemStatus(item.id, SyncItemStatus.completed);
          successCount++;
          onProgress?.call(i + 1, total, (i + 1) / total);
          continue;
        }

        // 2. Execute mutation against Supabase
        await _executeOperation(item);

        // 3. Mark completed
        await _storage.updateItemStatus(item.id, SyncItemStatus.completed);
        successCount++;
      } catch (e) {
        final errorMsg = e.toString();
        AppLogger.e('Failed syncing item ${item.id} (${item.table}): $errorMsg');
        errors.add('${item.table}: $errorMsg');
        failedCount++;
        await _storage.updateItemStatus(item.id, SyncItemStatus.failed, error: errorMsg);
      }

      onProgress?.call(i + 1, total, (i + 1) / total);
    }

    // Auto-clean completed items
    await _storage.clearCompleted();

    AppLogger.i('Sync queue complete: $successCount succeeded, $failedCount failed.');
    return SyncBatchResult(
      totalProcessed: total,
      successful: successCount,
      failed: failedCount,
      errors: errors,
    );
  }

  Future<void> _executeOperation(SyncQueueItem item) async {
    final table = _supabase.from(item.table);

    switch (item.operation) {
      case SyncOperation.insert:
      case SyncOperation.update:
        // Use upsert to handle idempotency and avoids unique key conflicts
        await table.upsert(item.payload, onConflict: 'id');
        break;

      case SyncOperation.delete:
        await table.delete().eq('id', item.recordId);
        break;
    }
  }
}
