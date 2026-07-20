import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/bodi_card.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/metric_entry.dart';
import '../habits/habits_controller.dart';

final metricsVersionProvider = StateProvider((ref) => 0);

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(metricsVersionProvider);
    final metrics = ref.watch(metricsRepositoryProvider);
    final habits = ref.watch(habitsListProvider);
    final theme = Theme.of(context);
    final today = DateTime.now();

    Widget metricCard(MetricType type, Color color, {bool additive = false}) {
      final entries = metrics.byType(type).take(30).toList().reversed.toList();
      final latest = additive
          ? metrics.dayTotal(type, today)
          : metrics.latest(type)?.value;
      return BodiCard(
        padding: const EdgeInsets.all(16),
        onTap: () => context.push('/health/log?type=${type.name}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type.label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              latest == null || (additive && latest == 0)
                  ? '—'
                  : '${latest.trimZeros()} ${type.unit}',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: entries.length >= 2
                  ? MetricSparkline(entries: entries, color: color)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tap to log',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Insights',
            onPressed: () => context.push('/insights'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/health/log'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              metricCard(MetricType.weight, AppColors.ocean),
              metricCard(MetricType.waist, AppColors.vital),
              metricCard(MetricType.bodyFat, AppColors.lavender),
              metricCard(MetricType.water, AppColors.water, additive: true),
              metricCard(MetricType.sleep, AppColors.sleep),
              metricCard(MetricType.heartRate, AppColors.heart),
              metricCard(MetricType.bpSystolic, AppColors.coral),
              metricCard(MetricType.bloodSugar, AppColors.sun),
              metricCard(MetricType.mood, AppColors.rose),
              metricCard(MetricType.energy, AppColors.calories),
            ],
          ),
          SectionHeader(
            'Habits',
            action: 'Manage',
            onAction: () => context.push('/habits'),
          ),
          if (habits.isEmpty)
            BodiCard(
              onTap: () => context.push('/habits'),
              child: Row(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Start a habit — small beats perfect.',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            )
          else
            BodiCard(
              child: Column(
                children: [
                  for (final habit in habits.where((h) => h.active))
                    HabitCheckRow(habit: habit),
                ],
              ),
            ),
          SectionHeader('More'),
          BodiCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.fitness_center_rounded),
                  title: const Text('Workouts'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/workouts'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded),
                  title: const Text('Smart reminders'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/reminders'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.description_rounded),
                  title: const Text('Weekly report'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/reports'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricSparkline extends StatelessWidget {
  const MetricSparkline({
    super.key,
    required this.entries,
    required this.color,
  });

  final List<MetricEntry> entries;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].value),
    ];
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 2.5,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
    );
  }
}
