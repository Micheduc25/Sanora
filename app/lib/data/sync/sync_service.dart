import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/local_store.dart';
import '../supabase_service.dart';

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

  final SupabaseService _supabase;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _flushing = false;

  Future<void> enqueue(
    String table,
    String op,
    Map<String, dynamic> payload,
  ) async {
    if (_supabase.client == null) return;
    final syncOp = SyncOp(
      id: const Uuid().v4(),
      table: table,
      op: op,
      payload: payload,
      queuedAt: DateTime.now(),
    );
    await LocalStore.put(LocalStore.syncQueueBox, syncOp.id, syncOp.toJson());
    unawaited(flush());
  }

  Future<void> flush() async {
    final client = _supabase.client;
    final userId = _supabase.userId;
    if (client == null || userId == null || _flushing) return;
    _flushing = true;
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
            await client.from(op.table).upsert(payload);
          }
          await LocalStore.delete(LocalStore.syncQueueBox, op.id);
        } catch (e) {
          debugPrint('sync: ${op.table}/${op.op} failed, will retry: $e');
          break;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
