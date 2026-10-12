import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';

class DeltaSyncResult {
  final String table;
  final int recordsReceived;
  final DateTime syncTimestamp;

  const DeltaSyncResult({
    required this.table,
    required this.recordsReceived,
    required this.syncTimestamp,
  });
}

class DeltaSyncService {
  final SupabaseClient _supabase;
  static const String _metadataFileName = 'afri_delta_sync_meta.json';
  File? _metaFile;

  DeltaSyncService(this._supabase);

  Future<File> _getFile() async {
    if (_metaFile != null) return _metaFile!;
    final directory = await getApplicationDocumentsDirectory();
    _metaFile = File('${directory.path}/$_metadataFileName');
    if (!await _metaFile!.exists()) {
      await _metaFile!.writeAsString(jsonEncode({}), flush: true);
    }
    return _metaFile!;
  }

  Future<DateTime?> getLastSyncTime(String table, String businessId) async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      if (content.isEmpty) return null;
      final map = jsonDecode(content) as Map<String, dynamic>;
      final key = '${businessId}_$table';
      final timeStr = map[key] as String?;
      return timeStr != null ? DateTime.tryParse(timeStr) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setLastSyncTime(String table, String businessId, DateTime timestamp) async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      final map = content.isNotEmpty ? jsonDecode(content) as Map<String, dynamic> : <String, dynamic>{};
      final key = '${businessId}_$table';
      map[key] = timestamp.toIso8601String();
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (e) {
      AppLogger.e('Failed to persist delta sync timestamp: $e');
    }
  }

  /// Downloads changed records since the last sync time for a specific table
  Future<DeltaSyncResult> pullDelta({
    required String table,
    required String businessId,
  }) async {
    final now = DateTime.now().toUtc();
    final lastSync = await getLastSyncTime(table, businessId);

    try {
      var query = _supabase.from(table).select().eq('business_id', businessId);

      if (lastSync != null) {
        // Delta filter: only changed records
        query = query.gt('updated_at', lastSync.toIso8601String());
      }

      final response = await query.order('updated_at', ascending: true).limit(500);
      final List<dynamic> records = response as List<dynamic>;

      // Update sync marker
      await setLastSyncTime(table, businessId, now);

      AppLogger.i('Delta sync pulled ${records.length} records for $table since ${lastSync?.toIso8601String() ?? 'beginning'}');

      return DeltaSyncResult(
        table: table,
        recordsReceived: records.length,
        syncTimestamp: now,
      );
    } catch (e) {
      AppLogger.e('Error pulling delta for $table: $e');
      return DeltaSyncResult(table: table, recordsReceived: 0, syncTimestamp: now);
    }
  }

  /// Pulls delta updates across all major business tables
  Future<List<DeltaSyncResult>> pullAllDeltas(String businessId) async {
    final tables = ['products', 'customers', 'sales', 'debts', 'expenses', 'suppliers'];
    final results = <DeltaSyncResult>[];
    for (final table in tables) {
      final res = await pullDelta(table: table, businessId: businessId);
      results.add(res);
    }
    return results;
  }
}
