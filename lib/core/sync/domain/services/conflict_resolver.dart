import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sync_queue_item.dart';
import '../../../../core/utils/logger.dart';

enum ResolutionDecision {
  applyClient,
  keepServer,
  merge;
}

class ConflictResolver {
  final SupabaseClient _supabase;

  ConflictResolver(this._supabase);

  /// Resolves any conflict between a queued local change and current remote state
  Future<ResolutionDecision> resolveConflict(SyncQueueItem item) async {
    // 1. Append-only tables (financial/immutable records)
    // Never overwrite; idempotent upsert with unique ID ensures single truth
    final appendOnlyTables = {'sales', 'sale_items', 'expenses', 'debts', 'debt_payments', 'stock_movements'};
    if (appendOnlyTables.contains(item.table)) {
      return ResolutionDecision.applyClient;
    }

    // 2. Mutable tables: check existing server record timestamp
    try {
      final remoteRecord = await _supabase
          .from(item.table)
          .select('id, updated_at')
          .eq('id', item.recordId)
          .maybeSingle();

      if (remoteRecord == null) {
        // Record does not exist remotely yet, apply client operation safely
        return ResolutionDecision.applyClient;
      }

      final serverUpdatedAtStr = remoteRecord['updated_at'] as String?;
      if (serverUpdatedAtStr == null) {
        return ResolutionDecision.applyClient;
      }

      final serverUpdatedAt = DateTime.tryParse(serverUpdatedAtStr);
      if (serverUpdatedAt == null) {
        return ResolutionDecision.applyClient;
      }

      // Last-Write-Wins: Client change is newer than server update
      if (item.createdAt.isAfter(serverUpdatedAt)) {
        return ResolutionDecision.applyClient;
      } else {
        AppLogger.i('Conflict resolved: Server record is newer (${serverUpdatedAt.toIso8601String()}) than client queue item (${item.createdAt.toIso8601String()}). Keeping server record.');
        return ResolutionDecision.keepServer;
      }
    } catch (e) {
      AppLogger.w('Failed to check conflict for ${item.table} ${item.recordId}: $e. Defaulting to applyClient.');
      return ResolutionDecision.applyClient;
    }
  }
}
