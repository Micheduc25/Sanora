import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/l10n/enum_labels.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/user_profile.dart';
import '../../l10n/app_localizations.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_widgets.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key, this.editing = false});

  /// Reopened from the profile screen to change answers. Skips the welcome
  /// step, saves in place rather than routing to the first-run generating
  /// screen, and keeps the existing profile's identity.
  final bool editing;

  static const _stepCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstStep = editing ? 1 : 0;
    final page = useState(firstStep);
    final pageController = usePageController(initialPage: firstStep);
    // Seeded from the saved profile when editing — see OnboardingController.
    final draft = ref.watch(onboardingControllerProvider(editing));
    final controller = ref.read(onboardingControllerProvider(editing).notifier);
    final theme = Theme.of(context);
    final l = L.of(context);

    // Set before leaving for the generating screen, which saves the profile —
    // otherwise this screen, still mounted underneath it, would read its own
    // write as a restore.
    final submitted = useRef(false);

    // A profile can land here at any moment: the startup pull finishing late,
    // or the user signing in from the welcome step. Someone who has not
    // answered anything yet just wants their data, so take them to it; someone
    // mid-wizard has typed answers this would silently discard, so offer.
    if (!editing) {
      ref.listen<UserProfile?>(userProfileProvider, (previous, next) {
        if (previous != null || next == null || submitted.value) return;
        if (page.value == 0) {
          context.go('/');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.onboardingProfileRestored),
            action: SnackBarAction(
              label: l.onboardingUseSavedProfile,
              onPressed: () => context.go('/'),
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      });
    }

    bool canContinue() => switch (page.value) {
      1 => draft.sex != null,
      3 => draft.activityLevel != null,
      4 => draft.stressLevel != null,
      7 => draft.goals.isNotEmpty,
      _ => true,
    };

    Future<void> next() async {
      if (page.value == _stepCount - 1) {
        if (editing) {
          await controller.complete();
          if (context.mounted) context.pop();
        } else {
          submitted.value = true;
          context.go('/onboarding/generating');
        }
        return;
      }
      await pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    Future<void> back() async {
      if (page.value == firstStep) return;
      await pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: page.value == firstStep ? (editing ? 1 : 0) : 1,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      // On the first editable step there is nowhere back to
                      // go inside the wizard, so leave editing entirely.
                      onPressed: editing && page.value == firstStep
                          ? context.pop
                          : back,
                      icon: Icon(
                        editing && page.value == firstStep
                            ? Icons.close_rounded
                            : Icons.arrow_back_rounded,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SmoothPageIndicator(
                    controller: pageController,
                    count: _stepCount,
                    effect: ExpandingDotsEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      expansionFactor: 4,
                      activeDotColor: theme.colorScheme.primary,
                      dotColor: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => page.value = i,
                children: [
                  const _WelcomeStep(),
                  _AboutStep(draft: draft, controller: controller),
                  _BodyStep(draft: draft, controller: controller),
                  _LifestyleStep(draft: draft, controller: controller),
                  _RhythmStep(draft: draft, controller: controller),
                  _HealthStep(draft: draft, controller: controller),
                  _FoodStep(draft: draft, controller: controller),
                  _GoalsStep(draft: draft, controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: FilledButton(
          onPressed: canContinue() ? next : null,
          child: Text(
            page.value == 0
                ? l.onboardingGetStarted
                : page.value == _stepCount - 1
                ? (editing
                      ? l.onboardingSaveChanges
                      : l.onboardingCreateProfile)
                : l.actionContinue,
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text('🌱', style: theme.textTheme.displayMedium),
          ),
          const SizedBox(height: 28),
          Text(l.onboardingWelcomeTitle, style: theme.textTheme.displayMedium),
          const SizedBox(height: 12),
          Text(
            l.onboardingWelcomeBody,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(l.onboardingWelcomeFootnote, style: theme.textTheme.labelMedium),
          const SizedBox(height: 12),
          // Someone who onboarded on another device should never have to
          // answer all eight steps again — signing in pulls the profile back.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/auth'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l.onboardingWelcomeRestore),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutStep extends StatelessWidget {
  const _AboutStep({required this.draft, required this.controller});

  final OnboardingDraft draft;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return StepScaffold(
      title: l.onboardingAboutTitle,
      subtitle: l.onboardingAboutSubtitle,
      children: [
        FieldLabel(l.onboardingFieldName),
        TextFormField(
          initialValue: draft.name,
          decoration: InputDecoration(hintText: l.onboardingHintFirstName),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => controller.update((d) => d.name = v),
        ),
        FieldLabel(l.onboardingFieldAge),
        ValueSlider(
          value: draft.age.toDouble(),
          min: 13,
          max: 90,
          step: 1,
          unit: l.onboardingUnitYears,
          onChanged: (v) => controller.update((d) => d.age = v.round()),
        ),
        FieldLabel(l.onboardingFieldSex),
        ChoiceCardGroup<Sex>(
          options: Sex.values,
          selected: draft.sex,
          onSelected: (v) => controller.update((d) => d.sex = v),
          titleOf: (s) => s.labelOf(context),
        ),
      ],
    );
  }
}

class _BodyStep extends StatelessWidget {
  const _BodyStep({required this.draft, required this.controller});

  final OnboardingDraft draft;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return StepScaffold(
      title: l.onboardingBodyTitle,
      subtitle: l.onboardingBodySubtitle,
      children: [
        FieldLabel(l.onboardingFieldHeight),
        ValueSlider(
          value: draft.heightCm,
          min: 120,
          max: 220,
          step: 1,
          unit: l.onboardingUnitCm,
          onChanged: (v) => controller.update((d) => d.heightCm = v),
        ),
        FieldLabel(l.metricWeight),
        ValueSlider(
          value: draft.weightKg,
          min: 35,
          max: 200,
          step: 0.5,
          decimals: 1,
          unit: l.onboardingUnitKg,
          onChanged: (v) => controller.update((d) => d.weightKg = v),
        ),
        FieldLabel(l.metricWaist, optional: true),
        ValueSlider(
          value: draft.waistCm ?? 85,
          min: 50,
          max: 160,
          step: 0.5,
          decimals: 1,
          unit: l.onboardingUnitCm,
          onChanged: (v) => controller.update((d) => d.waistCm = v),
        ),
        FieldLabel(l.metricHip, optional: true),
        ValueSlider(
          value: draft.hipCm ?? 95,
          min: 60,
          max: 170,
          step: 0.5,
          decimals: 1,
          unit: l.onboardingUnitCm,
          onChanged: (v) => controller.update((d) => d.hipCm = v),
        ),
        FieldLabel(l.metricBodyFat, optional: true),
        ValueSlider(
          value: draft.bodyFatPct ?? 25,
          min: 4,
          max: 60,
          step: 0.5,
          decimals: 1,
          unit: l.onboardingUnitPercent,
          onChanged: (v) => controller.update((d) => d.bodyFatPct = v),
        ),
      ],
    );
  }
}

class _LifestyleStep extends StatelessWidget {
  const _LifestyleStep({required this.draft, required this.controller});

  final OnboardingDraft draft;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return StepScaffold(
      title: l.onboardingLifeTitle,
      subtitle: l.onboardingLifeSubtitle,
      children: [
        FieldLabel(l.onboardingFieldOccupation),
        TextFormField(
          initialValue: draft.occupation,
          decoration: InputDecoration(hintText: l.onboardingHintOccupation),
          onChanged: (v) => controller.update((d) => d.occupation = v),
        ),
        FieldLabel(l.onboardingFieldCountry),
        TextFormField(
          initialValue: draft.country,
          decoration: InputDecoration(hintText: l.onboardingHintCountry),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => controller.update((d) => d.country = v),
        ),
        FieldLabel(l.onboardingFieldWorkSchedule),
        TagEditor(
          values: draft.workSchedule.isEmpty ? [] : [draft.workSchedule],
          presets: [
            l.onboardingScheduleDeskJob,
            l.onboardingScheduleShiftWork,
            l.onboardingScheduleRemote,
            l.onboardingScheduleOnMyFeet,
            l.onboardingScheduleStudent,
          ],
          onChanged: (v) => controller.update(
            (d) => d.workSchedule = v.isEmpty ? '' : v.last,
          ),
          hint: l.onboardingHintSchedule,
        ),
        FieldLabel(l.onboardingFieldActivity),
        ChoiceCardGroup<ActivityLevel>(
          options: ActivityLevel.values,
          selected: draft.activityLevel,
          onSelected: (v) => controller.update((d) => d.activityLevel = v),
          titleOf: (a) => a.labelOf(context),
          subtitleOf: (a) => a.descriptionOf(context),
        ),
      ],
    );
  }
}

class _RhythmStep extends StatelessWidget {
  const _RhythmStep({required this.draft, required this.controller});

  final OnboardingDraft draft;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return StepScaffold(
      title: l.onboardingRhythmTitle,
      subtitle: l.onboardingRhythmSubtitle,
      children: [
        FieldLabel(l.onboardingFieldWorkouts),
        ValueSlider(
          value: draft.exerciseDaysPerWeek.toDouble(),
          min: 0,
          max: 7,
          step: 1,
          unit: l.onboardingUnitDays,
          onChanged: (v) =>
              controller.update((d) => d.exerciseDaysPerWeek = v.round()),
        ),
        FieldLabel(l.onboardingFieldSleep),
        ValueSlider(
          value: draft.sleepHours,
          min: 3,
          max: 12,
          step: 0.5,
          decimals: 1,
          unit: l.onboardingUnitHours,
          onChanged: (v) => controller.update((d) => d.sleepHours = v),
        ),
        FieldLabel(l.onboardingFieldStress),
        ChoiceCardGroup<StressLevel>(
          options: StressLevel.values,
          selected: draft.stressLevel,
          onSelected: (v) => controller.update((d) => d.stressLevel = v),
          titleOf: (s) => s.labelOf(context),
          subtitleOf: (s) => s.descriptionOf(context),
        ),
      ],
    );
  }
}

class _HealthStep extends StatelessWidget {
  const _HealthStep({required this.draft, required this.controller});

  final OnboardingDraft draft;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return StepScaffold(
      title: l.onboardingHealthTitle,
      subtitle: l.onboardingHealthSubtitle,
      children: [
        FieldLabel(l.onboardingFieldConditions, optional: true),
        TagEditor(
          values: draft.medicalConditions,
          presets: [
            l.onboardingConditionHypertension,
            l.onboardingConditionDiabetes,
            l.onboardingConditionPrediabetes,
            l.onboardingConditionHighCholesterol,
            l.onboardingConditionAsthma,
            l.onboardingConditionUlcer,
            l.onboardingConditionSickleCell,
          ],
          onChanged: (v) => controller.update((d) => d.medicalConditions = v),
          hint: l.onboardingTagAddYourOwn,
        ),
        FieldLabel(l.onboardingFieldMedications, optional: true),
        TagEditor(
          values: draft.medications,
          presets: const [],
          onChanged: (v) => controller.update((d) => d.medications = v),
          hint: l.onboardingHintMedication,
        ),
        FieldLabel(l.onboardingFieldAllergies, optional: true),
        TagEditor(
          values: draft.allergies,
          presets: [
            l.onboardingAllergyPeanuts,
            l.onboardingAllergyShellfish,
            l.onboardingAllergyEggs,
            l.onboardingAllergyMilk,
            l.onboardingAllergyGluten,
          ],
          onChanged: (v) => controller.update((d) => d.allergies = v),
          hint: l.onboardingTagAddYourOwn,
        ),
      ],
    );
  }
}

class _FoodStep extends StatelessWidget {
  const _FoodStep({required this.draft, required this.controller});

  final OnboardingDraft draft;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return StepScaffold(
      title: l.onboardingFoodTitle,
      subtitle: l.onboardingFoodSubtitle,
      children: [
        FieldLabel(l.onboardingFieldPreferences),
        TagEditor(
          values: draft.foodPreferences,
          presets: [
            l.onboardingPreferenceNone,
            l.onboardingPreferenceVegetarian,
            l.onboardingPreferenceVegan,
            l.onboardingPreferenceHalal,
            l.onboardingPreferenceLowCarb,
            l.onboardingPreferenceLocalDishes,
          ],
          onChanged: (v) => controller.update((d) => d.foodPreferences = v),
          hint: l.onboardingTagAddYourOwn,
        ),
        FieldLabel(l.onboardingFieldFavoriteMeals),
        TagEditor(
          values: draft.favoriteFoods,
          presets: [
            l.onboardingFoodEru,
            l.onboardingFoodNdole,
            l.onboardingFoodJollofRice,
            l.onboardingFoodAchu,
            l.onboardingFoodRoastedFish,
            l.onboardingFoodBeansPlantains,
            l.onboardingFoodPepperSoup,
          ],
          onChanged: (v) => controller.update((d) => d.favoriteFoods = v),
          hint: l.onboardingHintFavoriteMeal,
        ),
      ],
    );
  }
}

class _GoalsStep extends StatelessWidget {
  const _GoalsStep({required this.draft, required this.controller});

  final OnboardingDraft draft;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    return StepScaffold(
      title: l.onboardingGoalsTitle,
      subtitle: l.onboardingGoalsSubtitle,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final goal in GoalType.values)
              FilterChip(
                label: Text(
                  l.onboardingGoalChip(goal.emoji, goal.labelOf(context)),
                ),
                selected: draft.goals.contains(goal),
                showCheckmark: false,
                onSelected: (_) => controller.update((d) {
                  final next = List<GoalType>.from(d.goals);
                  next.contains(goal) ? next.remove(goal) : next.add(goal);
                  d.goals = next;
                }),
              ),
          ],
        ),
        FieldLabel(l.onboardingFieldTargetWeight, optional: true),
        ValueSlider(
          value: draft.targetWeightKg ?? draft.weightKg,
          min: 35,
          max: 200,
          step: 0.5,
          decimals: 1,
          unit: l.onboardingUnitKg,
          onChanged: (v) => controller.update((d) => d.targetWeightKg = v),
        ),
        FieldLabel(l.onboardingFieldTargetWaist, optional: true),
        ValueSlider(
          value: draft.targetWaistCm ?? draft.waistCm ?? 85,
          min: 50,
          max: 160,
          step: 0.5,
          decimals: 1,
          unit: l.onboardingUnitCm,
          onChanged: (v) => controller.update((d) => d.targetWaistCm = v),
        ),
        FieldLabel(l.onboardingFieldTargetDate, optional: true),
        OutlinedButton.icon(
          icon: const Icon(Icons.event_rounded),
          label: Text(
            draft.targetDate == null
                ? l.onboardingPickDate
                : DateFormat.yMMMMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(draft.targetDate!),
            style: theme.textTheme.labelLarge,
          ),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  draft.targetDate ?? now.add(const Duration(days: 90)),
              firstDate: now.add(const Duration(days: 14)),
              lastDate: now.add(const Duration(days: 730)),
            );
            if (picked != null) {
              controller.update((d) => d.targetDate = picked);
            }
          },
        ),
      ],
    );
  }
}
