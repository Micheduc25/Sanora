import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/widgets/bodi_card.dart';
import '../../domain/models/workout.dart';
import '../../l10n/app_localizations.dart';
import 'workouts_screen.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(workout.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Row(
            children: [
              _Pill('${workout.category.emoji} ${workout.category.label}'),
              const SizedBox(width: 8),
              _Pill(workout.difficulty),
              const SizedBox(width: 8),
              _Pill(
                L.of(context).workoutsDurationMinutes(workout.durationMinutes),
              ),
              const SizedBox(width: 8),
              _Pill('~${workout.estimatedCalories} kcal'),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < workout.exercises.length; i++) ...[
            _ExerciseCard(index: i + 1, exercise: workout.exercises[i]),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomSheet: workout.completed
          ? null
          : Container(
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: Text(L.of(context).workoutsMarkCompleted),
                onPressed: () async {
                  await ref
                      .read(workoutsRepositoryProvider)
                      .markCompleted(workout);
                  ref.invalidate(workoutsListProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(L.of(context).workoutsLogged)),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.index, required this.exercise});

  final int index;
  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BodiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '$index',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(exercise.name, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(exercise.instructions, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(
            '${exercise.sets} × ${exercise.repsOrDuration}'
            '${exercise.restSeconds > 0 ? ' · rest ${exercise.restSeconds}s' : ''}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
