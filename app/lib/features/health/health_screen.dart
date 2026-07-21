import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/bodi_card.dart';
import '../../domain/models/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/metric_entry.dart';
import '../habits/habits_controller.dart';

final metricsVersionProvider = StateProvider((ref) => 0);

/// Every stored entry grouped by type, newest first. Rebuilt whenever
/// [metricsVersionProvider] is bumped so a single box read serves all cards.
final metricEntriesProvider = Provider<Map<MetricType, List<MetricEntry>>>((
  ref,
) {
  ref.watch(metricsVersionProvider);
  final grouped = <MetricType, List<MetricEntry>>{};
  for (final entry in ref.watch(metricsRepositoryProvider).all()) {
    grouped.putIfAbsent(entry.type, () => []).add(entry);
  }
  return grouped;
});

/// Chart values in chronological order — daily totals for additive metrics
/// (water), raw readings for everything else.
List<double> _series(List<MetricEntry> entries, {required bool additive}) {
  if (!additive) {
    return [for (final e in entries.take(30)) e.value].reversed.toList();
  }
  final byDay = <DateTime, double>{};
  for (final e in entries) {
    final day = e.recordedAt.dateOnly;
    byDay[day] = (byDay[day] ?? 0) + e.value;
  }
  final days = byDay.keys.toList()..sort();
  return [
    for (final d in days.skip(days.length > 14 ? days.length - 14 : 0))
      byDay[d]!,
  ];
}

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesByType = ref.watch(metricEntriesProvider);
    final habits = ref.watch(habitsListProvider);
    final theme = Theme.of(context);
    final today = DateTime.now();

    Widget metricCard(MetricType type, Color color, {bool additive = false}) {
      final entries = entriesByType[type] ?? const <MetricEntry>[];
      final series = _series(entries, additive: additive);
      final double? latest = entries.isEmpty
          ? null
          : additive
          ? entries
                .where((e) => e.recordedAt.isSameDay(today))
                .fold<double>(0, (sum, e) => sum + e.value)
          : entries.first.value;
      return BodiCard(
        padding: const EdgeInsets.all(16),
        onTap: () => context.push('/health/log?type=${type.name}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type.label,
              style: theme.textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  latest == null || (additive && latest == 0)
                      ? '—'
                      : '${latest.trimZeros()} ${type.unit}',
                  style: theme.textTheme.headlineSmall,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: series.length >= 2
                  ? MetricSparkline(values: series, color: color)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entries.isEmpty
                            ? L.of(context).healthTapToLog
                            : entries.first.recordedAt.friendlyDay,
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(L.of(context).healthTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Insights',
            onPressed: () => context.push('/insights'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // The shell keeps every visited tab alive in one IndexedStack, so the
        // FABs of other tabs are in this route's subtree too. Without distinct
        // tags they collide on the default one and the next push throws.
        heroTag: 'fab-health',
        onPressed: () => context.push('/health/log'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              // Fixed height rather than an aspect ratio: card content does not
              // scale with width, and 1.5 clipped it on narrow phones.
              mainAxisExtent:
                  132 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.6),
            ),
            children: [
              metricCard(MetricType.weight, AppColors.ocean),
              metricCard(MetricType.waist, AppColors.vital),
              metricCard(MetricType.hip, AppColors.vitalDark),
              metricCard(MetricType.bodyFat, AppColors.lavender),
              metricCard(MetricType.water, AppColors.water, additive: true),
              metricCard(MetricType.steps, AppColors.steps, additive: true),
              metricCard(MetricType.sleep, AppColors.sleep),
              metricCard(MetricType.heartRate, AppColors.heart),
              metricCard(MetricType.bpSystolic, AppColors.coral),
              metricCard(MetricType.bpDiastolic, AppColors.coral),
              metricCard(MetricType.bloodSugar, AppColors.sun),
              metricCard(MetricType.mood, AppColors.rose),
              metricCard(MetricType.stress, AppColors.warning),
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
                  title: Text(L.of(context).workoutsTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/workouts'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded),
                  title: Text(L.of(context).remindersTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/reminders'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.description_rounded),
                  title: Text(L.of(context).reportsTitle),
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
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
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
