import 'dart:convert';

import 'package:hive_ce/hive.dart';

/// Offline-first persistence. Every feature reads and writes Hive first;
/// remote sync happens in the background by replaying queued [SyncOp]s.
///
/// Values are stored as JSON strings — Hive's nested collections come back
/// as `Map<dynamic, dynamic>` which breaks generated `fromJson` casts.
abstract final class LocalStore {
  static const settingsBox = 'settings';
  static const profileBox = 'profile';
  static const metricsBox = 'metrics';
  static const mealsBox = 'meals';
  static const habitsBox = 'habits';
  static const habitLogsBox = 'habit_logs';
  static const chatBox = 'chat';
  static const insightsBox = 'insights';
  static const remindersBox = 'reminders';
  static const workoutsBox = 'workouts';
  static const syncQueueBox = 'sync_queue';

  static const _all = [
    settingsBox,
    profileBox,
    metricsBox,
    mealsBox,
    habitsBox,
    habitLogsBox,
    chatBox,
    insightsBox,
    remindersBox,
    workoutsBox,
    syncQueueBox,
  ];

  static Future<void> open() async {
    for (final name in _all) {
      await Hive.openBox<String>(name);
    }
  }

  static Box<String> box(String name) => Hive.box<String>(name);

  static Future<void> put(
    String boxName,
    String key,
    Map<String, dynamic> json,
  ) => box(boxName).put(key, jsonEncode(json));

  static Map<String, dynamic>? get(String boxName, String key) {
    final raw = box(boxName).get(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  static List<T> readAll<T>(
    String boxName,
    T Function(Map<String, dynamic>) fromJson,
  ) => box(boxName).values
      .map((raw) => fromJson(jsonDecode(raw) as Map<String, dynamic>))
      .toList();

  static Future<void> delete(String boxName, String key) =>
      box(boxName).delete(key);

  static Future<void> wipe() async {
    for (final name in _all) {
      await box(name).clear();
    }
  }
}

/// A pending remote write, replayed in order once connectivity returns.
class SyncOp {
  const SyncOp({
    required this.id,
    required this.table,
    required this.op,
    required this.payload,
    required this.queuedAt,
  });

  final String id;
  final String table;
  final String op; // upsert | delete
  final Map<String, dynamic> payload;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'op': op,
    'payload': payload,
    'queued_at': queuedAt.toIso8601String(),
  };

  factory SyncOp.fromJson(Map<String, dynamic> json) => SyncOp(
    id: json['id'] as String,
    table: json['table'] as String,
    op: json['op'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    queuedAt: DateTime.parse(json['queued_at'] as String),
  );
}
