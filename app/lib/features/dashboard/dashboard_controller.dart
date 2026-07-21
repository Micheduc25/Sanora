import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/health/daily_score_engine.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/health_profile.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/nutrition.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/onboarding_controller.dart';

class DashboardData {
  const DashboardData({
    required this.score,
    required this.health,
    required this.todayNutrition,
    required this.waterMl,
    required this.steps,
    required this.activeCalories,
    required this.heartRate,
    required this.sleepHours,
    required this.weightNow,
    required this.weightWeekDelta,
    required this.waistNow,
    required this.waistMonthDelta,
    required this.habitsDue,
    required this.habitsDone,
    required this.topInsight,
    required this.mealCount,
  });

  final DailyScore score;
  final HealthProfile health;
  final Nutrition todayNutrition;
  final double waterMl;
  final int steps;
  final double activeCalories;
  final double? heartRate;
  final double? sleepHours;
  final double? weightNow;
  final double? weightWeekDelta;
  final double? waistNow;
  final double? waistMonthDelta;
  final List<Habit> habitsDue;
  final int habitsDone;
  final Insight? topInsight;
  final int mealCount;
}

/// Whether Apple Health / Health Connect has granted the types Bodi reads.
/// Drives the connect prompt — without it the platform tiles sit empty and
/// the user is never told why.
final activityConnectedProvider = FutureProvider<bool>(
  (ref) => ref.watch(activityServiceProvider).isConnected(),
);

/// Assembles everything the dashboard needs in one pass. Platform activity
/// (steps, heart rate, sleep) merges with manual logs, taking the larger of
/// the two step counts so users without a wearable still see progress.
final dashboardProvider = FutureProvider.autoDispose<DashboardData?>((
  ref,
) async {
  final health = ref.watch(healthProfileProvider);
  if (health == null) return null;

  final today = DateTime.now();
  final metrics = ref.watch(metricsRepositoryProvider);
  final meals = ref.watch(mealsRepositoryProvider);
  final habits = ref.watch(habitsRepositoryProvider);
  final insights = ref.watch(insightsRepositoryProvider);
  final activity = ref.watch(activityServiceProvider);

  final platformSteps = await activity.stepsToday();
  final manualSteps = metrics.dayTotal(MetricType.steps, today).round();
  final steps = platformSteps > manualSteps ? platformSteps : manualSteps;

  final activeCalories = await activity.activeCaloriesToday();
  final heartRate =
      await activity.latestHeartRate() ??
      metrics.latest(MetricType.heartRate)?.value;

  final sleepEntry = metrics
      .forDay(today)
      .where((m) => m.type == MetricType.sleep)
      .firstOrNull;
  final sleepHours = sleepEntry?.value ?? await activity.sleepHoursLastNight();

  final todayNutrition = meals.dayNutrition(today);
  final waterMl = metrics.dayTotal(MetricType.water, today);

  final weights = metrics.byType(MetricType.weight);
  final weightNow = weights.firstOrNull?.value;
  double? weightWeekDelta;
  if (weightNow != null) {
    final weekAgo = weights
        .where(
          (w) =>
              today.difference(w.recordedAt).inDays >= 6 &&
              today.difference(w.recordedAt).inDays <= 10,
        )
        .firstOrNull;
    if (weekAgo != null) weightWeekDelta = weightNow - weekAgo.value;
  }

  final waists = metrics.byType(MetricType.waist);
  final waistNow = waists.firstOrNull?.value;
  double? waistMonthDelta;
  if (waistNow != null) {
    final monthAgo = waists
        .where((w) => today.difference(w.recordedAt).inDays >= 21)
        .firstOrNull;
    if (monthAgo != null) waistMonthDelta = waistNow - monthAgo.value;
  }

  final habitsDue = habits.activeForDay(today);
  final habitsDone = habitsDue
      .where((h) => habits.isDoneForDay(h, today))
      .length;

  final score = DailyScoreEngine.compute(
    DailyScoreInput(
      steps: steps,
      stepGoal: health.stepGoal,
      waterMl: waterMl,
      waterGoalMl: health.waterTargetMl,
      proteinG: todayNutrition.proteinG,
      proteinGoalG: health.proteinTargetG,
      calories: todayNutrition.calories,
      calorieTarget: health.calorieTarget,
      sleepHours: sleepHours,
      sleepGoalHours: health.sleepGoalHours,
      habitsCompleted: habitsDone,
      habitsTotal: habitsDue.length,
    ),
  );

  final unread = insights.all().where((i) => !i.read).toList();

  return DashboardData(
    score: score,
    health: health,
    todayNutrition: todayNutrition,
    waterMl: waterMl,
    steps: steps,
    activeCalories: activeCalories,
    heartRate: heartRate,
    sleepHours: sleepHours,
    weightNow: weightNow,
    weightWeekDelta: weightWeekDelta,
    waistNow: waistNow,
    waistMonthDelta: waistMonthDelta,
    habitsDue: habitsDue,
    habitsDone: habitsDone,
    topInsight: unread.firstOrNull,
    mealCount: meals.forDay(today).length,
  );
});

/// Greetings are whole sentences per locale rather than a greeting glued to a
/// name — French punctuates and orders the two differently.
String greetingFor(L l, DateTime now, String name) {
  if (now.hour < 12) {
    return name.isEmpty
        ? l.dashboardGreetingMorning
        : l.dashboardGreetingMorningNamed(name);
  }
  if (now.hour < 18) {
    return name.isEmpty
        ? l.dashboardGreetingAfternoon
        : l.dashboardGreetingAfternoonNamed(name);
  }
  return name.isEmpty
      ? l.dashboardGreetingEvening
      : l.dashboardGreetingEveningNamed(name);
}
