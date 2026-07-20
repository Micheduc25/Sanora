import 'package:uuid/uuid.dart';

import '../../core/storage/local_store.dart';
import '../../core/utils/extensions.dart';
import '../../domain/models/habit.dart';
import '../sync/sync_service.dart';

class HabitsRepository {
  HabitsRepository(this._sync);

  final SyncService _sync;

  List<Habit> all() =>
      LocalStore.readAll(LocalStore.habitsBox, Habit.fromJson)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<Habit> activeForDay(DateTime day) => all()
      .where(
        (h) =>
            h.active &&
            (h.scheduledWeekdays.isEmpty ||
                h.scheduledWeekdays.contains(day.weekday)),
      )
      .toList();

  List<HabitLog> logs() =>
      LocalStore.readAll(LocalStore.habitLogsBox, HabitLog.fromJson);

  int countForDay(String habitId, DateTime day) => logs()
      .where((l) => l.habitId == habitId && l.dayKey == day.dayKey)
      .fold(0, (sum, l) => sum + l.count);

  bool isDoneForDay(Habit habit, DateTime day) =>
      countForDay(habit.id, day) >= habit.dailyTarget;

  /// Consecutive scheduled days completed, ending today (or yesterday if
  /// today is not yet complete — an unfinished today never breaks a streak).
  int streak(Habit habit, {DateTime? today}) {
    final now = (today ?? DateTime.now()).dateOnly;
    var day = now;
    var count = 0;
    var first = true;
    while (true) {
      final scheduled =
          habit.scheduledWeekdays.isEmpty ||
          habit.scheduledWeekdays.contains(day.weekday);
      if (scheduled) {
        if (isDoneForDay(habit, day)) {
          count++;
        } else if (first && day == now) {
          // today still in progress
        } else {
          break;
        }
        first = false;
      }
      day = day.subtract(const Duration(days: 1));
      if (now.difference(day).inDays > 366) break;
    }
    return count;
  }

  Future<void> save(Habit habit) async {
    await LocalStore.put(LocalStore.habitsBox, habit.id, habit.toJson());
    await _sync.enqueue('habits', 'upsert', habit.toJson());
  }

  Future<void> remove(String id) async {
    await LocalStore.delete(LocalStore.habitsBox, id);
    await _sync.enqueue('habits', 'delete', {'id': id});
  }

  Future<void> log(Habit habit, DateTime day, {int count = 1}) async {
    final log = HabitLog(
      id: const Uuid().v4(),
      habitId: habit.id,
      dayKey: day.dayKey,
      count: count,
      loggedAt: DateTime.now(),
    );
    await LocalStore.put(LocalStore.habitLogsBox, log.id, log.toJson());
    await _sync.enqueue('habit_logs', 'upsert', log.toJson());
  }

  Future<void> undoLog(Habit habit, DateTime day) async {
    final dayLogs =
        logs()
            .where((l) => l.habitId == habit.id && l.dayKey == day.dayKey)
            .toList()
          ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    if (dayLogs.isEmpty) return;
    final last = dayLogs.first;
    await LocalStore.delete(LocalStore.habitLogsBox, last.id);
    await _sync.enqueue('habit_logs', 'delete', {'id': last.id});
  }
}
