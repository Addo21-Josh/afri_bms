import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/sync_queue_item.dart';
import '../../../../core/utils/logger.dart';

class SyncQueueStorage {
  static const String _fileName = 'afri_sync_queue.json';
  File? _cachedFile;

  Future<File> _getFile() async {
    if (_cachedFile != null) return _cachedFile!;
    final directory = await getApplicationDocumentsDirectory();
    _cachedFile = File('${directory.path}/$_fileName');
    if (!await _cachedFile!.exists()) {
      await _cachedFile!.writeAsString(jsonEncode([]), flush: true);
    }
    return _cachedFile!;
  }

  Future<List<SyncQueueItem>> getAllItems() async {
    try {
      final file = await _getFile();
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> list = jsonDecode(content) as List<dynamic>;
      return list
          .map((item) => SyncQueueItem.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('Error loading sync queue: $e');
      return [];
    }
  }

  Future<void> _saveAllItems(List<SyncQueueItem> items) async {
    try {
      final file = await _getFile();
      final jsonList = items.map((i) => i.toMap()).toList();
      await file.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (e) {
      AppLogger.e('Error saving sync queue: $e');
    }
  }

  Future<void> enqueue(SyncQueueItem item) async {
    await enqueueAll([item]);
  }

  Future<void> enqueueAll(List<SyncQueueItem> newItems) async {
    if (newItems.isEmpty) return;
    final items = await getAllItems();

    for (final item in newItems) {
      final index = items.indexWhere(
        (i) =>
            i.table == item.table &&
            i.recordId == item.recordId &&
            i.operation == item.operation &&
            i.status == SyncItemStatus.pending,
      );

      if (index >= 0) {
        items[index] = item; // Update payload with latest changes
      } else {
        items.add(item);
      }
    }
    await _saveAllItems(items);
  }

  Future<List<SyncQueueItem>> getPendingItems({String? businessId}) async {
    final items = await getAllItems();
    return items.where((i) {
      final matchesBiz =
          businessId == null ||
          businessId.isEmpty ||
          i.businessId == businessId;
      return matchesBiz &&
          (i.status == SyncItemStatus.pending ||
              i.status == SyncItemStatus.failed);
    }).toList();
  }

  Future<int> getPendingCount({String? businessId}) async {
    final pending = await getPendingItems(businessId: businessId);
    return pending.length;
  }

  Future<void> updateItemStatus(
    String id,
    SyncItemStatus status, {
    String? error,
    DateTime? completedAt,
  }) async {
    final items = await getAllItems();
    final index = items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final current = items[index];
      items[index] = current.copyWith(
        status: status,
        attempts: status == SyncItemStatus.failed
            ? current.attempts + 1
            : current.attempts,
        lastError: error,
        completedAt:
            completedAt ??
            (status == SyncItemStatus.completed
                ? DateTime.now()
                : current.completedAt),
      );
      await _saveAllItems(items);
    }
  }

  Future<void> retryFailedItems({String? businessId}) async {
    final items = await getAllItems();
    for (int i = 0; i < items.length; i++) {
      if (items[i].status == SyncItemStatus.failed) {
        if (businessId == null ||
            businessId.isEmpty ||
            items[i].businessId == businessId) {
          items[i] = items[i].copyWith(
            status: SyncItemStatus.pending,
            lastError: null,
            attempts: 0,
          );
        }
      }
    }
    await _saveAllItems(items);
  }

  Future<void> clearCompleted() async {
    final items = await getAllItems();
    items.removeWhere((i) => i.status == SyncItemStatus.completed);
    await _saveAllItems(items);
  }

  Future<void> clearAll() async {
    await _saveAllItems([]);
  }
}
