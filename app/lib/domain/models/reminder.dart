import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder.freezed.dart';
part 'reminder.g.dart';

enum ReminderKind {
  @JsonValue('water')
  water('Drink water', '💧'),
  @JsonValue('stand')
  stand('Stand up & move', '🧍'),
  @JsonValue('meal')
  meal('Meal time', '🍽️'),
  @JsonValue('exercise')
  exercise('Exercise', '🏃'),
  @JsonValue('medication')
  medication('Medication', '💊'),
  @JsonValue('sleep')
  sleep('Wind down for sleep', '🌙'),
  @JsonValue('walk')
  walk('Take a walk', '🚶'),
  @JsonValue('custom')
  custom('Reminder', '🔔');

  const ReminderKind(this.defaultTitle, this.emoji);
  final String defaultTitle;
  final String emoji;
}

@freezed
abstract class Reminder with _$Reminder {
  const factory Reminder({
    required String id,
    required ReminderKind kind,
    required String title,
    @Default('') String body,
    /// "HH:mm" 24h local time.
    required String time,
    /// 1–7 = Mon–Sun. Empty means every day.
    @Default([]) List<int> weekdays,
    @Default(true) bool enabled,
    required DateTime createdAt,
  }) = _Reminder;

  factory Reminder.fromJson(Map<String, dynamic> json) =>
      _$ReminderFromJson(json);
}
