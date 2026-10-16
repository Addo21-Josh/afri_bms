import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/services/cloud_backup_service.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../debts/presentation/providers/debts_provider.dart';
import '../../../suppliers/presentation/providers/suppliers_provider.dart';
import '../../../../core/sync/presentation/providers/sync_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/subscription/domain/models/subscription_tier.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';
import '../../../../core/utils/user_friendly_error.dart';

final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService(Supabase.instance.client);
});

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool get _isLoading => _isBackingUp || _isRestoring;
  bool _autoBackupEnabled = true;
  List<FileSystemEntity> _localBackups = [];

  @override
  void initState() {
    super.initState();
    _loadLocalBackups();
  }

  Future<void> _loadLocalBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().where((f) => f.path.contains('afribms_backup_') && f.path.endsWith('.json')).toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      if (mounted) {
        setState(() {
          _localBackups = files;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleCreateBackup() async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) return;

    final gate = ref.read(featureGateProvider);
    if (!gate.limits.cloudBackup) {
      UpgradePromptSheet.show(
        context,
        featureName: 'Cloud Backup & Snapshot Export',
        customMessage: 'Full automated and cloud backups require Afri_BMS Pro or Enterprise.',
        currentTier: gate.tier,
        suggestedTier: SubscriptionTier.pro,
      );
      return;
    }

    setState(() => _isBackingUp = true);

    try {
      final backupService = ref.read(cloudBackupServiceProvider);
      final file = await backupService.createFullBackup(
        businessId: business.id,
        businessName: business.name,
      );

      await _loadLocalBackups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created successfully: ${file.path.split(Platform.pathSeparator).last}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => backupService.shareBackupFile(file, business.name),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyError.toFriendly(
                e,
                defaultMessage: 'Unable to generate backup file. Please try again.',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreFromJson(Map<String, dynamic> parsed, {String? sourceName}) async {
    final business = ref.read(currentBusinessProvider);
    if (business == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active business selected to restore data into.')),
        );
      }
      return;
    }

    setState(() => _isRestoring = true);

    try {
      final backupService = ref.read(cloudBackupServiceProvider);
      final results = await backupService.restoreFromBackupJson(
        businessId: business.id,
        backupJson: parsed,
      );

      // Refresh all feature providers to display newly restored records
      ref.invalidate(productsListProvider);
      ref.invalidate(productCategoriesProvider);
      ref.invalidate(customersListProvider);
      ref.invalidate(salesListProvider);
      ref.invalidate(expensesListProvider);
      ref.invalidate(debtsListProvider);
      ref.invalidate(suppliersListProvider);

      // Eagerly refresh and warm local cache so restored products show immediately
      try {
        final repo = ref.read(inventoryRepositoryProvider);
        final prodsRes = await repo.getProducts(businessId: business.id);
        prodsRes.fold((_) {}, (prods) async {
          await ref.read(localCacheServiceProvider).cacheProducts(business.id, prods);
        });

        final catsRes = await repo.getCategories(business.id);
        catsRes.fold((_) {}, (cats) async {
          await ref.read(localCacheServiceProvider).cacheCategories(business.id, cats);
        });
      } catch (e) {
        AppLogger.w('Failed to warm local cache after restore: $e');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Restoration Complete'),
            content: Text(
              '${sourceName != null ? 'Data from "$sourceName" has been restored into "${business.name}".\n\n' : ''}'
              'Restored records:\n${results.entries.map((e) => '• ${e.key}: ${e.value}').join('\n')}',
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              UserFriendlyError.toFriendly(
                e,
                defaultMessage: 'Unable to restore data from backup file. Please verify file integrity and try again.',
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _confirmRestoreFile(File file, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup?'),
        content: Text(
          'Are you sure you want to restore records from "$fileName"?\n\n'
          'This will import all products, customers, sales, and transactions from this snapshot into your active business.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore Data')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final content = await file.readAsString();
        final parsed = jsonDecode(content) as Map<String, dynamic>;
        await _restoreFromJson(parsed, sourceName: fileName);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed reading backup file: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showRestoreDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Restore from Backup JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your Afri_BMS backup JSON payload below to restore products, customers, and transactions:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{\n  "app": "Afri_BMS",\n  "data": { ... }\n}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final raw = textController.text.trim();
              if (raw.isEmpty) return;

              Navigator.pop(dialogCtx);
              try {
                final Map<String, dynamic> parsed = jsonDecode(raw) as Map<String, dynamic>;
                await _restoreFromJson(parsed, sourceName: 'Pasted JSON');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid JSON formatting: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final business = ref.watch(currentBusinessProvider);
    final backupService = ref.read(cloudBackupServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup & Restore'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_upload_outlined, color: colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Automated Store Backups',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Safely export complete store state including sales, inventory, and customer ledgers.',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Automatic Daily Backup (Pro+)'),
                    subtitle: const Text('Generates and archives backup at 00:00 every day'),
                    value: _autoBackupEnabled,
                    onChanged: (val) {
                      if (val) {
                        final gate = ref.read(featureGateProvider);
                        if (!gate.limits.cloudBackup) {
                          UpgradePromptSheet.show(
                            context,
                            featureName: 'Automatic Daily Cloud Backup',
                            customMessage: 'Daily scheduled automated cloud backups require Afri_BMS Pro or Enterprise.',
                            currentTier: gate.tier,
                            suggestedTier: SubscriptionTier.pro,
                          );
                          return;
                        }
                      }
                      setState(() => _autoBackupEnabled = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(val ? 'Daily automatic backups enabled.' : 'Daily automatic backups paused.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isRestoring)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Restoring store data from backup snapshot... Please do not close.',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isBackingUp)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onSecondaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Creating and saving backup snapshot...',
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Primary Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _handleCreateBackup,
                  icon: _isBackingUp
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.backup_outlined),
                  label: Text(_isBackingUp ? 'Backing Up...' : 'Create Backup Now'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _showRestoreDialog,
                icon: _isRestoring
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.settings_backup_restore),
                label: Text(_isRestoring ? 'Restoring...' : 'Restore Data'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Local Backups List
          Text('Local Backup Snapshots (${_localBackups.length})',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          if (_localBackups.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No backup snapshots generated on this device yet.'),
                ),
              ),
            )
          else
            ..._localBackups.map((entity) {
              final file = File(entity.path);
              final stat = file.statSync();
              final name = entity.path.split(Platform.pathSeparator).last;
              final sizeKb = (stat.size / 1024).toStringAsFixed(1);
              final dateStr = DateFormat('d MMM yyyy, HH:mm').format(stat.modified);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined, color: Colors.teal),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('$dateStr • $sizeKb KB', style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Restore this snapshot',
                        icon: const Icon(Icons.settings_backup_restore, size: 20, color: Colors.teal),
                        onPressed: _isLoading ? null : () => _confirmRestoreFile(file, name),
                      ),
                      IconButton(
                        tooltip: 'Share / Export',
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () => backupService.shareBackupFile(file, business?.name ?? 'Afri_BMS'),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () async {
                          await file.delete();
                          _loadLocalBackups();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
