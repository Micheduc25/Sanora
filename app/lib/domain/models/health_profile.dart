import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'health_profile.freezed.dart';
part 'health_profile.g.dart';

/// The AI Health Profile — every value is derived from [UserProfile] by the
/// HealthEngine and recomputed whenever user data changes.
@freezed
abstract class HealthProfile with _$HealthProfile {
  const factory HealthProfile({
    required double bmi,
    required BmiCategory bmiCategory,
    required double estimatedBodyFatPct,
    required double bmr,
    required double tdee,
    required double calorieTarget,
    required double proteinTargetG,
    required double waterTargetMl,
    required int stepGoal,
    required int exerciseMinutesPerWeek,
    required double sleepGoalHours,
    required double healthyWeightMinKg,
    required double healthyWeightMaxKg,
    double? waistToHeightRatio,
    double? waistToHipRatio,
    required RiskBand visceralFatRisk,
    required int metabolicHealthScore,
    required int lifestyleRiskScore,
    required DateTime computedAt,
  }) = _HealthProfile;

  factory HealthProfile.fromJson(Map<String, dynamic> json) =>
      _$HealthProfileFromJson(json);
}
