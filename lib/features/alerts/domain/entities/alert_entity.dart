import 'package:flutter/material.dart';

enum AlertSeverity {
  critical, // Expired, Out of stock, severely overdue (>30d)
  warning,  // Low stock, debt due soon/today
  info,     // Daily sales milestone, sync notices
}

enum AlertType {
  lowStock,
  outOfStock,
  overdueDebt,
  expiringProduct,
  dailySalesTarget,
}

@immutable
class BusinessAlertEntity {
  const BusinessAlertEntity({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.actionRoute,
    this.actionLabel,
    this.metadata,
    this.isRead = false,
  });

  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? actionRoute;
  final String? actionLabel;
  final Map<String, dynamic>? metadata;
  final bool isRead;

  BusinessAlertEntity copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    DateTime? timestamp,
    String? actionRoute,
    String? actionLabel,
    Map<String, dynamic>? metadata,
    bool? isRead,
  }) {
    return BusinessAlertEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      actionRoute: actionRoute ?? this.actionRoute,
      actionLabel: actionLabel ?? this.actionLabel,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
    );
  }
}
