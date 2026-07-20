import 'package:bodi/domain/health/health_engine.dart';
import 'package:bodi/domain/models/enums.dart';
import 'package:bodi/domain/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile profile({
  int age = 30,
  Sex sex = Sex.male,
  double heightCm = 175,
  double weightKg = 80,
  double? waistCm,
  double? hipCm,
  double? bodyFatPct,
  ActivityLevel activityLevel = ActivityLevel.sedentary,
  double sleepHours = 7.5,
  StressLevel stressLevel = StressLevel.low,
  int exerciseDaysPerWeek = 3,
  List<GoalType> goals = const [],
  List<String> medicalConditions = const [],
  double? targetWeightKg,
}) {
  final now = DateTime(2026, 7, 20);
  return UserProfile(
    id: 'test',
    age: age,
    sex: sex,
    heightCm: heightCm,
    weightKg: weightKg,
    waistCm: waistCm,
    hipCm: hipCm,
    bodyFatPct: bodyFatPct,
    activityLevel: activityLevel,
    sleepHours: sleepHours,
    stressLevel: stressLevel,
    exerciseDaysPerWeek: exerciseDaysPerWeek,
    goals: goals,
    medicalConditions: medicalConditions,
    targetWeightKg: targetWeightKg,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BMI', () {
    test('computes weight / height²', () {
      expect(HealthEngine.computeBmi(80, 175), closeTo(26.12, 0.01));
    });

    test('categorises per WHO cutoffs', () {
      expect(HealthEngine.bmiCategory(18.4), BmiCategory.underweight);
      expect(HealthEngine.bmiCategory(18.5), BmiCategory.healthy);
      expect(HealthEngine.bmiCategory(24.9), BmiCategory.healthy);
      expect(HealthEngine.bmiCategory(25.0), BmiCategory.overweight);
      expect(HealthEngine.bmiCategory(30.0), BmiCategory.obese);
    });
  });

  group('BMR (Mifflin-St Jeor)', () {
    test('male: 10w + 6.25h − 5a + 5', () {
      final bmr = HealthEngine.computeBmr(profile());
      expect(bmr, closeTo(10 * 80 + 6.25 * 175 - 5 * 30 + 5, 0.01));
    });

    test('female subtracts 161', () {
      final bmr = HealthEngine.computeBmr(profile(sex: Sex.female));
      expect(bmr, closeTo(10 * 80 + 6.25 * 175 - 5 * 30 - 161, 0.01));
    });

    test('uses Katch-McArdle when body fat is known', () {
      final bmr = HealthEngine.computeBmr(profile(), bodyFatPct: 20);
      expect(bmr, closeTo(370 + 21.6 * 80 * 0.8, 0.01));
    });
  });

  group('body fat estimate', () {
    test('uses Relative Fat Mass when waist is present', () {
      final bf = HealthEngine.estimateBodyFat(profile(waistCm: 90));
      expect(bf, closeTo(64 - 20 * (175 / 90), 0.01));
    });

    test('female RFM uses the 76 intercept', () {
      final bf = HealthEngine.estimateBodyFat(
        profile(sex: Sex.female, waistCm: 80),
      );
      expect(bf, closeTo(76 - 20 * (175 / 80), 0.01));
    });

    test('falls back to Deurenberg without waist', () {
      final bmi = HealthEngine.computeBmi(80, 175);
      final bf = HealthEngine.estimateBodyFat(profile());
      expect(bf, closeTo(1.2 * bmi + 0.23 * 30 - 10.8 - 5.4, 0.01));
    });

    test('clamps to a physiological range', () {
      final bf = HealthEngine.estimateBodyFat(
        profile(waistCm: 50, heightCm: 200),
      );
      expect(bf, greaterThanOrEqualTo(3));
    });
  });

  group('calorie target', () {
    test('fat-loss deficit is 20% capped at 500 kcal', () {
      final tdee = 2500.0;
      final target = HealthEngine.calorieTarget(
        profile(goals: [GoalType.loseFat]),
        tdee,
      );
      expect(target, 2000);

      final bigTdee = 3000.0;
      final capped = HealthEngine.calorieTarget(
        profile(goals: [GoalType.loseFat]),
        bigTdee,
      );
      expect(capped, 2500);
    });

    test('never goes below the safety floor', () {
      final target = HealthEngine.calorieTarget(
        profile(sex: Sex.female, goals: [GoalType.loseFat]),
        1300,
      );
      expect(target, 1200);
    });

    test('muscle gain adds 10% capped at 300', () {
      expect(
        HealthEngine.calorieTarget(
          profile(goals: [GoalType.buildMuscle]),
          2000,
        ),
        2200,
      );
      expect(
        HealthEngine.calorieTarget(
          profile(goals: [GoalType.buildMuscle]),
          3500,
        ),
        3800,
      );
    });

    test('a lower target weight implies a deficit even without the goal', () {
      final target = HealthEngine.calorieTarget(
        profile(targetWeightKg: 70),
        2500,
      );
      expect(target, lessThan(2500));
    });

    test('maintenance returns TDEE', () {
      expect(HealthEngine.calorieTarget(profile(), 2400), 2400);
    });
  });

  group('protein target', () {
    test('1.8 g/kg when recomposing', () {
      final target = HealthEngine.proteinTarget(
        profile(weightKg: 70, goals: [GoalType.loseFat]),
      );
      expect(target, closeTo(70 * 1.8, 0.01));
    });

    test('caps reference weight at healthy-range max', () {
      final target = HealthEngine.proteinTarget(
        profile(weightKg: 150, goals: [GoalType.loseFat]),
      );
      final healthyMax = 24.9 * 1.75 * 1.75;
      expect(target, closeTo(healthyMax * 1.8, 0.01));
    });

    test('1.2 g/kg of reference weight for maintenance', () {
      expect(
        HealthEngine.proteinTarget(profile(weightKg: 70)),
        closeTo(84, 0.01),
      );
    });
  });

  group('water target', () {
    test('35 ml per kg', () {
      expect(HealthEngine.waterTarget(70), 2450);
    });

    test('bounded between 1.5 and 4 litres', () {
      expect(HealthEngine.waterTarget(30), 1500);
      expect(HealthEngine.waterTarget(150), 4000);
    });
  });

  group('step goal', () {
    test('scales with activity and fat-loss goal, capped at 12k', () {
      expect(HealthEngine.stepGoal(profile()), 7000);
      expect(
        HealthEngine.stepGoal(profile(activityLevel: ActivityLevel.active)),
        10000,
      );
      expect(
        HealthEngine.stepGoal(
          profile(
            activityLevel: ActivityLevel.active,
            goals: [GoalType.loseFat],
          ),
        ),
        12000,
      );
    });
  });

  group('visceral risk', () {
    test('waist-to-height drives the band', () {
      expect(
        HealthEngine.compute(profile(waistCm: 80)).visceralFatRisk,
        RiskBand.low,
      );
      expect(
        HealthEngine.compute(profile(waistCm: 90)).visceralFatRisk,
        RiskBand.moderate,
      );
      expect(
        HealthEngine.compute(profile(waistCm: 106)).visceralFatRisk,
        RiskBand.high,
      );
    });
  });

  group('composite scores', () {
    test('healthy profile scores high, risky profile scores low', () {
      final healthy = HealthEngine.compute(
        profile(
          weightKg: 70,
          waistCm: 78,
          activityLevel: ActivityLevel.moderate,
          sleepHours: 8,
        ),
      );
      final risky = HealthEngine.compute(
        profile(
          weightKg: 110,
          waistCm: 112,
          sleepHours: 5,
          stressLevel: StressLevel.severe,
          exerciseDaysPerWeek: 0,
          medicalConditions: ['Hypertension', 'Diabetes'],
        ),
      );
      expect(healthy.metabolicHealthScore, greaterThanOrEqualTo(90));
      expect(risky.metabolicHealthScore, lessThan(50));
      expect(healthy.lifestyleRiskScore, lessThan(25));
      expect(risky.lifestyleRiskScore, greaterThan(60));
    });

    test('scores stay within 0–100', () {
      final extreme = HealthEngine.compute(
        profile(
          weightKg: 200,
          heightCm: 150,
          waistCm: 160,
          sleepHours: 3,
          stressLevel: StressLevel.severe,
          exerciseDaysPerWeek: 0,
          medicalConditions: [
            'diabetes',
            'hypertension',
            'high cholesterol',
            'heart disease',
          ],
        ),
      );
      expect(extreme.metabolicHealthScore, inInclusiveRange(0, 100));
      expect(extreme.lifestyleRiskScore, inInclusiveRange(0, 100));
    });
  });

  group('full profile', () {
    test('healthy weight range comes from BMI 18.5–24.9', () {
      final health = HealthEngine.compute(profile());
      expect(health.healthyWeightMinKg, closeTo(18.5 * 1.75 * 1.75, 0.1));
      expect(health.healthyWeightMaxKg, closeTo(24.9 * 1.75 * 1.75, 0.1));
    });

    test('waist-to-hip ratio only when both present', () {
      expect(HealthEngine.compute(profile()).waistToHipRatio, isNull);
      expect(
        HealthEngine.compute(profile(waistCm: 90, hipCm: 100)).waistToHipRatio,
        closeTo(0.9, 0.001),
      );
    });
  });
}
