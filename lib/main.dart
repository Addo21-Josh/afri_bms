import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/logger.dart';
import 'core/sync/domain/services/background_sync_worker.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.i('Initializing Afri_BMS...');

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    AppLogger.i('Supabase initialized successfully');
  } catch (e) {
    AppLogger.e('Failed to initialize Supabase: $e');
  }

  // Initialize background sync worker
  await BackgroundSyncWorker.initialize();

  runApp(const ProviderScope(child: AfriBmsApp()));
}
