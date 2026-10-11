import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/logger.dart';
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

  runApp(const ProviderScope(child: AfriBmsApp()));
}
