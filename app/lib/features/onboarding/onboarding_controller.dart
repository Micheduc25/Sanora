import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/health_profile.dart';
import '../../domain/models/user_profile.dart';

class OnboardingDraft {
  OnboardingDraft({
    this.name = '',
    this.age = 30,
    this.sex,
    this.heightCm = 170,
    this.weightKg = 75,
    this.waistCm,
    this.hipCm,
    this.bodyFatPct,
    this.occupation = '',
    this.country = '',
    this.language = 'en',
    this.activityLevel,
    this.exerciseDaysPerWeek = 2,
    this.sleepHours = 7,
    this.stressLevel,
    this.medicalConditions = const [],
    this.medications = const [],
    this.allergies = const [],
    this.foodPreferences = const [],
    this.favoriteFoods = const [],
    this.workSchedule = '',
    this.goals = const [],
    this.targetWeightKg,
    this.targetWaistCm,
    this.targetBodyFatPct,
    this.targetDate,
  });

  String name;
  int age;
  Sex? sex;
  double heightCm;
  double weightKg;
  double? waistCm;
  double? hipCm;
  double? bodyFatPct;
  String occupation;
  String country;
  String language;
  ActivityLevel? activityLevel;
  int exerciseDaysPerWeek;
  double sleepHours;
  StressLevel? stressLevel;
  List<String> medicalConditions;
  List<String> medications;
  List<String> allergies;
  List<String> foodPreferences;
  List<String> favoriteFoods;
  String workSchedule;
  List<GoalType> goals;
  double? targetWeightKg;
  double? targetWaistCm;
  double? targetBodyFatPct;
  DateTime? targetDate;

  UserProfile toProfile() {
    final now = DateTime.now();
    return UserProfile(
      id: const Uuid().v4(),
      name: name.trim(),
      age: age,
      sex: sex ?? Sex.other,
      heightCm: heightCm,
      weightKg: weightKg,
      waistCm: waistCm,
      hipCm: hipCm,
      bodyFatPct: bodyFatPct,
      occupation: occupation.trim(),
      country: country.trim(),
      language: language,
      activityLevel: activityLevel ?? ActivityLevel.sedentary,
      exerciseDaysPerWeek: exerciseDaysPerWeek,
      sleepHours: sleepHours,
      stressLevel: stressLevel ?? StressLevel.moderate,
      medicalConditions: medicalConditions,
      medications: medications,
      allergies: allergies,
      foodPreferences: foodPreferences,
      favoriteFoods: favoriteFoods,
      workSchedule: workSchedule.trim(),
      goals: goals,
      targetWeightKg: targetWeightKg,
      targetWaistCm: targetWaistCm,
      targetBodyFatPct: targetBodyFatPct,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => OnboardingDraft();

  void update(void Function(OnboardingDraft) mutate) {
    mutate(state);
    ref.notifyListeners();
  }

  /// Persists the profile and returns the freshly computed health profile.
  Future<HealthProfile> complete() async {
    final profile = state.toProfile();
    final health = await ref
        .read(profileRepositoryProvider)
        .saveProfile(profile);
    ref.invalidate(userProfileProvider);
    ref.invalidate(healthProfileProvider);
    return health;
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );

final userProfileProvider = Provider<UserProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).getProfile(),
);

final healthProfileProvider = Provider<HealthProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).getHealthProfile(),
);
