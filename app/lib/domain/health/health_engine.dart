import 'dart:math' as math;

import '../models/enums.dart';
import '../models/health_profile.dart';
import '../models/user_profile.dart';

/// Pure, deterministic health calculations. Formula sources:
/// BMI/healthy range per WHO; BMR per Mifflin-St Jeor (Katch-McArdle when
/// body fat is known); body fat estimate per Relative Fat Mass (Woolcott
/// 2018), falling back to Deurenberg; visceral risk per WHO waist-to-height
/// and waist-to-hip cutoffs.
abstract final class HealthEngine {
  static HealthProfile compute(UserProfile u, {DateTime? now}) {
    final bmi = computeBmi(u.weightKg, u.heightCm);
    final bodyFat = u.bodyFatPct ?? estimateBodyFat(u);
    final bmr = computeBmr(u, bodyFatPct: u.bodyFatPct);
    final tdee = bmr * u.activityLevel.multiplier;
    final wthr = u.waistCm == null ? null : u.waistCm! / u.heightCm;
    final whr = (u.waistCm != null && u.hipCm != null && u.hipCm! > 0)
        ? u.waistCm! / u.hipCm!
        : null;

    return HealthProfile(
      bmi: _round1(bmi),
      bmiCategory: bmiCategory(bmi),
      estimatedBodyFatPct: _round1(bodyFat),
      bmr: bmr.roundToDouble(),
      tdee: tdee.roundToDouble(),
      calorieTarget: calorieTarget(u, tdee).roundToDouble(),
      proteinTargetG: proteinTarget(u).roundToDouble(),
      waterTargetMl: waterTarget(u.weightKg).roundToDouble(),
      stepGoal: stepGoal(u),
      exerciseMinutesPerWeek: 150,
      sleepGoalHours: sleepGoal(u.age),
      healthyWeightMinKg: _round1(18.5 * _heightM2(u.heightCm)),
      healthyWeightMaxKg: _round1(24.9 * _heightM2(u.heightCm)),
      waistToHeightRatio: wthr == null ? null : _round2(wthr),
      waistToHipRatio: whr == null ? null : _round2(whr),
      visceralFatRisk: visceralRisk(u, wthr: wthr, whr: whr),
      metabolicHealthScore: metabolicScore(u, bmi: bmi, wthr: wthr),
      lifestyleRiskScore: lifestyleRisk(u),
      computedAt: now ?? DateTime.now(),
    );
  }

  static double computeBmi(double weightKg, double heightCm) =>
      weightKg / _heightM2(heightCm);

  static BmiCategory bmiCategory(double bmi) {
    if (bmi < 18.5) return BmiCategory.underweight;
    if (bmi < 25) return BmiCategory.healthy;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  /// Relative Fat Mass when waist is available, Deurenberg otherwise.
  /// [Sex.other] uses the midpoint of the male and female equations.
  static double estimateBodyFat(UserProfile u) {
    double forSex(Sex sex) {
      if (u.waistCm != null && u.waistCm! > 0) {
        final ratio = u.heightCm / u.waistCm!;
        return switch (sex) {
          Sex.male => 64 - 20 * ratio,
          Sex.female => 76 - 20 * ratio,
          Sex.other => 70 - 20 * ratio,
        };
      }
      final bmi = computeBmi(u.weightKg, u.heightCm);
      final sexTerm = switch (sex) {
        Sex.male => 1.0,
        Sex.female => 0.0,
        Sex.other => 0.5,
      };
      return 1.2 * bmi + 0.23 * u.age - 10.8 * sexTerm - 5.4;
    }

    return forSex(u.sex).clamp(3.0, 60.0);
  }

  static double computeBmr(UserProfile u, {double? bodyFatPct}) {
    if (bodyFatPct != null && bodyFatPct > 0) {
      final leanMassKg = u.weightKg * (1 - bodyFatPct / 100);
      return 370 + 21.6 * leanMassKg;
    }
    final base = 10 * u.weightKg + 6.25 * u.heightCm - 5 * u.age;
    return switch (u.sex) {
      Sex.male => base + 5,
      Sex.female => base - 161,
      Sex.other => base - 78,
    };
  }

  /// Sustainable deficit/surplus: −20% capped at −500 kcal for fat loss
  /// (never below a safe floor), +10% capped at +300 kcal for muscle gain.
  static double calorieTarget(UserProfile u, double tdee) {
    final losing = u.goals.contains(GoalType.loseFat) ||
        (u.targetWeightKg != null && u.targetWeightKg! < u.weightKg - 1);
    final gaining = !losing &&
        (u.goals.contains(GoalType.buildMuscle) ||
            (u.targetWeightKg != null && u.targetWeightKg! > u.weightKg + 1));
    if (losing) {
      final floor = u.sex == Sex.female ? 1200.0 : 1500.0;
      return math.max(tdee - math.min(tdee * 0.20, 500), floor);
    }
    if (gaining) return tdee + math.min(tdee * 0.10, 300);
    return tdee;
  }

  /// g/kg of reference weight: 1.8 when recomposing (fat loss or muscle
  /// gain), 1.2 for maintenance. Reference weight avoids over-prescribing
  /// for high body weights by using the healthy-range max when above it.
  static double proteinTarget(UserProfile u) {
    final healthyMax = 24.9 * _heightM2(u.heightCm);
    final referenceKg = math.min(u.weightKg, healthyMax);
    final recomposing = u.goals.contains(GoalType.loseFat) ||
        u.goals.contains(GoalType.buildMuscle);
    return referenceKg * (recomposing ? 1.8 : 1.2);
  }

  /// 35 ml/kg bounded to a practical 1.5–4 L range.
  static double waterTarget(double weightKg) =>
      (weightKg * 35).clamp(1500.0, 4000.0);

  static int stepGoal(UserProfile u) {
    var goal = switch (u.activityLevel) {
      ActivityLevel.sedentary => 7000,
      ActivityLevel.light => 8000,
      ActivityLevel.moderate => 9000,
      ActivityLevel.active || ActivityLevel.athlete => 10000,
    };
    if (u.goals.contains(GoalType.loseFat)) goal += 2000;
    return math.min(goal, 12000);
  }

  static double sleepGoal(int age) => age >= 65 ? 7.5 : 8.0;

  static RiskBand visceralRisk(UserProfile u, {double? wthr, double? whr}) {
    if (wthr != null) {
      if (wthr >= 0.6) return RiskBand.high;
      if (wthr >= 0.55) return RiskBand.elevated;
      if (wthr >= 0.5) return RiskBand.moderate;
      return RiskBand.low;
    }
    if (whr != null) {
      final cutoff = u.sex == Sex.female ? 0.85 : 0.90;
      if (whr >= cutoff + 0.05) return RiskBand.high;
      if (whr >= cutoff) return RiskBand.elevated;
      return RiskBand.low;
    }
    final bmi = computeBmi(u.weightKg, u.heightCm);
    if (bmi >= 30) return RiskBand.elevated;
    if (bmi >= 25) return RiskBand.moderate;
    return RiskBand.low;
  }

  /// 0–100. Starts at 100 and subtracts weighted penalties for BMI band,
  /// central adiposity, inactivity, short sleep and diagnosed conditions.
  static int metabolicScore(UserProfile u, {double? bmi, double? wthr}) {
    final b = bmi ?? computeBmi(u.weightKg, u.heightCm);
    var score = 100.0;

    score -= switch (bmiCategory(b)) {
      BmiCategory.healthy => 0,
      BmiCategory.underweight => 10,
      BmiCategory.overweight => 12,
      BmiCategory.obese => 25,
    };

    if (wthr != null) {
      if (wthr >= 0.6) {
        score -= 20;
      } else if (wthr >= 0.55) {
        score -= 12;
      } else if (wthr >= 0.5) {
        score -= 6;
      }
    }

    score -= switch (u.activityLevel) {
      ActivityLevel.sedentary => 12,
      ActivityLevel.light => 6,
      _ => 0,
    };

    if (u.sleepHours < 6) {
      score -= 10;
    } else if (u.sleepHours < 7) {
      score -= 5;
    }

    const metabolicConditions = [
      'diabetes',
      'prediabetes',
      'hypertension',
      'high blood pressure',
      'high cholesterol',
      'heart disease',
      'fatty liver',
    ];
    final diagnosed = u.medicalConditions
        .where((c) =>
            metabolicConditions.any((m) => c.toLowerCase().contains(m)))
        .length;
    score -= math.min(diagnosed * 8, 20);

    return score.clamp(0, 100).round();
  }

  /// 0–100 where higher means more lifestyle risk.
  static int lifestyleRisk(UserProfile u) {
    var risk = 0.0;

    risk += switch (u.stressLevel) {
      StressLevel.low => 0,
      StressLevel.moderate => 8,
      StressLevel.high => 18,
      StressLevel.severe => 28,
    };

    if (u.sleepHours < 5.5) {
      risk += 22;
    } else if (u.sleepHours < 6.5) {
      risk += 14;
    } else if (u.sleepHours < 7) {
      risk += 7;
    }

    risk += switch (u.activityLevel) {
      ActivityLevel.sedentary => 20,
      ActivityLevel.light => 10,
      ActivityLevel.moderate => 4,
      _ => 0,
    };

    if (u.exerciseDaysPerWeek == 0) {
      risk += 12;
    } else if (u.exerciseDaysPerWeek < 3) {
      risk += 6;
    }

    risk += math.min(u.medicalConditions.length * 6, 18);

    return risk.clamp(0, 100).round();
  }

  static double _heightM2(double heightCm) {
    final m = heightCm / 100;
    return m * m;
  }

  static double _round1(double v) => (v * 10).round() / 10;
  static double _round2(double v) => (v * 100).round() / 100;
}
