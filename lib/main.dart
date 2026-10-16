import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/storage/secure_local_storage.dart';
import 'core/utils/logger.dart';
import 'core/sync/domain/services/background_sync_worker.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.i('Initializing Afri_BMS...');

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(),
      ),
    );
    AppLogger.i('Supabase initialized successfully with secure storage');
  } catch (e) {
    AppLogger.e('Failed to initialize Supabase: $e');
  }

  // Initialize background sync worker
  await BackgroundSyncWorker.initialize();

  runApp(const ProviderScope(child: AfriBmsApp()));
}
