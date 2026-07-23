import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'workout.freezed.dart';
part 'workout.g.dart';

@freezed
abstract class WorkoutExercise with _$WorkoutExercise {
  const factory WorkoutExercise({
    required String name,
    required String instructions,
    @Default(3) int sets,
    @Default('12 reps') String repsOrDuration,
    @Default(60) int restSeconds,
    // ignore: invalid_annotation_target
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    ExerciseIllustration? illustration,
  }) = _WorkoutExercise;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);
}

@freezed
abstract class Workout with _$Workout {
  const factory Workout({
    required String id,
    required String name,
    required WorkoutCategory category,
    @Default('Beginner') String difficulty,
    required int durationMinutes,
    required int estimatedCalories,
    @Default([]) List<WorkoutExercise> exercises,
    @Default(false) bool completed,
    DateTime? completedAt,
    required DateTime createdAt,
  }) = _Workout;

  factory Workout.fromJson(Map<String, dynamic> json) =>
      _$WorkoutFromJson(json);
}
