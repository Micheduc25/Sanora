import 'package:uuid/uuid.dart';

import '../../core/utils/extensions.dart';
import '../models/enums.dart';
import '../models/health_profile.dart';
import '../models/insight.dart';
import '../models/meal.dart';
import '../models/metric_entry.dart';
import '../models/user_profile.dart';

/// Deterministic, on-device insight generation. Runs daily over the last
/// 7–14 days of local data; the AI insights edge function complements these
/// with free-form pattern analysis when online.
abstract final class InsightRulesEngine {
  static List<Insight> generate({
    required UserProfile profile,
    required HealthProfile health,
    required List<Meal> meals,
    required List<MetricEntry> metrics,
    DateTime? now,
  }) {
    final today = (now ?? DateTime.now()).dateOnly;
    final insights = <Insight>[];
    final weekMeals = meals
        .where((m) => today.difference(m.eatenAt.dateOnly).inDays < 7)
        .toList();

    void add(
      String title,
      String body,
      InsightSeverity severity, [
      String action = '',
    ]) {
      insights.add(
        Insight(
          id: const Uuid().v4(),
          title: title,
          body: body,
          severity: severity,
          action: action,
          actionRoute: routeForAction(action),
          createdAt: now ?? DateTime.now(),
        ),
      );
    }

    _weightTrend(metrics, today, add);
    _lateNightEating(weekMeals, add);
    _proteinGap(weekMeals, health, add);
    _sodiumLoad(weekMeals, add);
    _sugarLoad(weekMeals, add);
    _weekendPattern(meals, today, add);
    _sleepPattern(metrics, today, add);
    _hydration(metrics, health, today, add);

    return insights;
  }

  /// Maps a call-to-action label onto the screen that actually performs it.
  /// Kept beside the rules so adding a new action without somewhere to send
  /// the user is an obvious omission rather than a dead label.
  static String routeForAction(String action) => switch (action) {
    'Review recent meals' => '/meals',
    'See high-protein foods' => '/meals/log',
    'Set a dinner reminder' => '/reminders',
    'Set a sleep reminder' => '/reminders',
    'Enable water reminders' => '/reminders',
    'Log your weight' => '/health/log?type=weight',
    _ => '',
  };

  static void _weightTrend(
    List<MetricEntry> metrics,
    DateTime today,
    void Function(String, String, InsightSeverity, [String]) add,
  ) {
    final weights =
        metrics
            .where(
              (m) =>
                  m.type == MetricType.weight &&
                  today.difference(m.recordedAt.dateOnly).inDays <= 14,
            )
            .toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (weights.length < 3) return;
    final delta = weights.last.value - weights.first.value;
    final days = weights.last.recordedAt
        .difference(weights.first.recordedAt)
        .inDays
        .clamp(1, 14);
    final weekly = delta / days * 7;
    if (weekly <= -0.25) {
      add(
        'Weight is trending down',
        'You are losing about ${weekly.abs().toStringAsFixed(1)} kg per week. That is a sustainable pace — keep doing what you are doing.',
        InsightSeverity.celebrate,
      );
    } else if (weekly >= 0.4) {
      add(
        'Weight is trending up',
        'You have gained about ${weekly.toStringAsFixed(1)} kg per week over the last ${days.round()} days. A look at portion sizes and evening snacks usually explains most of it.',
        InsightSeverity.warning,
        'Review recent meals',
      );
    }
  }

  static void _lateNightEating(
    List<Meal> weekMeals,
    void Function(String, String, InsightSeverity, [String]) add,
  ) {
    final late = weekMeals.where((m) => m.eatenAt.hour >= 22).length;
    if (late >= 3) {
      add(
        'Late-night eating pattern',
        'You ate after 22:00 on $late of the last 7 days. Late meals are linked to poorer sleep and higher morning glucose — try moving dinner 1–2 hours earlier.',
        InsightSeverity.nudge,
        'Set a dinner reminder',
      );
    }
  }

  static void _proteinGap(
    List<Meal> weekMeals,
    HealthProfile health,
    void Function(String, String, InsightSeverity, [String]) add,
  ) {
    if (weekMeals.isEmpty) return;
    final days = weekMeals.map((m) => m.eatenAt.dayKey).toSet().length;
    final avgProtein =
        weekMeals.fold(0.0, (s, m) => s + m.nutrition.proteinG) / days;
    if (avgProtein < health.proteinTargetG * 0.7) {
      add(
        'Protein is below your target',
        'You are averaging ${avgProtein.round()} g of protein a day against a target of ${health.proteinTargetG.round()} g. Protein protects muscle while losing fat — add eggs, beans, fish or lean meat to one more meal.',
        InsightSeverity.nudge,
        'See high-protein foods',
      );
    }
  }

  static void _sodiumLoad(
    List<Meal> weekMeals,
    void Function(String, String, InsightSeverity, [String]) add,
  ) {
    if (weekMeals.isEmpty) return;
    final days = weekMeals.map((m) => m.eatenAt.dayKey).toSet().length;
    final avgSodium =
        weekMeals.fold(0.0, (s, m) => s + m.nutrition.sodiumMg) / days;
    if (avgSodium > 2300) {
      add(
        'High sodium this week',
        'Your meals averaged ${avgSodium.round()} mg of sodium a day — above the 2,300 mg guideline. High sodium can nudge blood pressure and water retention; stock cubes and processed sauces are the usual sources.',
        InsightSeverity.warning,
      );
    }
  }

  static void _sugarLoad(
    List<Meal> weekMeals,
    void Function(String, String, InsightSeverity, [String]) add,
  ) {
    if (weekMeals.isEmpty) return;
    final days = weekMeals.map((m) => m.eatenAt.dayKey).toSet().length;
    final avgSugar =
        weekMeals.fold(0.0, (s, m) => s + m.nutrition.sugarG) / days;
    if (avgSugar > 50) {
      add(
        'Sugar is adding up',
        'You are averaging ${avgSugar.round()} g of sugar a day. Sugary drinks are usually the biggest single source — swapping one for water saves roughly 100 kcal a day.',
        InsightSeverity.nudge,
      );
    }
  }

  static void _weekendPattern(
    List<Meal> meals,
    DateTime today,
    void Function(String, String, InsightSeverity, [String]) add,
  ) {
    final recent = meals
        .where((m) => today.difference(m.eatenAt.dateOnly).inDays < 28)
        .toList();
    if (recent.length < 10) return;
    double avgFor(bool weekend) {
      final byDay = <String, double>{};
      for (final m in recent) {
        final isWeekend = m.eatenAt.weekday >= 6;
        if (isWeekend != weekend) continue;
        byDay[m.eatenAt.dayKey] =
            (byDay[m.eatenAt.dayKey] ?? 0) + m.nutrition.calories;
      }
      if (byDay.isEmpty) return 0;
      return byDay.values.reduce((a, b) => a + b) / byDay.length;
    }

    final weekdayAvg = avgFor(false);
    final weekendAvg = avgFor(true);
    if (weekdayAvg > 0 && weekendAvg > weekdayAvg * 1.3) {
      final extra = (weekendAvg - weekdayAvg).round();
      add(
        'Weekends run higher',
        'You eat about $extra kcal more on weekend days than weekdays. One planned treat instead of an open-ended weekend keeps progress without giving up enjoyment.',
        InsightSeverity.info,
      );
    }
  }

  static void _sleepPattern(
    List<MetricEntry> metrics,
    DateTime today,
    void Function(String, String, InsightSeverity, [String]) add,
  ) {
    final sleep = metrics
        .where(
          (m) =>
              m.type == MetricType.sleep &&
              today.difference(m.recordedAt.dateOnly).inDays < 7,
        )
        .toList();
    if (sleep.length < 3) return;
    final avg = sleep.fold(0.0, (s, m) => s + m.value) / sleep.length;
    if (avg < 6.5) {
      add(
        'Sleep debt is building',
        'You averaged ${avg.toStringAsFixed(1)} hours of sleep this week. Short sleep raises hunger hormones the next day — protecting a wind-down time is the single highest-leverage change.',
        InsightSeverity.warning,
        'Set a sleep reminder',
      );
    } else if (avg >= 7.5) {
      add(
        'Great sleep this week',
        'You averaged ${avg.toStringAsFixed(1)} hours — right in the recovery zone. Good sleep makes every other goal easier.',
        InsightSeverity.celebrate,
      );
    }
  }

  static void _hydration(
    List<MetricEntry> metrics,
    HealthProfile health,
    DateTime today,
    void Function(String, String, InsightSeverity, [String]) add,
  ) {
    final water = metrics
        .where(
          (m) =>
              m.type == MetricType.water &&
              today.difference(m.recordedAt.dateOnly).inDays < 7,
        )
        .toList();
    if (water.isEmpty) return;
    final byDay = <String, double>{};
    for (final w in water) {
      byDay[w.recordedAt.dayKey] = (byDay[w.recordedAt.dayKey] ?? 0) + w.value;
    }
    final avg = byDay.values.reduce((a, b) => a + b) / byDay.length;
    if (avg < health.waterTargetMl * 0.6) {
      add(
        'Hydration is low',
        'You are drinking about ${(avg / 1000).toStringAsFixed(1)} L a day against a ${(health.waterTargetMl / 1000).toStringAsFixed(1)} L target. A bottle on your desk beats willpower.',
        InsightSeverity.nudge,
        'Enable water reminders',
      );
    }
  }
}
