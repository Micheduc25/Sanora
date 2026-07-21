import 'package:sanora/core/error/failures.dart';
import 'package:sanora/domain/health/insight_rules_engine.dart';
import 'package:sanora/domain/models/enums.dart';
import 'package:sanora/domain/models/health_profile.dart';
import 'package:sanora/domain/models/meal.dart';
import 'package:sanora/domain/models/metric_entry.dart';
import 'package:sanora/domain/models/nutrition.dart';
import 'package:sanora/domain/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('insight action routes', () {
    test('every action the rules engine emits resolves to a route', () {
      // The screen renders an action with no route as inert text, so an
      // unmapped label is a silently dead call-to-action.
      final now = DateTime(2026, 7, 21);
      final profile = UserProfile(
        id: 'u',
        age: 35,
        sex: Sex.male,
        heightCm: 175,
        weightKg: 95,
        activityLevel: ActivityLevel.sedentary,
        sleepHours: 5,
        stressLevel: StressLevel.high,
        exerciseDaysPerWeek: 0,
        goals: const [GoalType.loseFat],
        createdAt: now,
        updatedAt: now,
      );
      final health = HealthProfile(
        bmi: 31,
        bmiCategory: BmiCategory.obese,
        estimatedBodyFatPct: 30,
        bmr: 1800,
        tdee: 2160,
        calorieTarget: 1660,
        proteinTargetG: 140,
        waterTargetMl: 3300,
        stepGoal: 9000,
        exerciseMinutesPerWeek: 120,
        sleepGoalHours: 8,
        healthyWeightMinKg: 57,
        healthyWeightMaxKg: 76,
        visceralFatRisk: RiskBand.high,
        metabolicHealthScore: 40,
        lifestyleRiskScore: 60,
        computedAt: now,
      );

      // A week that trips as many rules as possible at once.
      final meals = <Meal>[
        for (var day = 0; day < 7; day++)
          Meal(
            id: 'm$day',
            name: 'Late jollof',
            type: MealType.dinner,
            source: MealSource.database,
            nutrition: const Nutrition(
              calories: 900,
              proteinG: 8,
              sodiumMg: 3000,
              sugarG: 60,
            ),
            eatenAt: now
                .subtract(Duration(days: day))
                .add(const Duration(hours: 23)),
          ),
      ];
      final metrics = <MetricEntry>[
        for (var day = 0; day < 7; day++)
          MetricEntry(
            id: 's$day',
            type: MetricType.sleep,
            value: 4.5,
            recordedAt: now.subtract(Duration(days: day)),
          ),
      ];

      final insights = InsightRulesEngine.generate(
        profile: profile,
        health: health,
        meals: meals,
        metrics: metrics,
        now: now,
      );

      expect(insights, isNotEmpty);
      for (final insight in insights.where((i) => i.action.isNotEmpty)) {
        expect(
          insight.actionRoute,
          isNotEmpty,
          reason:
              'Action "${insight.action}" has no route, so it renders as '
              'dead text. Add it to InsightRulesEngine.routeForAction.',
        );
      }
    });

    test('an unknown action maps to no route rather than a wrong one', () {
      expect(InsightRulesEngine.routeForAction('Do something else'), '');
      expect(InsightRulesEngine.routeForAction(''), '');
    });
  });

  group('messageFor', () {
    test('surfaces a failure message verbatim', () {
      expect(messageFor(const QuotaFailure('Out of calls.')), 'Out of calls.');
    });

    test('never leaks a raw exception to the user', () {
      final shown = messageFor(StateError('bad state: internal detail'));

      expect(shown, 'Something went wrong. Please try again.');
      expect(shown, isNot(contains('internal detail')));
    });
  });
}
