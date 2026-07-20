import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/stat_tile.dart';
import '../../domain/models/insight.dart';
import '../habits/habits_controller.dart';
import '../onboarding/onboarding_controller.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final data = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(dashboardProvider.future),
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (d) {
              if (d == null) return const SizedBox.shrink();
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greetingFor(now, profile?.name ?? ''),
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM').format(now),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () => context.push('/insights'),
                        icon: Badge(
                          isLabelVisible: d.topInsight != null,
                          child: const Icon(Icons.auto_awesome_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ScoreCard(data: d),
                  const SizedBox(height: 12),
                  if (d.topInsight != null) ...[
                    _InsightCard(insight: d.topInsight!),
                    const SizedBox(height: 12),
                  ],
                  _BodyTrendCard(data: d),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      StatTile(
                        icon: Icons.directions_walk_rounded,
                        color: AppColors.steps,
                        value: d.steps.compact,
                        label: 'of ${d.health.stepGoal.compact} steps',
                        progress: d.steps / d.health.stepGoal,
                        onTap: () => context.push('/health'),
                      ),
                      StatTile(
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.calories,
                        value: d.todayNutrition.calories.toKcal(),
                        label: 'of ${d.health.calorieTarget.toKcal()}',
                        progress:
                            d.todayNutrition.calories / d.health.calorieTarget,
                        onTap: () => context.push('/meals'),
                      ),
                      StatTile(
                        icon: Icons.egg_alt_rounded,
                        color: AppColors.protein,
                        value: '${d.todayNutrition.proteinG.round()} g',
                        label:
                            'of ${d.health.proteinTargetG.round()} g protein',
                        progress:
                            d.todayNutrition.proteinG / d.health.proteinTargetG,
                        onTap: () => context.push('/meals'),
                      ),
                      StatTile(
                        icon: Icons.water_drop_rounded,
                        color: AppColors.water,
                        value:
                            '${(d.waterMl / 1000).trimZeros()} L',
                        label:
                            'of ${(d.health.waterTargetMl / 1000).trimZeros()} L water',
                        progress: d.waterMl / d.health.waterTargetMl,
                        onTap: () => context.push('/health'),
                      ),
                      StatTile(
                        icon: Icons.bedtime_rounded,
                        color: AppColors.sleep,
                        value: d.sleepHours == null
                            ? '—'
                            : '${d.sleepHours!.trimZeros()} h',
                        label: 'sleep last night',
                        onTap: () => context.push('/health'),
                      ),
                      StatTile(
                        icon: Icons.favorite_rounded,
                        color: AppColors.heart,
                        value: d.heartRate == null
                            ? '—'
                            : '${d.heartRate!.round()} bpm',
                        label: 'heart rate',
                        onTap: () => context.push('/health'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HabitsCard(data: d),
                  const SizedBox(height: 12),
                  _QuickActions(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = data.score;
    final message = score.total >= 80
        ? 'Excellent day — keep it rolling.'
        : score.total >= 55
            ? 'Solid progress. Small steps add up.'
            : 'Every log makes today better. Start small.';
    return BodiCard(
      child: Row(
        children: [
          ProgressRing(
            progress: score.total / 100,
            size: 110,
            strokeWidth: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${score.total}', style: theme.textTheme.displaySmall),
                Text('today', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily health score',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(message, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                _ScoreBar(label: 'Move', value: score.movement,
                    color: AppColors.steps),
                _ScoreBar(label: 'Eat', value: score.nutrition,
                    color: AppColors.calories),
                _ScoreBar(label: 'Sleep', value: score.sleep,
                    color: AppColors.sleep),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar(
      {required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 44,
              child: Text(label, style: theme.textTheme.labelSmall)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 5,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyTrendCard extends StatelessWidget {
  const _BodyTrendCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = data;

    Widget trend(String label, double? value, String unit, double? delta,
        {bool downIsGood = true}) {
      final deltaText = delta == null
          ? null
          : '${delta > 0 ? '+' : ''}${delta.trimZeros()} $unit';
      final good = delta != null && (downIsGood ? delta <= 0 : delta >= 0);
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value == null ? '—' : '${value.trimZeros()} $unit',
                style: theme.textTheme.headlineSmall),
            if (deltaText != null)
              Text(
                deltaText,
                style: theme.textTheme.labelMedium?.copyWith(
                    color: good ? AppColors.success : AppColors.warning),
              ),
          ],
        ),
      );
    }

    return BodiCard(
      onTap: () {},
      child: Row(
        children: [
          trend('Weight', d.weightNow, 'kg', d.weightWeekDelta),
          trend('Waist', d.waistNow, 'cm', d.waistMonthDelta),
          trend('Body fat', d.health.estimatedBodyFatPct, '%', null),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (insight.severity) {
      InsightSeverity.celebrate => AppColors.success,
      InsightSeverity.info => AppColors.ocean,
      InsightSeverity.nudge => AppColors.sun,
      InsightSeverity.warning => AppColors.coral,
    };
    return BodiCard(
      onTap: () => context.push('/insights'),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(insight.body,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitsCard extends ConsumerWidget {
  const _HabitsCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (data.habitsDue.isEmpty) {
      return BodiCard(
        onTap: () => context.push('/habits'),
        child: Row(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Build your first habit — small and repeatable.',
                  style: theme.textTheme.titleMedium),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
    }
    return BodiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Habits', style: theme.textTheme.titleLarge),
              Text('${data.habitsDone}/${data.habitsDue.length} done',
                  style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 8),
          for (final habit in data.habitsDue.take(4))
            HabitCheckRow(habit: habit),
          if (data.habitsDue.length > 4)
            TextButton(
              onPressed: () => context.push('/habits'),
              child: Text('All ${data.habitsDue.length} habits'),
            ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget action(IconData icon, String label, String route, Color color) =>
        Expanded(
          child: BodiCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            onTap: () => context.push(route),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(label,
                    style: theme.textTheme.labelMedium,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );

    return Row(
      children: [
        action(Icons.photo_camera_rounded, 'Log meal', '/meals/log',
            AppColors.calories),
        const SizedBox(width: 10),
        action(Icons.fitness_center_rounded, 'Workout', '/workouts',
            AppColors.vital),
        const SizedBox(width: 10),
        action(Icons.monitor_weight_rounded, 'Weigh in', '/health/log',
            AppColors.ocean),
        const SizedBox(width: 10),
        action(Icons.description_rounded, 'Report', '/reports',
            AppColors.lavender),
      ],
    );
  }
}
