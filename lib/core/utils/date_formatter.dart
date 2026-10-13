import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

class DateFormatter {
  static String formatShortDate(DateTime date, {String? locale}) {
    return DateFormat('MMM d, yyyy', locale).format(date);
  }

  static String formatDateTime(DateTime date, {String? locale}) {
    return DateFormat('MMM d, yyyy • h:mm a', locale).format(date);
  }

  static String formatTime(DateTime date, {String? locale}) {
    return DateFormat('h:mm a', locale).format(date);
  }

  static String formatMonthYear(DateTime date, {String? locale}) {
    return DateFormat('MMMM yyyy', locale).format(date);
  }
}

class LocaleHelper {
  /// Checks if the provided locale is Right-To-Left (e.g. Arabic, Hebrew)
  static bool isRtl(Locale locale) {
    const rtlLanguages = {'ar', 'fa', 'he', 'ur'};
    return rtlLanguages.contains(locale.languageCode.toLowerCase());
  }

  /// Returns text direction based on locale
  static TextDirection getTextDirection(Locale locale) {
    return isRtl(locale) ? TextDirection.rtl : TextDirection.ltr;
  }
}
