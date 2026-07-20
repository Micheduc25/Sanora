import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    @Default('') String name,
    required int age,
    required Sex sex,
    required double heightCm,
    required double weightKg,
    double? waistCm,
    double? hipCm,
    double? bodyFatPct,
    @Default('') String occupation,
    @Default('') String country,
    @Default('en') String language,
    @Default(ActivityLevel.sedentary) ActivityLevel activityLevel,
    @Default(0) int exerciseDaysPerWeek,
    @Default(7.0) double sleepHours,
    @Default(StressLevel.moderate) StressLevel stressLevel,
    @Default([]) List<String> medicalConditions,
    @Default([]) List<String> medications,
    @Default([]) List<String> allergies,
    @Default([]) List<String> foodPreferences,
    @Default([]) List<String> favoriteFoods,
    @Default('') String workSchedule,
    @Default([]) List<GoalType> goals,
    double? targetWeightKg,
    double? targetWaistCm,
    double? targetBodyFatPct,
    DateTime? targetDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
