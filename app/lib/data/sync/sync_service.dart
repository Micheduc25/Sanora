import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/local_store.dart';
import '../supabase_service.dart';

/// What the last replay attempt did, so the UI can show an honest backup
/// state instead of claiming everything is safe.
enum SyncState { idle, syncing, offline, failed }

@immutable
class SyncStatus {
  const SyncStatus({
    this.state = SyncState.idle,
    this.pending = 0,
    this.rejected = 0,
    this.lastSyncedAt,
    this.message,
  });

  final SyncState state;
  final int pending;

  /// Ops the server refused often enough that we stopped replaying them.
  final int rejected;
  final DateTime? lastSyncedAt;
  final String? message;
}

/// Replays queued writes against Supabase whenever the user is signed in and
/// online. Ops are idempotent upserts keyed by row id, so replay order only
/// matters per-row and the queue preserves insertion order.
class SyncService {
  SyncService(this._supabase) {
    if (_supabase.client != null) {
      _subscription = Connectivity().onConnectivityChanged.listen((results) {
        if (!results.contains(ConnectivityResult.none)) flush();
      });
    }
  }

  /// A row rejected this many times is almost certainly malformed rather than
  /// unlucky, so it stops competing for the queue with healthy writes.
  static const _maxAttempts = 5;

  final SupabaseService _supabase;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _flushing = false;

  final status = ValueNotifier<SyncStatus>(const SyncStatus());

  Future<void> enqueue(
    String table,
    String op,
    Map<String, dynamic> payload, {
    String? conflictTarget,
  }) async {
    if (_supabase.client == null) return;
    final syncOp = SyncOp(
      id: const Uuid().v4(),
      table: table,
      op: op,
      payload: payload,
      queuedAt: DateTime.now(),
      conflictTarget: conflictTarget,
    );
    await LocalStore.put(LocalStore.syncQueueBox, syncOp.id, syncOp.toJson());
    unawaited(flush());
  }

  Future<void> flush() async {
    final client = _supabase.client;
    final userId = _supabase.userId;
    if (client == null || userId == null || _flushing) return;
    _flushing = true;
    _emit(SyncState.syncing);
    try {
      final ops = LocalStore.readAll(LocalStore.syncQueueBox, SyncOp.fromJson)
        ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
      for (final op in ops) {
        try {
          final payload = {...op.payload, 'user_id': userId};
          if (op.op == 'delete') {
            await client
                .from(op.table)
                .delete()
                .eq('id', op.payload['id'] as String)
                .eq('user_id', userId);
          } else {
            await client
                .from(op.table)
                .upsert(payload, onConflict: op.conflictTarget);
          }
          await LocalStore.delete(LocalStore.syncQueueBox, op.id);
        } on PostgrestException catch (e) {
          // The server understood the row and refused it. Everything queued
          // behind it is unrelated, so retire this one and keep going rather
          // than wedging the whole queue on a single bad write.
          await _reschedule(op, 'server rejected (${e.code}): ${e.message}');
        } catch (e) {
          // Transport failure — the rest of the batch would fail the same
          // way, so stop and let the next connectivity change retry.
          await _reschedule(op, '$e');
          _emit(SyncState.offline, message: 'Waiting for a connection.');
          return;
        }
      }
      _emit(SyncState.idle, syncedNow: true);
    } finally {
      _flushing = false;
    }
  }

  /// Puts a failed op back with its attempt count bumped, or retires it to the
  /// dead-letter box once it has burned through [_maxAttempts].
  Future<void> _reschedule(SyncOp op, String error) async {
    final next = op.retry(error);
    if (next.attempts >= _maxAttempts) {
      await LocalStore.put(
        LocalStore.syncDeadLetterBox,
        next.id,
        next.toJson(),
      );
      await LocalStore.delete(LocalStore.syncQueueBox, next.id);
      debugPrint('sync: ${op.table}/${op.op} retired after $error');
      return;
    }
    await LocalStore.put(LocalStore.syncQueueBox, next.id, next.toJson());
    debugPrint('sync: ${op.table}/${op.op} attempt ${next.attempts}: $error');
  }

  /// Server tables that mirror a local box one row per document. `profiles` is
  /// absent because it stores two documents in a single row.
  static const _mirroredTables = <String, String>{
    'metric_entries': LocalStore.metricsBox,
    'meals': LocalStore.mealsBox,
    'habits': LocalStore.habitsBox,
    'habit_logs': LocalStore.habitLogsBox,
    'chat_messages': LocalStore.chatBox,
    'reminders': LocalStore.remindersBox,
    'workouts': LocalStore.workoutsBox,
  };

  /// Rehydrates the local boxes from Postgres so a reinstall or a second
  /// device gets the user's history back. Rows still queued for upload are
  /// skipped — the local copy is newer than anything the server can return.
  Future<void> pull() async {
    final client = _supabase.client;
    final userId = _supabase.userId;
    if (client == null || userId == null) return;
    _emit(SyncState.syncing);
    try {
      final unpushed = LocalStore.readAll(
        LocalStore.syncQueueBox,
        SyncOp.fromJson,
      ).map((op) => op.payload['id']).whereType<String>().toSet();

      for (final entry in _mirroredTables.entries) {
        final rows = await client
            .from(entry.key)
            .select()
            .eq('user_id', userId);
        for (final row in rows) {
          final id = row['id'] as String?;
          if (id == null || unpushed.contains(id)) continue;
          final document = Map<String, dynamic>.from(row)..remove('user_id');
          await LocalStore.put(entry.value, id, document);
        }
      }
      await _pullProfile(client, userId, skip: unpushed);
      _emit(SyncState.idle, syncedNow: true);
    } catch (e) {
      debugPrint('sync: pull failed: $e');
      _emit(SyncState.offline, message: 'Could not restore your data.');
    }
  }

  /// The profile row carries the user document and the computed health profile
  /// side by side, and a locally-edited profile must not be clobbered by an
  /// older server copy.
  Future<void> _pullProfile(
    SupabaseClient client,
    String userId, {
    required Set<String> skip,
  }) async {
    final row = await client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return;
    if (skip.contains(row['id'])) return;

    final local = LocalStore.get(LocalStore.profileBox, 'user');
    if (local != null) {
      final localAt = DateTime.tryParse(local['updated_at'] as String? ?? '');
      final remoteAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
      if (localAt != null && remoteAt != null && localAt.isAfter(remoteAt)) {
        return;
      }
    }
    await LocalStore.put(
      LocalStore.profileBox,
      'user',
      Map<String, dynamic>.from(row['data'] as Map),
    );
    await LocalStore.put(
      LocalStore.profileBox,
      'health',
      Map<String, dynamic>.from(row['health'] as Map),
    );
  }

  /// Pushes anything queued, then restores whatever this device is missing.
  Future<void> synchronise() async {
    await flush();
    await pull();
  }

  /// Moves everything out of the dead-letter box for one more round, for a
  /// user who has fixed whatever the server was objecting to.
  Future<void> retryRejected() async {
    final retired = LocalStore.readAll(
      LocalStore.syncDeadLetterBox,
      SyncOp.fromJson,
    );
    for (final op in retired) {
      final revived = SyncOp(
        id: op.id,
        table: op.table,
        op: op.op,
        payload: op.payload,
        queuedAt: op.queuedAt,
        conflictTarget: op.conflictTarget,
      );
      await LocalStore.put(LocalStore.syncQueueBox, op.id, revived.toJson());
      await LocalStore.delete(LocalStore.syncDeadLetterBox, op.id);
    }
    await flush();
  }

  void _emit(SyncState state, {bool syncedNow = false, String? message}) {
    final pending = LocalStore.box(LocalStore.syncQueueBox).length;
    final rejected = LocalStore.box(LocalStore.syncDeadLetterBox).length;
    status.value = SyncStatus(
      state: rejected > 0 && state == SyncState.idle ? SyncState.failed : state,
      pending: pending,
      rejected: rejected,
      lastSyncedAt: syncedNow ? DateTime.now() : status.value.lastSyncedAt,
      message: message,
    );
  }

  void dispose() {
    _subscription?.cancel();
    status.dispose();
  }
}
