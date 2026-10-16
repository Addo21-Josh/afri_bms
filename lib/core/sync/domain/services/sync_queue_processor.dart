import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sync_queue_item.dart';
import '../../data/local/sync_queue_storage.dart';
import 'conflict_resolver.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/storage/secure_local_storage.dart';

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

  /// Relational dependency priority (lower numbers = parent tables, higher numbers = dependent child tables)
  static const Map<String, int> _tablePriority = {
    'profiles': 1,
    'businesses': 2,
    'branches': 3,
    'user_roles': 4,
    'categories': 5,
    'products': 6,
    'product_variants': 7,
    'customers': 8,
    'suppliers': 9,
    'sales': 10,
    'expenses': 11,
    'debts': 12,
    'sale_items': 20,
    'stock_movements': 21,
    'debt_payments': 22,
    'payments': 23,
  };

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
    final rawPending = await _storage.getPendingItems(businessId: businessId);
    if (rawPending.isEmpty) {
      return const SyncBatchResult(totalProcessed: 0, successful: 0, failed: 0, errors: []);
    }

    // Verify user is authenticated before attempting to sync protected tables
    if (_supabase.auth.currentSession == null) {
      try {
        final sessionStr = await const SecureLocalStorage().accessToken();
        if (sessionStr != null && sessionStr.isNotEmpty) {
          await _supabase.auth.recoverSession(sessionStr);
        }
      } catch (e) {
        AppLogger.w('Failed to recover session before sync queue processing: $e');
      }
    }

    if (_supabase.auth.currentSession == null) {
      AppLogger.w('Cannot process sync queue: No authenticated Supabase session.');
      return SyncBatchResult(
        totalProcessed: rawPending.length,
        successful: 0,
        failed: rawPending.length,
        errors: const ['User session is not active. Please check your login credentials.'],
      );
    }

    // Sort items by relational table dependency priority:
    // Parents (sales, products, etc.) must be pushed before children (sale_items, stock_movements)
    final pendingItems = List<SyncQueueItem>.from(rawPending)
      ..sort((a, b) {
        final prioA = _tablePriority[a.table] ?? 15;
        final prioB = _tablePriority[b.table] ?? 15;
        if (prioA != prioB) {
          return prioA.compareTo(prioB);
        }
        return a.createdAt.compareTo(b.createdAt);
      });

    int successCount = 0;
    int failedCount = 0;
    final List<String> errors = [];
    final total = pendingItems.length;
    final Set<String> failedParentIds = {};

    AppLogger.i('Starting sync queue processing for $total items (sorted by dependency priority)...');

    for (int i = 0; i < total; i++) {
      final item = pendingItems[i];

      // Skip items that exceeded max retry limit
      if (item.attempts >= maxAttempts) {
        AppLogger.w('Skipping item ${item.id} (${item.table}) - exceeded max retry attempts ($maxAttempts)');
        failedCount++;
        continue;
      }

      // Check if parent sale failed in this batch to prevent cascaded RLS / foreign key errors
      if (item.table == 'sale_items') {
        final parentSaleId = item.payload['sale_id'] as String?;
        if (parentSaleId != null && failedParentIds.contains(parentSaleId)) {
          AppLogger.w('Skipping sale_item ${item.recordId} because parent sale $parentSaleId failed in this sync batch.');
          failedCount++;
          await _storage.updateItemStatus(item.id, SyncItemStatus.failed, error: 'Parent sale failed to sync');
          continue;
        }
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
        failedParentIds.add(item.recordId);
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
        try {
          await table.insert(item.payload);
        } on PostgrestException catch (e) {
          // If record already exists in Supabase (unique key conflict 23505),
          // treat as successfully synced without error
          if (e.code == '23505' || e.message.contains('duplicate key')) {
            AppLogger.i('Item ${item.recordId} already exists in ${item.table}. Treating insert as completed.');
          } else {
            rethrow;
          }
        }
        break;

      case SyncOperation.update:
        await table.update(item.payload).eq('id', item.recordId);
        break;

      case SyncOperation.delete:
        await table.delete().eq('id', item.recordId);
        break;
    }
  }
}
