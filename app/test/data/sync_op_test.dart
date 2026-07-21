import 'package:bodi/core/storage/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SyncOp op({int attempts = 0, String? conflictTarget}) => SyncOp(
    id: 'op-1',
    table: 'profiles',
    op: 'upsert',
    payload: const {'id': 'row-1'},
    queuedAt: DateTime(2026, 7, 21),
    conflictTarget: conflictTarget,
    attempts: attempts,
  );

  group('SyncOp', () {
    test('round-trips the replay bookkeeping', () {
      final restored = SyncOp.fromJson(
        op(attempts: 2, conflictTarget: 'user_id').retry('boom').toJson(),
      );

      expect(restored.conflictTarget, 'user_id');
      expect(restored.attempts, 3);
      expect(restored.lastError, 'boom');
      expect(restored.payload, {'id': 'row-1'});
      expect(restored.queuedAt, DateTime(2026, 7, 21));
    });

    test('reads ops queued before retry tracking existed', () {
      // Upgrading users have writes sitting in Hive in the original shape;
      // dropping them would silently lose data.
      final legacy = SyncOp.fromJson({
        'id': 'op-1',
        'table': 'meals',
        'op': 'upsert',
        'payload': {'id': 'row-1'},
        'queued_at': '2026-07-21T00:00:00.000',
      });

      expect(legacy.attempts, 0);
      expect(legacy.conflictTarget, isNull);
      expect(legacy.lastError, isNull);
    });

    test('retry preserves the conflict target so replays stay correct', () {
      expect(
        op(conflictTarget: 'user_id').retry('x').conflictTarget,
        'user_id',
      );
    });
  });
}
