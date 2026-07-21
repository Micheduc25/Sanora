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

  /// Seeds the wizard from a saved profile so the same steps can be reopened
  /// to edit it.
  factory OnboardingDraft.fromProfile(UserProfile p) => OnboardingDraft(
    name: p.name,
    age: p.age,
    sex: p.sex,
    heightCm: p.heightCm,
    weightKg: p.weightKg,
    waistCm: p.waistCm,
    hipCm: p.hipCm,
    bodyFatPct: p.bodyFatPct,
    occupation: p.occupation,
    country: p.country,
    language: p.language,
    activityLevel: p.activityLevel,
    exerciseDaysPerWeek: p.exerciseDaysPerWeek,
    sleepHours: p.sleepHours,
    stressLevel: p.stressLevel,
    medicalConditions: [...p.medicalConditions],
    medications: [...p.medications],
    allergies: [...p.allergies],
    foodPreferences: [...p.foodPreferences],
    favoriteFoods: [...p.favoriteFoods],
    workSchedule: p.workSchedule,
    goals: [...p.goals],
    targetWeightKg: p.targetWeightKg,
    targetWaistCm: p.targetWaistCm,
    targetBodyFatPct: p.targetBodyFatPct,
    targetDate: p.targetDate,
  );

  /// [existing] keeps the row's identity when editing — minting a new id would
  /// orphan the profile already synced under the old one.
  UserProfile toProfile({UserProfile? existing}) {
    final now = DateTime.now();
    return UserProfile(
      id: existing?.id ?? const Uuid().v4(),
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
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }
}

class OnboardingController extends FamilyNotifier<OnboardingDraft, bool> {
  /// [editing] seeds the draft from the saved profile.
  ///
  /// This is a provider argument rather than a `loadFrom` call from the
  /// screen because Riverpod forbids modifying a provider during a widget
  /// life-cycle — doing it from `useEffect` threw. Seeding here also means the
  /// first frame already shows the user's answers instead of the defaults.
  ///
  /// `read`, not `watch`: the draft is mutable working state, so re-seeding it
  /// when the saved profile changes would throw away edits in progress.
  @override
  OnboardingDraft build(bool editing) {
    if (!editing) return OnboardingDraft();
    final profile = ref.read(profileRepositoryProvider).getProfile();
    return profile == null
        ? OnboardingDraft()
        : OnboardingDraft.fromProfile(profile);
  }

  void update(void Function(OnboardingDraft) mutate) {
    mutate(state);
    ref.notifyListeners();
  }

  /// Persists the profile and returns the freshly computed health profile.
  /// Editing keeps the existing row's identity and creation date.
  Future<HealthProfile> complete() async {
    final repo = ref.read(profileRepositoryProvider);
    final profile = state.toProfile(existing: repo.getProfile());
    final health = await repo.saveProfile(profile);
    ref.invalidate(userProfileProvider);
    ref.invalidate(healthProfileProvider);
    return health;
  }
}

final onboardingControllerProvider =
    NotifierProvider.family<OnboardingController, OnboardingDraft, bool>(
      OnboardingController.new,
    );

final userProfileProvider = Provider<UserProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).getProfile(),
);

final healthProfileProvider = Provider<HealthProfile?>(
  (ref) => ref.watch(profileRepositoryProvider).getHealthProfile(),
);
