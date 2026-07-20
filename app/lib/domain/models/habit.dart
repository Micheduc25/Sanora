import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit.freezed.dart';
part 'habit.g.dart';

@freezed
abstract class Habit with _$Habit {
  const factory Habit({
    required String id,
    required String name,
    @Default('✅') String emoji,
    @Default('') String description,
    /// 1–7 = Mon–Sun. Empty means every day.
    @Default([]) List<int> scheduledWeekdays,
    @Default(1) int dailyTarget,
    @Default(true) bool active,
    String? reminderTime,
    required DateTime createdAt,
  }) = _Habit;

  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);
}

@freezed
abstract class HabitLog with _$HabitLog {
  const factory HabitLog({
    required String id,
    required String habitId,
    required String dayKey,
    @Default(1) int count,
    required DateTime loggedAt,
  }) = _HabitLog;

  factory HabitLog.fromJson(Map<String, dynamic> json) =>
      _$HabitLogFromJson(json);
}
