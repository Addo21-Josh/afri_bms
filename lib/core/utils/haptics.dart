import 'package:flutter/services.dart';

/// Provides tactile haptic feedback for user interactions across the app
class AppHaptics {
  /// Subtle tick for button presses, selection changes, tab switches
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Light impact for item added to cart, toggle switches, filter chips
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for successful checkout, form submission, pull-to-refresh
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for barcode scan detected, cash payment confirmed
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Double buzz for critical errors, deletion prompts, out of stock alerts
  static void error() {
    HapticFeedback.vibrate();
  }
}
