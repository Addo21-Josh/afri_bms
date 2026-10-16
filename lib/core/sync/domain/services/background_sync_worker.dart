import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/storage/secure_local_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../data/local/sync_queue_storage.dart';
import 'conflict_resolver.dart';
import 'sync_queue_processor.dart';

const String afriSyncTaskPeriodic = 'com.afribms.sync.periodic';
const String afriSyncTaskOneOff = 'com.afribms.sync.oneoff';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.i('WorkManager background task triggered: $task');

    try {
      // Ensure Supabase is initialized in background isolate with encrypted secure storage
      try {
        Supabase.instance.client;
      } catch (_) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
          authOptions: const FlutterAuthClientOptions(
            localStorage: SecureLocalStorage(),
          ),
        );
      }

      final client = Supabase.instance.client;
      var currentSession = client.auth.currentSession;
      if (currentSession == null) {
        try {
          final sessionStr = await const SecureLocalStorage().accessToken();
          if (sessionStr != null && sessionStr.isNotEmpty) {
            final res = await client.auth.recoverSession(sessionStr);
            currentSession = res.session;
          }
        } catch (e) {
          AppLogger.w('Background sync worker session recovery error: $e');
        }
      }

      if (currentSession == null) {
        AppLogger.w('Background sync worker: no active Supabase session. Skipping queue to avoid RLS violation.');
        return true;
      }

      final storage = SyncQueueStorage();
      final resolver = ConflictResolver(client);
      final processor = SyncQueueProcessor(
        storage: storage,
        conflictResolver: resolver,
        supabase: client,
      );

      final result = await processor.processQueue();
      AppLogger.i('Background sync worker finished: ${result.successful}/${result.totalProcessed} synced');
      return true;
    } catch (e) {
      AppLogger.e('Background sync worker failed: $e');
      return false;
    }
  });
}

class BackgroundSyncWorker {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      _isInitialized = true;
      AppLogger.i('WorkManager initialized successfully');

      // Register periodic background sync (every 15 minutes)
      await registerPeriodicSync();
    } catch (e) {
      AppLogger.w('WorkManager initialization skipped or failed: $e');
    }
  }

  static Future<void> registerPeriodicSync() async {
    try {
      await Workmanager().registerPeriodicTask(
        'afri_bms_sync_periodic',
        afriSyncTaskPeriodic,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } catch (e) {
      AppLogger.w('Failed to register periodic background sync: $e');
    }
  }

  static Future<void> triggerOneOffSync() async {
    try {
      await Workmanager().registerOneOffTask(
        'afri_bms_sync_oneoff_${DateTime.now().millisecondsSinceEpoch}',
        afriSyncTaskOneOff,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      AppLogger.w('Failed to register one-off sync task: $e');
    }
  }
}
