import 'package:flutter/widgets.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/reminder.dart';
import '../../l10n/app_localizations.dart';

/// Localized display names for the domain enums.
///
/// The enums keep their English `label` fields because `domain/` is pure Dart
/// with no Flutter dependency — that rule is what makes the health engines
/// testable without a widget binding. Translation therefore belongs here, at
/// the UI boundary, and the raw `.label` should never reach a screen.
extension SexL10n on Sex {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      Sex.male => l.sexMale,
      Sex.female => l.sexFemale,
      Sex.other => l.sexOther,
    };
  }
}

extension ActivityLevelL10n on ActivityLevel {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      ActivityLevel.sedentary => l.activitySedentary,
      ActivityLevel.light => l.activityLight,
      ActivityLevel.moderate => l.activityModerate,
      ActivityLevel.active => l.activityActive,
      ActivityLevel.athlete => l.activityAthlete,
    };
  }

  String descriptionOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      ActivityLevel.sedentary => l.activitySedentaryDesc,
      ActivityLevel.light => l.activityLightDesc,
      ActivityLevel.moderate => l.activityModerateDesc,
      ActivityLevel.active => l.activityActiveDesc,
      ActivityLevel.athlete => l.activityAthleteDesc,
    };
  }
}

extension StressLevelL10n on StressLevel {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      StressLevel.low => l.stressLow,
      StressLevel.moderate => l.stressModerate,
      StressLevel.high => l.stressHigh,
      StressLevel.severe => l.stressSevere,
    };
  }

  String descriptionOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      StressLevel.low => l.stressLowDesc,
      StressLevel.moderate => l.stressModerateDesc,
      StressLevel.high => l.stressHighDesc,
      StressLevel.severe => l.stressSevereDesc,
    };
  }
}

extension GoalTypeL10n on GoalType {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      GoalType.loseFat => l.goalLoseFat,
      GoalType.buildMuscle => l.goalBuildMuscle,
      GoalType.improveEnergy => l.goalImproveEnergy,
      GoalType.eatHealthier => l.goalEatHealthier,
      GoalType.sleepBetter => l.goalSleepBetter,
      GoalType.reduceStress => l.goalReduceStress,
      GoalType.preventDisease => l.goalPreventDisease,
      GoalType.liveLonger => l.goalLiveLonger,
    };
  }
}

extension MetricTypeL10n on MetricType {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      MetricType.weight => l.metricWeight,
      MetricType.waist => l.metricWaist,
      MetricType.hip => l.metricHip,
      MetricType.bodyFat => l.metricBodyFat,
      MetricType.bpSystolic => l.metricBpSystolic,
      MetricType.bpDiastolic => l.metricBpDiastolic,
      MetricType.bloodSugar => l.metricBloodSugar,
      MetricType.heartRate => l.metricHeartRate,
      MetricType.sleep => l.metricSleep,
      MetricType.mood => l.metricMood,
      MetricType.stress => l.metricStress,
      MetricType.energy => l.metricEnergy,
      MetricType.water => l.metricWater,
      MetricType.steps => l.metricSteps,
      MetricType.symptom => l.metricSymptom,
      MetricType.medication => l.metricMedication,
    };
  }
}

extension MealTypeL10n on MealType {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      MealType.breakfast => l.mealBreakfast,
      MealType.lunch => l.mealLunch,
      MealType.dinner => l.mealDinner,
      MealType.snack => l.mealSnack,
    };
  }
}

extension RiskBandL10n on RiskBand {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      RiskBand.low => l.riskLow,
      RiskBand.moderate => l.riskModerate,
      RiskBand.elevated => l.riskElevated,
      RiskBand.high => l.riskHigh,
    };
  }
}

extension BmiCategoryL10n on BmiCategory {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      BmiCategory.underweight => l.bmiUnderweight,
      BmiCategory.healthy => l.bmiHealthy,
      BmiCategory.overweight => l.bmiOverweight,
      BmiCategory.obese => l.bmiObese,
    };
  }
}

extension WorkoutCategoryL10n on WorkoutCategory {
  String labelOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      WorkoutCategory.home => l.workoutHome,
      WorkoutCategory.gym => l.workoutGym,
      WorkoutCategory.office => l.workoutOffice,
      WorkoutCategory.walking => l.workoutWalking,
      WorkoutCategory.running => l.workoutRunning,
      WorkoutCategory.mobility => l.workoutMobility,
      WorkoutCategory.stretching => l.workoutStretching,
      WorkoutCategory.strength => l.workoutStrength,
      WorkoutCategory.hiit => l.workoutHiit,
      WorkoutCategory.yoga => l.workoutYoga,
    };
  }
}

extension ReminderKindL10n on ReminderKind {
  String titleOf(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      ReminderKind.water => l.reminderWater,
      ReminderKind.stand => l.reminderStand,
      ReminderKind.meal => l.reminderMeal,
      ReminderKind.exercise => l.reminderExercise,
      ReminderKind.medication => l.reminderMedication,
      ReminderKind.sleep => l.reminderSleep,
      ReminderKind.walk => l.reminderWalk,
      ReminderKind.custom => l.reminderCustom,
    };
  }
}
