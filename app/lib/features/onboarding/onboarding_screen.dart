import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../domain/models/enums.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_widgets.dart';

class OnboardingScreen extends HookConsumerWidget {
  const OnboardingScreen({super.key});

  static const _stepCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = useState(0);
    final pageController = usePageController();
    final draft = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);

    bool canContinue() => switch (page.value) {
      1 => draft.sex != null,
      3 => draft.activityLevel != null,
      4 => draft.stressLevel != null,
      7 => draft.goals.isNotEmpty,
      _ => true,
    };

    Future<void> next() async {
      if (page.value == _stepCount - 1) {
        context.go('/onboarding/generating');
        return;
      }
      await pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    Future<void> back() async {
      if (page.value == 0) return;
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
                    opacity: page.value == 0 ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: back,
                      icon: const Icon(Icons.arrow_back_rounded),
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
                ? 'Get started'
                : page.value == _stepCount - 1
                ? 'Create my health profile'
                : 'Continue',
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
          Text('Know your body.', style: theme.textTheme.displayMedium),
          const SizedBox(height: 12),
          Text(
            'Bodi turns a few details about you into a personal health plan — '
            'and an AI coach that helps you eat better, move more and live longer.\n\n'
            'No calorie obsession. No shame. Just steady progress.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Takes about 2 minutes · your data stays private',
            style: theme.textTheme.labelMedium,
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
    return StepScaffold(
      title: 'About you',
      subtitle: 'This shapes every calculation Bodi makes for you.',
      children: [
        const FieldLabel('What should we call you?'),
        TextFormField(
          initialValue: draft.name,
          decoration: const InputDecoration(hintText: 'Your first name'),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => controller.update((d) => d.name = v),
        ),
        const FieldLabel('Age'),
        ValueSlider(
          value: draft.age.toDouble(),
          min: 13,
          max: 90,
          step: 1,
          unit: 'years',
          onChanged: (v) => controller.update((d) => d.age = v.round()),
        ),
        const FieldLabel('Sex'),
        ChoiceCardGroup<Sex>(
          options: Sex.values,
          selected: draft.sex,
          onSelected: (v) => controller.update((d) => d.sex = v),
          titleOf: (s) => s.label,
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
    return StepScaffold(
      title: 'Your body today',
      subtitle:
          'A tape measure around your waist tells us more than a scale ever will.',
      children: [
        const FieldLabel('Height'),
        ValueSlider(
          value: draft.heightCm,
          min: 120,
          max: 220,
          step: 1,
          unit: 'cm',
          onChanged: (v) => controller.update((d) => d.heightCm = v),
        ),
        const FieldLabel('Weight'),
        ValueSlider(
          value: draft.weightKg,
          min: 35,
          max: 200,
          step: 0.5,
          decimals: 1,
          unit: 'kg',
          onChanged: (v) => controller.update((d) => d.weightKg = v),
        ),
        const FieldLabel('Waist', optional: true),
        ValueSlider(
          value: draft.waistCm ?? 85,
          min: 50,
          max: 160,
          step: 0.5,
          decimals: 1,
          unit: 'cm',
          onChanged: (v) => controller.update((d) => d.waistCm = v),
        ),
        const FieldLabel('Hip', optional: true),
        ValueSlider(
          value: draft.hipCm ?? 95,
          min: 60,
          max: 170,
          step: 0.5,
          decimals: 1,
          unit: 'cm',
          onChanged: (v) => controller.update((d) => d.hipCm = v),
        ),
        const FieldLabel('Body fat', optional: true),
        ValueSlider(
          value: draft.bodyFatPct ?? 25,
          min: 4,
          max: 60,
          step: 0.5,
          decimals: 1,
          unit: '%',
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
    return StepScaffold(
      title: 'Your life',
      subtitle: 'Health advice only works when it fits your real routine.',
      children: [
        const FieldLabel('Occupation'),
        TextFormField(
          initialValue: draft.occupation,
          decoration: const InputDecoration(hintText: 'e.g. Software engineer'),
          onChanged: (v) => controller.update((d) => d.occupation = v),
        ),
        const FieldLabel('Country'),
        TextFormField(
          initialValue: draft.country,
          decoration: const InputDecoration(hintText: 'e.g. Cameroon'),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => controller.update((d) => d.country = v),
        ),
        const FieldLabel('Typical work schedule'),
        TagEditor(
          values: draft.workSchedule.isEmpty ? [] : [draft.workSchedule],
          presets: const [
            '9 to 5 desk job',
            'Shift work',
            'Remote, flexible',
            'On my feet all day',
            'Student schedule',
          ],
          onChanged: (v) => controller.update(
            (d) => d.workSchedule = v.isEmpty ? '' : v.last,
          ),
          hint: 'Describe your schedule…',
        ),
        const FieldLabel('How active is a normal week?'),
        ChoiceCardGroup<ActivityLevel>(
          options: ActivityLevel.values,
          selected: draft.activityLevel,
          onSelected: (v) => controller.update((d) => d.activityLevel = v),
          titleOf: (a) => a.label,
          subtitleOf: (a) => a.description,
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
    return StepScaffold(
      title: 'Your rhythm',
      subtitle: 'Sleep and stress move the needle as much as food does.',
      children: [
        const FieldLabel('Workouts per week'),
        ValueSlider(
          value: draft.exerciseDaysPerWeek.toDouble(),
          min: 0,
          max: 7,
          step: 1,
          unit: 'days',
          onChanged: (v) =>
              controller.update((d) => d.exerciseDaysPerWeek = v.round()),
        ),
        const FieldLabel('Usual sleep per night'),
        ValueSlider(
          value: draft.sleepHours,
          min: 3,
          max: 12,
          step: 0.5,
          decimals: 1,
          unit: 'hours',
          onChanged: (v) => controller.update((d) => d.sleepHours = v),
        ),
        const FieldLabel('Stress level lately'),
        ChoiceCardGroup<StressLevel>(
          options: StressLevel.values,
          selected: draft.stressLevel,
          onSelected: (v) => controller.update((d) => d.stressLevel = v),
          titleOf: (s) => s.label,
          subtitleOf: (s) => s.description,
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
    return StepScaffold(
      title: 'Health background',
      subtitle:
          'Bodi adapts its advice around conditions and medication. This never leaves your control.',
      children: [
        const FieldLabel('Medical conditions', optional: true),
        TagEditor(
          values: draft.medicalConditions,
          presets: const [
            'Hypertension',
            'Diabetes',
            'Prediabetes',
            'High cholesterol',
            'Asthma',
            'Ulcer',
            'Sickle cell',
          ],
          onChanged: (v) => controller.update((d) => d.medicalConditions = v),
        ),
        const FieldLabel('Current medications', optional: true),
        TagEditor(
          values: draft.medications,
          presets: const [],
          onChanged: (v) => controller.update((d) => d.medications = v),
          hint: 'e.g. Amlodipine 5mg…',
        ),
        const FieldLabel('Food allergies', optional: true),
        TagEditor(
          values: draft.allergies,
          presets: const ['Peanuts', 'Shellfish', 'Eggs', 'Milk', 'Gluten'],
          onChanged: (v) => controller.update((d) => d.allergies = v),
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
    return StepScaffold(
      title: 'How you eat',
      subtitle:
          'Bodi works with your food culture — fufu and eru included — never against it.',
      children: [
        const FieldLabel('Preferences'),
        TagEditor(
          values: draft.foodPreferences,
          presets: const [
            'No preference',
            'Vegetarian',
            'Vegan',
            'Halal',
            'Low carb',
            'Local dishes mostly',
          ],
          onChanged: (v) => controller.update((d) => d.foodPreferences = v),
        ),
        const FieldLabel('Favorite meals'),
        TagEditor(
          values: draft.favoriteFoods,
          presets: const [
            'Eru',
            'Ndolé',
            'Jollof rice',
            'Achu',
            'Roasted fish',
            'Beans & plantains',
            'Pepper soup',
          ],
          onChanged: (v) => controller.update((d) => d.favoriteFoods = v),
          hint: 'Add a favorite meal…',
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
    return StepScaffold(
      title: 'Where are we going?',
      subtitle: 'Pick everything that matters to you. Bodi balances them.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final goal in GoalType.values)
              FilterChip(
                label: Text('${goal.emoji} ${goal.label}'),
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
        const FieldLabel('Target weight', optional: true),
        ValueSlider(
          value: draft.targetWeightKg ?? draft.weightKg,
          min: 35,
          max: 200,
          step: 0.5,
          decimals: 1,
          unit: 'kg',
          onChanged: (v) => controller.update((d) => d.targetWeightKg = v),
        ),
        const FieldLabel('Target waist', optional: true),
        ValueSlider(
          value: draft.targetWaistCm ?? draft.waistCm ?? 85,
          min: 50,
          max: 160,
          step: 0.5,
          decimals: 1,
          unit: 'cm',
          onChanged: (v) => controller.update((d) => d.targetWaistCm = v),
        ),
        const FieldLabel('When would you like to get there?', optional: true),
        OutlinedButton.icon(
          icon: const Icon(Icons.event_rounded),
          label: Text(
            draft.targetDate == null
                ? 'Pick a date'
                : DateFormat('d MMMM yyyy').format(draft.targetDate!),
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
