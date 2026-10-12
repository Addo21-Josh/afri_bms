import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/sync_queue_storage.dart';
import '../../data/local/local_cache_service.dart';
import '../../domain/models/sync_queue_item.dart';
import '../../domain/services/conflict_resolver.dart';
import '../../domain/services/delta_sync_service.dart';
import '../../domain/services/sync_queue_processor.dart';
import '../../domain/services/background_sync_worker.dart';
import '../../../../features/business/presentation/providers/business_provider.dart';
import '../../../../core/utils/logger.dart';

class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final double progress;
  final String statusMessage;
  final List<SyncQueueItem> queueItems;
  final String? lastError;

  const SyncState({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    this.lastSyncTime,
    this.progress = 0.0,
    this.statusMessage = 'Up to date',
    this.queueItems = const [],
    this.lastError,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    double? progress,
    String? statusMessage,
    List<SyncQueueItem>? queueItems,
    String? lastError,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      queueItems: queueItems ?? this.queueItems,
      lastError: lastError,
    );
  }
}

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

final syncStorageProvider = Provider<SyncQueueStorage>((ref) {
  return SyncQueueStorage();
});

final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  return ConflictResolver(Supabase.instance.client);
});

final deltaSyncServiceProvider = Provider<DeltaSyncService>((ref) {
  return DeltaSyncService(Supabase.instance.client);
});

final syncQueueProcessorProvider = Provider<SyncQueueProcessor>((ref) {
  final storage = ref.watch(syncStorageProvider);
  final resolver = ref.watch(conflictResolverProvider);
  return SyncQueueProcessor(
    storage: storage,
    conflictResolver: resolver,
    supabase: Supabase.instance.client,
  );
});

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final storage = ref.watch(syncStorageProvider);
  final processor = ref.watch(syncQueueProcessorProvider);
  final deltaService = ref.watch(deltaSyncServiceProvider);
  final business = ref.watch(currentBusinessProvider);

  return SyncNotifier(
    storage: storage,
    processor: processor,
    deltaService: deltaService,
    businessId: business?.id,
  );
});

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncQueueStorage _storage;
  final SyncQueueProcessor _processor;
  final DeltaSyncService _deltaService;
  final String? _businessId;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _autoSyncDebounce;

  SyncNotifier({
    required SyncQueueStorage storage,
    required SyncQueueProcessor processor,
    required DeltaSyncService deltaService,
    String? businessId,
  })  : _storage = storage,
        _processor = processor,
        _deltaService = deltaService,
        _businessId = businessId,
        super(const SyncState(isOnline: true, isSyncing: false, pendingCount: 0)) {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    try {
      final results = await Connectivity().checkConnectivity();
      final online = results.any((r) => r != ConnectivityResult.none);
      state = state.copyWith(isOnline: online);
    } catch (_) {}

    // Listen to network changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      final wasOffline = !state.isOnline;
      state = state.copyWith(
        isOnline: online,
        statusMessage: online ? (state.pendingCount > 0 ? '${state.pendingCount} pending sync' : 'Online') : 'Offline Mode',
      );

      // Auto-trigger sync upon coming back online
      if (online && wasOffline) {
        AppLogger.i('Network re-established: scheduling automatic sync');
        _triggerAutoSync();
      }
    });

    await refreshQueue();
  }

  void _triggerAutoSync() {
    _autoSyncDebounce?.cancel();
    _autoSyncDebounce = Timer(const Duration(seconds: 2), () {
      triggerSync();
    });
  }

  Future<void> refreshQueue() async {
    final items = await _storage.getAllItems();
    final pending = items.where((i) => i.status == SyncItemStatus.pending || i.status == SyncItemStatus.failed).length;
    state = state.copyWith(
      queueItems: items,
      pendingCount: pending,
      statusMessage: state.isOnline
          ? (pending > 0 ? '$pending items pending' : 'All changes synced')
          : 'Offline Mode ($pending queued)',
    );
  }

  /// Enqueue an offline mutation (CRUD)
  Future<void> enqueueOperation({
    required String table,
    required SyncOperation operation,
    required String recordId,
    required Map<String, dynamic> payload,
    String? businessId,
  }) async {
    final bizId = businessId ?? _businessId ?? '';
    final item = SyncQueueItem(
      id: const Uuid().v4(),
      businessId: bizId,
      table: table,
      operation: operation,
      recordId: recordId,
      payload: payload,
      createdAt: DateTime.now(),
    );

    await _storage.enqueue(item);
    await refreshQueue();
    AppLogger.i('Enqueued offline operation for $table ($recordId)');

    // Trigger one-off background worker registration as fallback
    BackgroundSyncWorker.triggerOneOffSync();

    // If online, immediately process queue
    if (state.isOnline && !state.isSyncing) {
      _triggerAutoSync();
    }
  }

  /// Manually trigger full push & pull sync
  Future<void> triggerSync() async {
    if (state.isSyncing) return;
    if (!state.isOnline) {
      state = state.copyWith(statusMessage: 'Cannot sync while offline');
      return;
    }

    state = state.copyWith(
      isSyncing: true,
      progress: 0.1,
      statusMessage: 'Syncing changes...',
      lastError: null,
    );

    try {
      // 1. Process outbound queue
      final pushResult = await _processor.processQueue(
        businessId: _businessId,
        onProgress: (processed, total, progress) {
          state = state.copyWith(
            progress: 0.1 + (progress * 0.5),
            statusMessage: 'Pushing offline changes ($processed/$total)...',
          );
        },
      );

      // 2. Pull inbound delta updates
      final bId = _businessId;
      if (bId != null && bId.isNotEmpty) {
        state = state.copyWith(progress: 0.7, statusMessage: 'Fetching latest cloud updates...');
        await _deltaService.pullAllDeltas(bId);
      }

      final now = DateTime.now();
      await refreshQueue();

      state = state.copyWith(
        isSyncing: false,
        progress: 1.0,
        lastSyncTime: now,
        statusMessage: pushResult.failed > 0
            ? 'Synced with ${pushResult.failed} errors'
            : 'All data synchronized',
        lastError: pushResult.errors.isNotEmpty ? pushResult.errors.first : null,
      );
    } catch (e) {
      AppLogger.e('Manual sync error: $e');
      await refreshQueue();
      state = state.copyWith(
        isSyncing: false,
        statusMessage: 'Sync failed',
        lastError: e.toString(),
      );
    }
  }

  Future<void> retryFailed() async {
    await _storage.retryFailedItems(businessId: _businessId);
    await refreshQueue();
    await triggerSync();
  }

  Future<void> clearCompleted() async {
    await _storage.clearCompleted();
    await refreshQueue();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _autoSyncDebounce?.cancel();
    super.dispose();
  }
}
