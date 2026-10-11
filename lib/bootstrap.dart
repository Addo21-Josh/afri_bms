import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:afri_bms/core/utils/logger.dart';

class AppBootstrap {
  static late final Isar isar;

  static Future<void> initialize() async {
    AppLogger.i('Initializing Database...');
    final dir = await getApplicationDocumentsDirectory();
    
    // We will initialize collections here when we define them
    try {
      isar = await Isar.open(
        [], // Schemas will be added here
        directory: dir.path,
      );
      AppLogger.i('Database initialized successfully');
    } catch (e) {
      AppLogger.e('Failed to initialize database: $e');
    }
  }
}
