import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/error/failures.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/bodi_card.dart';
import '../../data/repositories/workouts_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/workout.dart';
import '../onboarding/onboarding_controller.dart';
import 'workout_detail_screen.dart';

final workoutsListProvider = Provider.autoDispose(
    (ref) => ref.watch(workoutsRepositoryProvider).all());

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  Future<void> _generate(
      BuildContext context, WidgetRef ref, WorkoutCategory category) async {
    final messenger = ScaffoldMessenger.of(context);
    final profile = ref.read(userProfileProvider);
    final health = ref.read(healthProfileProvider);
    if (profile == null || health == null) return;
    try {
      final workout = await ref.read(aiServiceProvider).generateWorkout(
            category: category,
            durationMinutes: 20,
            profile: profile,
            health: health,
          );
      await ref.read(workoutsRepositoryProvider).save(workout);
      ref.invalidate(workoutsListProvider);
    } on AiUnavailableFailure {
      final template = WorkoutsRepositoryTemplates.closest(category);
      await ref.read(workoutsRepositoryProvider).save(template);
      ref.invalidate(workoutsListProvider);
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'Offline — added a coach-curated workout instead. Connect for a personalized one.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content:
              Text('Could not generate a workout. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Generate for today', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final category in WorkoutCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: BodiCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      onTap: () => _generate(context, ref, category),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(category.emoji,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 6),
                          Text(category.label,
                              style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SectionHeader('Your workouts'),
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

  static Workout closest(WorkoutCategory category) =>
      all().firstWhere((w) => w.category == category,
          orElse: () => all().first);
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
      child: BodiCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workout: workout))),
        child: Row(
          children: [
            Text(workout.category.emoji,
                style: const TextStyle(fontSize: 28)),
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
              Icon(Icons.check_circle_rounded,
                  color: theme.colorScheme.primary)
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
