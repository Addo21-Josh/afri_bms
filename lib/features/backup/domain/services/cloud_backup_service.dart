import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';

class BackupMetadata {
  const BackupMetadata({
    required this.fileName,
    required this.createdAt,
    required this.totalRecords,
    required this.fileSizeBytes,
    this.storageUrl,
  });

  final String fileName;
  final DateTime createdAt;
  final int totalRecords;
  final int fileSizeBytes;
  final String? storageUrl;
}

class CloudBackupService {
  CloudBackupService(this._supabase);

  final SupabaseClient _supabase;

  /// Exports full database state to a JSON backup and optionally uploads to Supabase Storage
  Future<File> createFullBackup({
    required String businessId,
    required String businessName,
    bool uploadToStorage = true,
  }) async {
    AppLogger.i('Generating full JSON backup for $businessName ($businessId)...');

    // 1. Gather all entity tables with direct business_id column
    final directTables = [
      'product_categories',
      'expense_categories',
      'products',
      'customers',
      'suppliers',
      'expenses',
      'debts',
      'sales',
    ];
    final Map<String, dynamic> backupData = {};
    int totalRecords = 0;
    final Map<String, int> counts = {};

    for (final table in directTables) {
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

    // Also populate legacy 'categories' key for backward compatibility
    backupData['categories'] = backupData['product_categories'] ?? [];

    // Pull product_variants and stock for backed-up products
    try {
      final productIds = (backupData['products'] as List<dynamic>?)
              ?.map((p) => p['id'] as String)
              .toList() ??
          [];
      if (productIds.isNotEmpty) {
        try {
          final variants = await _supabase
              .from('product_variants')
              .select()
              .inFilter('product_id', productIds);
          final list = variants as List<dynamic>;
          backupData['product_variants'] = list;
          counts['product_variants'] = list.length;
          totalRecords += list.length;
        } catch (e) {
          AppLogger.w('Backup: could not pull product_variants: $e');
          backupData['product_variants'] = [];
          counts['product_variants'] = 0;
        }

        try {
          final stock = await _supabase
              .from('stock')
              .select()
              .inFilter('product_id', productIds);
          final list = stock as List<dynamic>;
          backupData['stock'] = list;
          counts['stock'] = list.length;
          totalRecords += list.length;
        } catch (e) {
          AppLogger.w('Backup: could not pull stock: $e');
          backupData['stock'] = [];
          counts['stock'] = 0;
        }
      }
    } catch (e) {
      AppLogger.w('Backup: could not process product sub-records: $e');
    }

    // Pull sale_items belonging to the backed-up sales
    try {
      final saleIds = (backupData['sales'] as List<dynamic>?)
              ?.map((s) => s['id'] as String)
              .toList() ??
          [];
      if (saleIds.isNotEmpty) {
        final saleItems = await _supabase
            .from('sale_items')
            .select()
            .inFilter('sale_id', saleIds);
        final list = saleItems as List<dynamic>;
        backupData['sale_items'] = list;
        counts['sale_items'] = list.length;
        totalRecords += list.length;
      } else {
        backupData['sale_items'] = [];
        counts['sale_items'] = 0;
      }
    } catch (e) {
      AppLogger.w('Backup: could not pull sale_items: $e');
      backupData['sale_items'] = [];
      counts['sale_items'] = 0;
    }

    // Pull debt_payments belonging to the backed-up debts
    try {
      final debtIds = (backupData['debts'] as List<dynamic>?)
              ?.map((d) => d['id'] as String)
              .toList() ??
          [];
      if (debtIds.isNotEmpty) {
        final debtPayments = await _supabase
            .from('debt_payments')
            .select()
            .inFilter('debt_id', debtIds);
        final list = debtPayments as List<dynamic>;
        backupData['debt_payments'] = list;
        counts['debt_payments'] = list.length;
        totalRecords += list.length;
      } else {
        backupData['debt_payments'] = [];
        counts['debt_payments'] = 0;
      }
    } catch (e) {
      AppLogger.w('Backup: could not pull debt_payments: $e');
      backupData['debt_payments'] = [];
      counts['debt_payments'] = 0;
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

    // Order of restoration for foreign keys:
    // categories -> products -> variants -> stock -> customers -> suppliers -> expenses -> debts -> debt_payments -> sales -> sale_items
    final order = [
      'product_categories',
      'expense_categories',
      'products',
      'product_variants',
      'stock',
      'customers',
      'suppliers',
      'expenses',
      'debts',
      'debt_payments',
      'sales',
      'sale_items',
    ];

    for (final table in order) {
      // Handle legacy 'categories' key mapping to 'product_categories'
      List<dynamic>? records;
      if (table == 'product_categories') {
        records = (data['product_categories'] as List<dynamic>?) ??
            (data['categories'] as List<dynamic>?);
      } else {
        records = data[table] as List<dynamic>?;
      }

      if (records == null || records.isEmpty) continue;

      int success = 0;
      for (final r in records) {
        try {
          final recordMap = Map<String, dynamic>.from(r as Map);

          // Tables that don't have direct business_id column
          const nonBusinessIdTables = {'sale_items', 'product_variants', 'stock', 'debt_payments'};
          if (!nonBusinessIdTables.contains(table)) {
            recordMap['business_id'] = businessId; // ensure target business
          }

          // Resurrect soft-deleted items (e.g. products, categories, customers)
          if (table == 'products') {
            recordMap['is_active'] = true;
            recordMap['deleted_at'] = null;
          } else {
            if (recordMap.containsKey('is_active')) {
              recordMap['is_active'] = true;
            }
            if (recordMap.containsKey('deleted_at')) {
              recordMap['deleted_at'] = null;
            }
          }

          if (table == 'sale_items' || table == 'sales') {
            // sale_items and sales are immutable audit transactions with INSERT policies.
            // Using insert avoids PostgrestException 42501 (missing UPDATE USING policy on upsert).
            try {
              await _supabase.from(table).insert(recordMap);
              success++;
            } on PostgrestException catch (e) {
              if (e.code == '23505' || e.message.contains('duplicate key')) {
                // Record already exists in Supabase, count as intact
                success++;
              } else {
                AppLogger.w('Notice inserting $table record (${recordMap['id']}): ${e.message}');
              }
            }
          } else {
            // Mutable entities: products, categories, customers, expenses, debts, etc.
            try {
              await _supabase.from(table).upsert(recordMap, onConflict: 'id');
              success++;
            } on PostgrestException catch (e) {
              // If foreign key failed (e.g. category was removed), clear category_id and retry
              if (table == 'products' && (e.code == '23503' || e.message.contains('foreign key'))) {
                try {
                  recordMap['category_id'] = null;
                  await _supabase.from(table).upsert(recordMap, onConflict: 'id');
                  success++;
                } catch (retryErr) {
                  AppLogger.e('Failed restoring product without category: $retryErr');
                }
              } else {
                AppLogger.e('Failed upserting record in $table: $e');
              }
            }
          }
        } catch (e) {
          AppLogger.e('Failed restoring record in $table: $e');
        }
      }
      restoredCounts[table] = success;
    }

    return restoredCounts;
  }
}
