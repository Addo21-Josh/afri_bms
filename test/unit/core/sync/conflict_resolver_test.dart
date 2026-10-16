import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afri_bms/core/sync/domain/models/sync_queue_item.dart';
import 'package:afri_bms/core/sync/domain/services/conflict_resolver.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late ConflictResolver resolver;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    resolver = ConflictResolver(mockSupabase);
  });

  group('ConflictResolver', () {
    test('always returns applyClient for append-only tables (sales, expenses, debts, etc.)', () async {
      final now = DateTime.now();
      final appendOnlyTables = [
        'sales',
        'sale_items',
        'expenses',
        'debts',
        'debt_payments',
        'stock_movements',
      ];

      for (final table in appendOnlyTables) {
        final item = SyncQueueItem(
          id: 'queue-1',
          businessId: 'biz-1',
          table: table,
          recordId: 'rec-123',
          operation: SyncOperation.insert,
          payload: {'amount': 100},
          createdAt: now,
        );

        final decision = await resolver.resolveConflict(item);
        expect(decision, equals(ResolutionDecision.applyClient));
      }

      // Supabase query should not even be triggered for append-only tables
      verifyZeroInteractions(mockSupabase);
    });
  });
}
