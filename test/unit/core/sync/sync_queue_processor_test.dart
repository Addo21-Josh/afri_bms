import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afri_bms/core/sync/data/local/sync_queue_storage.dart';
import 'package:afri_bms/core/sync/domain/models/sync_queue_item.dart';
import 'package:afri_bms/core/sync/domain/services/conflict_resolver.dart';
import 'package:afri_bms/core/sync/domain/services/sync_queue_processor.dart';

class MockSyncQueueStorage extends Mock implements SyncQueueStorage {}

class MockConflictResolver extends Mock implements ConflictResolver {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSyncQueueStorage mockStorage;
  late MockConflictResolver mockResolver;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late SyncQueueProcessor processor;

  setUp(() {
    mockStorage = MockSyncQueueStorage();
    mockResolver = MockConflictResolver();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockSupabase.auth).thenReturn(mockAuth);

    processor = SyncQueueProcessor(
      storage: mockStorage,
      conflictResolver: mockResolver,
      supabase: mockSupabase,
    );
  });

  group('SyncQueueProcessor', () {
    test('returns empty result when queue has no pending items', () async {
      when(
        () => mockStorage.getPendingItems(businessId: any(named: 'businessId')),
      ).thenAnswer((_) async => []);

      final result = await processor.processQueue();

      expect(result.totalProcessed, equals(0));
      expect(result.successful, equals(0));
      expect(result.failed, equals(0));
    });

    test('returns failed batch when user session is not active', () async {
      when(
        () => mockStorage.getPendingItems(businessId: any(named: 'businessId')),
      ).thenAnswer(
        (_) async => [
          SyncQueueItem(
            id: 'q-1',
            businessId: 'biz-1',
            table: 'sales',
            recordId: 'sale-1',
            operation: SyncOperation.insert,
            payload: {'id': 'sale-1'},
            createdAt: DateTime.now(),
          ),
        ],
      );

      when(() => mockAuth.currentSession).thenReturn(null);

      final result = await processor.processQueue();

      expect(result.totalProcessed, equals(1));
      expect(result.successful, equals(0));
      expect(result.failed, equals(1));
      expect(result.errors.first, contains('User session is not active'));
    });
  });
}
