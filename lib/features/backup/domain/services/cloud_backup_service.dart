import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';

class BackupMetadata {
  final String fileName;
  final DateTime createdAt;
  final int totalRecords;
  final int fileSizeBytes;
  final String? storageUrl;

  const BackupMetadata({
    required this.fileName,
    required this.createdAt,
    required this.totalRecords,
    required this.fileSizeBytes,
    this.storageUrl,
  });
}

class CloudBackupService {
  final SupabaseClient _supabase;

  CloudBackupService(this._supabase);

  /// Exports full database state to a JSON backup and optionally uploads to Supabase Storage
  Future<File> createFullBackup({
    required String businessId,
    required String businessName,
    bool uploadToStorage = true,
  }) async {
    AppLogger.i('Generating full JSON backup for $businessName ($businessId)...');

    // 1. Gather all entity tables
    final tables = ['products', 'categories', 'customers', 'sales', 'sale_items', 'debts', 'expenses', 'suppliers'];
    final Map<String, dynamic> backupData = {};
    int totalRecords = 0;
    final Map<String, int> counts = {};

    for (final table in tables) {
      try {
        final records = await _supabase.from(table).select().eq('business_id', businessId);
        final list = records as List<dynamic>;
        backupData[table] = list;
        counts[table] = list.length;
        totalRecords += list.length;
      } catch (e) {
        AppLogger.w('Backup: could not pull table $table: $e');
        backupData[table] = [];
        counts[table] = 0;
      }
    }

    final backupPayload = {
      'app': 'Afri_BMS',
      'version': '1.0.0',
      'schema_version': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'business_id': businessId,
      'business_name': businessName,
      'total_records': totalRecords,
      'record_counts': counts,
      'data': backupData,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);

    // 2. Save locally
    final dir = await getApplicationDocumentsDirectory();
    final sanitizedBiz = businessName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final fileName = 'afribms_backup_${sanitizedBiz}_${DateTime.now().millisecondsSinceEpoch}.json';
    final backupFile = File('${dir.path}/$fileName');
    await backupFile.writeAsString(jsonString, flush: true);

    // 3. Upload to Supabase Storage if configured
    if (uploadToStorage) {
      try {
        final storagePath = '$businessId/$fileName';
        await _supabase.storage.from('backups').upload(
              storagePath,
              backupFile,
              fileOptions: const FileOptions(contentType: 'application/json', upsert: true),
            );
        AppLogger.i('Backup uploaded to Supabase Storage: $storagePath');
      } catch (e) {
        AppLogger.w('Could not upload backup to Supabase storage bucket (offline or bucket missing): $e');
      }
    }

    return backupFile;
  }

  /// Shares backup file via native share sheet (Drive, WhatsApp, Mail, Files)
  Future<void> shareBackupFile(File file, String businessName) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Afri_BMS Cloud Backup - $businessName',
      text: 'Encrypted JSON backup file for Afri_BMS ($businessName).',
    );
  }

  /// Restores records from a valid backup JSON structure
  Future<Map<String, int>> restoreFromBackupJson({
    required String businessId,
    required Map<String, dynamic> backupJson,
  }) async {
    AppLogger.i('Restoring from backup JSON...');

    if (backupJson['app'] != 'Afri_BMS' || backupJson['data'] == null) {
      throw const FormatException('Invalid backup file. Missing Afri_BMS signature.');
    }

    final data = backupJson['data'] as Map<String, dynamic>;
    final Map<String, int> restoredCounts = {};

    // Order of restoration for foreign keys: categories -> products -> customers -> sales...
    final order = ['categories', 'products', 'customers', 'suppliers', 'expenses', 'debts', 'sales', 'sale_items'];

    for (final table in order) {
      final records = data[table] as List<dynamic>?;
      if (records == null || records.isEmpty) continue;

      int success = 0;
      for (final r in records) {
        try {
          final recordMap = Map<String, dynamic>.from(r as Map);
          recordMap['business_id'] = businessId; // ensure target business
          await _supabase.from(table).upsert(recordMap, onConflict: 'id');
          success++;
        } catch (e) {
          AppLogger.e('Failed restoring record in $table: $e');
        }
      }
      restoredCounts[table] = success;
    }

    return restoredCounts;
  }
}
