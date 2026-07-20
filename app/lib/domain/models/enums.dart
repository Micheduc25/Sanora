import 'package:json_annotation/json_annotation.dart';

enum Sex {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('other')
  other;

  String get label => switch (this) {
        Sex.male => 'Male',
        Sex.female => 'Female',
        Sex.other => 'Other',
      };
}

enum ActivityLevel {
  @JsonValue('sedentary')
  sedentary(1.2, 'Sedentary', 'Desk job, little movement'),
  @JsonValue('light')
  light(1.375, 'Lightly active', 'Walks or light exercise 1–3 days/week'),
  @JsonValue('moderate')
  moderate(1.55, 'Moderately active', 'Exercise 3–5 days/week'),
  @JsonValue('active')
  active(1.725, 'Very active', 'Hard exercise 6–7 days/week'),
  @JsonValue('athlete')
  athlete(1.9, 'Athlete', 'Physical job or twice-daily training');

  const ActivityLevel(this.multiplier, this.label, this.description);
  final double multiplier;
  final String label;
  final String description;
}

enum StressLevel {
  @JsonValue('low')
  low('Low', 'Mostly calm'),
  @JsonValue('moderate')
  moderate('Moderate', 'Some stressful days'),
  @JsonValue('high')
  high('High', 'Often stressed'),
  @JsonValue('severe')
  severe('Severe', 'Overwhelmed most days');

  const StressLevel(this.label, this.description);
  final String label;
  final String description;
}

enum GoalType {
  @JsonValue('lose_fat')
  loseFat('Lose fat', '🔥'),
  @JsonValue('build_muscle')
  buildMuscle('Build muscle', '💪'),
  @JsonValue('improve_energy')
  improveEnergy('Improve energy', '⚡'),
  @JsonValue('eat_healthier')
  eatHealthier('Eat healthier', '🥗'),
  @JsonValue('sleep_better')
  sleepBetter('Sleep better', '😴'),
  @JsonValue('reduce_stress')
  reduceStress('Reduce stress', '🧘'),
  @JsonValue('prevent_disease')
  preventDisease('Prevent disease', '🛡️'),
  @JsonValue('live_longer')
  liveLonger('Live longer', '🌱');

  const GoalType(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum MetricType {
  @JsonValue('weight')
  weight('Weight', 'kg'),
  @JsonValue('waist')
  waist('Waist', 'cm'),
  @JsonValue('hip')
  hip('Hip', 'cm'),
  @JsonValue('body_fat')
  bodyFat('Body fat', '%'),
  @JsonValue('blood_pressure_systolic')
  bpSystolic('Blood pressure (sys)', 'mmHg'),
  @JsonValue('blood_pressure_diastolic')
  bpDiastolic('Blood pressure (dia)', 'mmHg'),
  @JsonValue('blood_sugar')
  bloodSugar('Blood sugar', 'mg/dL'),
  @JsonValue('heart_rate')
  heartRate('Resting heart rate', 'bpm'),
  @JsonValue('sleep')
  sleep('Sleep', 'h'),
  @JsonValue('mood')
  mood('Mood', '/5'),
  @JsonValue('stress')
  stress('Stress', '/5'),
  @JsonValue('energy')
  energy('Energy', '/5'),
  @JsonValue('water')
  water('Water', 'ml'),
  @JsonValue('steps')
  steps('Steps', 'steps'),
  @JsonValue('symptom')
  symptom('Symptom', ''),
  @JsonValue('medication')
  medication('Medication', '');

  const MetricType(this.label, this.unit);
  final String label;
  final String unit;
}

enum MealType {
  @JsonValue('breakfast')
  breakfast('Breakfast'),
  @JsonValue('lunch')
  lunch('Lunch'),
  @JsonValue('dinner')
  dinner('Dinner'),
  @JsonValue('snack')
  snack('Snack');

  const MealType(this.label);
  final String label;

  static MealType forTime(DateTime time) {
    final h = time.hour;
    if (h < 11) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }
}

enum MealSource {
  @JsonValue('photo')
  photo,
  @JsonValue('text')
  text,
  @JsonValue('voice')
  voice,
  @JsonValue('database')
  database,
  @JsonValue('favorite')
  favorite,
}

enum RiskBand {
  @JsonValue('low')
  low('Low'),
  @JsonValue('moderate')
  moderate('Moderate'),
  @JsonValue('elevated')
  elevated('Elevated'),
  @JsonValue('high')
  high('High');

  const RiskBand(this.label);
  final String label;
}

enum BmiCategory {
  @JsonValue('underweight')
  underweight('Underweight'),
  @JsonValue('healthy')
  healthy('Healthy'),
  @JsonValue('overweight')
  overweight('Overweight'),
  @JsonValue('obese')
  obese('Obese');

  const BmiCategory(this.label);
  final String label;
}

enum WorkoutCategory {
  @JsonValue('home')
  home('Home', '🏠'),
  @JsonValue('gym')
  gym('Gym', '🏋️'),
  @JsonValue('office')
  office('Office', '💼'),
  @JsonValue('walking')
  walking('Walking', '🚶'),
  @JsonValue('running')
  running('Running', '🏃'),
  @JsonValue('mobility')
  mobility('Mobility', '🤸'),
  @JsonValue('stretching')
  stretching('Stretching', '🧎'),
  @JsonValue('strength')
  strength('Strength', '💪'),
  @JsonValue('hiit')
  hiit('HIIT', '⚡'),
  @JsonValue('yoga')
  yoga('Yoga', '🧘');

  const WorkoutCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}
