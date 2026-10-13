import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/logger.dart';

const _secureStorage = FlutterSecureStorage();
const _keyLocale = 'app_user_locale';
const _keyThemeMode = 'app_user_theme_mode';
const _keyPrinterName = 'app_printer_name';
const _keyPrinterPaperWidth = 'app_printer_paper_width';
const _keyAutoPrint = 'app_auto_print_receipt';

/// Supported Locales in Afri_BMS
class AppLanguages {
  static const english = Locale('en');
  static const french = Locale('fr');
  static const swahili = Locale('sw');

  static const supported = [english, french, swahili];

  static String getLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'sw':
        return 'Kiswahili';
      case 'en':
      default:
        return 'English';
    }
  }

  static String getFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return '🇫🇷';
      case 'sw':
        return '🇰🇪';
      case 'en':
      default:
        return '🇬🇧';
    }
  }
}

/// Dynamic Locale Provider with secure storage persistence
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(AppLanguages.english) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final code = await _secureStorage.read(key: _keyLocale);
      if (code != null && AppLanguages.supported.any((l) => l.languageCode == code)) {
        state = Locale(code);
      }
    } catch (e) {
      AppLogger.w('Failed reading persisted locale: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (state == newLocale) return;
    state = newLocale;
    try {
      await _secureStorage.write(key: _keyLocale, value: newLocale.languageCode);
      AppLogger.i('App locale updated to: ${newLocale.languageCode}');
    } catch (e) {
      AppLogger.w('Failed persisting locale: $e');
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Theme Mode Provider with persistence
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final modeStr = await _secureStorage.read(key: _keyThemeMode);
      if (modeStr != null) {
        if (modeStr == 'light') state = ThemeMode.light;
        if (modeStr == 'dark') state = ThemeMode.dark;
        if (modeStr == 'system') state = ThemeMode.system;
      }
    } catch (e) {
      AppLogger.w('Failed reading persisted theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final val = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await _secureStorage.write(key: _keyThemeMode, value: val);
      AppLogger.i('Theme mode updated to: $val');
    } catch (e) {
      AppLogger.w('Failed persisting theme mode: $e');
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Printer Settings Model & Provider
class PrinterConfig {
  const PrinterConfig({
    this.printerName,
    this.paperWidthMm = 58,
    this.autoPrintReceipt = false,
  });

  final String? printerName;
  final int paperWidthMm; // 58 or 80
  final bool autoPrintReceipt;

  PrinterConfig copyWith({
    String? printerName,
    int? paperWidthMm,
    bool? autoPrintReceipt,
  }) {
    return PrinterConfig(
      printerName: printerName ?? this.printerName,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
    );
  }
}

class PrinterConfigNotifier extends StateNotifier<PrinterConfig> {
  PrinterConfigNotifier() : super(const PrinterConfig()) {
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    try {
      final name = await _secureStorage.read(key: _keyPrinterName);
      final widthStr = await _secureStorage.read(key: _keyPrinterPaperWidth);
      final autoStr = await _secureStorage.read(key: _keyAutoPrint);

      state = PrinterConfig(
        printerName: name,
        paperWidthMm: int.tryParse(widthStr ?? '58') ?? 58,
        autoPrintReceipt: autoStr == 'true',
      );
    } catch (e) {
      AppLogger.w('Failed reading printer config: $e');
    }
  }

  Future<void> updatePrinter({
    String? name,
    int? widthMm,
    bool? autoPrint,
  }) async {
    state = state.copyWith(
      printerName: name,
      paperWidthMm: widthMm,
      autoPrintReceipt: autoPrint,
    );
    try {
      if (name != null) await _secureStorage.write(key: _keyPrinterName, value: name);
      if (widthMm != null) await _secureStorage.write(key: _keyPrinterPaperWidth, value: widthMm.toString());
      if (autoPrint != null) await _secureStorage.write(key: _keyAutoPrint, value: autoPrint.toString());
    } catch (e) {
      AppLogger.w('Failed saving printer config: $e');
    }
  }
}

final printerConfigProvider = StateNotifierProvider<PrinterConfigNotifier, PrinterConfig>((ref) {
  return PrinterConfigNotifier();
});
