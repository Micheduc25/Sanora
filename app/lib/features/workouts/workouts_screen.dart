import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/error/failures.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/sanora_card.dart';
import '../../data/repositories/workouts_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/workout.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/onboarding_controller.dart';
import 'workout_detail_screen.dart';

final workoutsListProvider = Provider.autoDispose(
  (ref) => ref.watch(workoutsRepositoryProvider).all(),
);

class WorkoutsScreen extends HookConsumerWidget {
  const WorkoutsScreen({super.key});

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    WorkoutCategory category,
    int durationMinutes,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    // Resolved before the first await: generation can take two minutes, and
    // the context may be gone by the time the failure copy is needed.
    final l = L.of(context);
    final profile = ref.read(userProfileProvider);
    final health = ref.read(healthProfileProvider);
    if (profile == null || health == null) return;
    try {
      final workout = await ref
          .read(aiServiceProvider)
          .generateWorkout(
            category: category,
            durationMinutes: durationMinutes,
            profile: profile,
            health: health,
          );
      await ref.read(workoutsRepositoryProvider).save(workout);
      ref.invalidate(workoutsListProvider);
    } on AiUnavailableFailure {
      await _useTemplate(ref, messenger, category, l.workoutsOfflineTemplate);
    } on QuotaFailure {
      await _useTemplate(ref, messenger, category, l.workoutsQuotaTemplate);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.workoutsGenerateFailed)));
    }
  }

  Future<void> _useTemplate(
    WidgetRef ref,
    ScaffoldMessengerState messenger,
    WorkoutCategory category,
    String explanation,
  ) async {
    final template = WorkoutsRepositoryTemplates.closest(category);
    await ref.read(workoutsRepositoryProvider).save(template);
    ref.invalidate(workoutsListProvider);
    messenger.showSnackBar(SnackBar(content: Text(explanation)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsListProvider);
    final theme = Theme.of(context);
    final l = L.of(context);
    // Generation can take up to two minutes, so the tapped category has to
    // show progress and the rest have to stop accepting taps.
    final generating = useState<WorkoutCategory?>(null);
    final minutes = useState(20);

    Future<void> start(WorkoutCategory category) async {
      if (generating.value != null) return;
      generating.value = category;
      try {
        await _generate(context, ref, category, minutes.value);
      } finally {
        generating.value = null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.workoutsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(l.workoutsGenerateForToday, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: [
              for (final m in const [15, 20, 30, 45])
                ButtonSegment(
                  value: m,
                  label: Text(l.workoutsDurationMinutes(m)),
                ),
            ],
            selected: {minutes.value},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => minutes.value = selection.first,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final category in WorkoutCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SanoraCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      onTap: generating.value == null
                          ? () => start(category)
                          : null,
                      child: Opacity(
                        opacity:
                            generating.value == null ||
                                generating.value == category
                            ? 1
                            : 0.4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (generating.value == category)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            else
                              Text(
                                category.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              category.labelOf(context),
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Templates are the coach's, not the user's — calling them "your
          // workouts" before anything is saved overstates it.
          SectionHeader(
            workouts.isEmpty ? l.workoutsCoachPicks : l.workoutsYourWorkouts,
          ),
          if (workouts.isEmpty)
            for (final template in WorkoutsRepositoryTemplates.all())
              _WorkoutCard(workout: template, isTemplate: true)
          else
            for (final workout in workouts)
              _WorkoutCard(workout: workout, isTemplate: false),
        ],
      ),
    );
  }
}

/// Stable template list for the session so ids don't churn on rebuild.
abstract final class WorkoutsRepositoryTemplates {
  static List<Workout>? _cache;

  static List<Workout> all() => _cache ??= WorkoutsRepository.templates();

  static Workout closest(WorkoutCategory category) => all().firstWhere(
    (w) => w.category == category,
    orElse: () => all().first,
  );
}

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard({required this.workout, required this.isTemplate});

  final Workout workout;
  final bool isTemplate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SanoraCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workout: workout),
          ),
        ),
        child: Row(
          children: [
            Text(workout.category.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.name, style: theme.textTheme.titleMedium),
                  Text(
                    '${workout.difficulty} · ${workout.durationMinutes} min · ~${workout.estimatedCalories} kcal',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (workout.completed)
              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
