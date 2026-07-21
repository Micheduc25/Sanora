import 'package:sanora/domain/health/health_engine.dart';
import 'package:sanora/domain/health/insight_rules_engine.dart';
import 'package:sanora/domain/models/enums.dart';
import 'package:sanora/domain/models/insight.dart';
import 'package:sanora/domain/models/meal.dart';
import 'package:sanora/domain/models/metric_entry.dart';
import 'package:sanora/domain/models/nutrition.dart';
import 'package:sanora/domain/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 7, 20, 12);

UserProfile get profile => UserProfile(
  id: 'test',
  age: 30,
  sex: Sex.male,
  heightCm: 175,
  weightKg: 80,
  createdAt: now,
  updatedAt: now,
);

Meal meal(
  DateTime eatenAt, {
  double calories = 600,
  double proteinG = 25,
  double sodiumMg = 400,
  double sugarG = 10,
}) => Meal(
  id: '${eatenAt.microsecondsSinceEpoch}',
  name: 'Test meal',
  type: MealType.dinner,
  source: MealSource.database,
  nutrition: Nutrition(
    calories: calories,
    proteinG: proteinG,
    sodiumMg: sodiumMg,
    sugarG: sugarG,
  ),
  eatenAt: eatenAt,
);

MetricEntry metric(MetricType type, double value, DateTime at) => MetricEntry(
  id: '${type.name}-${at.microsecondsSinceEpoch}',
  type: type,
  value: value,
  recordedAt: at,
);

List<Insight> generate({
  List<Meal> meals = const [],
  List<MetricEntry> metrics = const [],
}) => InsightRulesEngine.generate(
  profile: profile,
  health: HealthEngine.compute(profile, now: now),
  meals: meals,
  metrics: metrics,
  now: now,
);

void main() {
  test('no data produces no insights', () {
    expect(generate(), isEmpty);
  });

  test('flags late-night eating after three late meals in a week', () {
    final meals = [
      for (var i = 1; i <= 3; i++) meal(DateTime(2026, 7, 20 - i, 22, 30)),
    ];
    final insights = generate(meals: meals);
    expect(insights.map((i) => i.title), contains('Late-night eating pattern'));
  });

  test('flags low protein against the personal target', () {
    final meals = [
      for (var i = 0; i < 5; i++)
        meal(DateTime(2026, 7, 19 - i, 13), proteinG: 30),
    ];
    final insights = generate(meals: meals);
    expect(
      insights.map((i) => i.title),
      contains('Protein is below your target'),
    );
  });

  test('celebrates a sustainable downward weight trend', () {
    final metrics = [
      metric(MetricType.weight, 80.0, DateTime(2026, 7, 13, 8)),
      metric(MetricType.weight, 79.6, DateTime(2026, 7, 16, 8)),
      metric(MetricType.weight, 79.2, DateTime(2026, 7, 19, 8)),
    ];
    final insights = generate(metrics: metrics);
    final trend = insights.firstWhere(
      (i) => i.title == 'Weight is trending down',
    );
    expect(trend.severity, InsightSeverity.celebrate);
  });

  test('warns on a fast upward weight trend', () {
    final metrics = [
      metric(MetricType.weight, 80.0, DateTime(2026, 7, 13, 8)),
      metric(MetricType.weight, 80.6, DateTime(2026, 7, 16, 8)),
      metric(MetricType.weight, 81.2, DateTime(2026, 7, 19, 8)),
    ];
    final insights = generate(metrics: metrics);
    final trend = insights.firstWhere(
      (i) => i.title == 'Weight is trending up',
    );
    expect(trend.severity, InsightSeverity.warning);
  });

  test('flags high average sodium', () {
    final meals = [
      for (var i = 0; i < 4; i++)
        meal(DateTime(2026, 7, 19 - i, 13), sodiumMg: 2800),
    ];
    expect(
      generate(meals: meals).map((i) => i.title),
      contains('High sodium this week'),
    );
  });

  test('warns when sleep debt builds', () {
    final metrics = [
      for (var i = 1; i <= 4; i++)
        metric(MetricType.sleep, 5.5, DateTime(2026, 7, 20 - i, 8)),
    ];
    expect(
      generate(metrics: metrics).map((i) => i.title),
      contains('Sleep debt is building'),
    );
  });
}
