import 'dart:convert';
import 'package:flutter/foundation.dart';

enum SyncOperation {
  insert,
  update,
  delete;

  String get value => name;

  static SyncOperation fromString(String value) {
    return SyncOperation.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SyncOperation.insert,
    );
  }
}

enum SyncItemStatus {
  pending,
  processing,
  failed,
  completed;

  String get value => name;

  static SyncItemStatus fromString(String value) {
    return SyncItemStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SyncItemStatus.pending,
    );
  }
}

@immutable
class SyncQueueItem {
  final String id;
  final String businessId;
  final String table;
  final SyncOperation operation;
  final String recordId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  final SyncItemStatus status;
  final DateTime? completedAt;

  const SyncQueueItem({
    required this.id,
    required this.businessId,
    required this.table,
    required this.operation,
    required this.recordId,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
    this.status = SyncItemStatus.pending,
    this.completedAt,
  });

  SyncQueueItem copyWith({
    String? id,
    String? businessId,
    String? table,
    SyncOperation? operation,
    String? recordId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? attempts,
    String? lastError,
    SyncItemStatus? status,
    DateTime? completedAt,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      table: table ?? this.table,
      operation: operation ?? this.operation,
      recordId: recordId ?? this.recordId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'table': table,
      'operation': operation.name,
      'record_id': recordId,
      'payload': jsonEncode(payload),
      'created_at': createdAt.toIso8601String(),
      'attempts': attempts,
      'last_error': lastError,
      'status': status.name,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedPayload = {};
    if (map['payload'] != null) {
      if (map['payload'] is String) {
        try {
          parsedPayload = jsonDecode(map['payload'] as String) as Map<String, dynamic>;
        } catch (_) {
          parsedPayload = {};
        }
      } else if (map['payload'] is Map) {
        parsedPayload = Map<String, dynamic>.from(map['payload'] as Map);
      }
    }

    return SyncQueueItem(
      id: map['id'] as String,
      businessId: map['business_id'] as String? ?? '',
      table: map['table'] as String,
      operation: SyncOperation.fromString(map['operation'] as String? ?? 'insert'),
      recordId: map['record_id'] as String? ?? '',
      payload: parsedPayload,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      lastError: map['last_error'] as String?,
      status: SyncItemStatus.fromString(map['status'] as String? ?? 'pending'),
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'] as String) : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SyncQueueItem.fromJson(String source) =>
      SyncQueueItem.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
