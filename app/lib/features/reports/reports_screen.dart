import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/empty_state.dart';
import 'report_controller.dart';
import 'report_pdf.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(weeklyReportProvider);
    final theme = Theme.of(context);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly report')),
        body: const EmptyState(
          icon: Icons.description_rounded,
          title: 'No report yet',
          message: 'Complete onboarding to start generating weekly reports.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export PDF',
            onPressed: () async {
              final bytes = await buildWeeklyReportPdf(report);
              await Printing.sharePdf(
                bytes: Uint8List.fromList(bytes),
                filename: 'bodi-weekly-report.pdf',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              _SummaryTile(
                  label: 'Avg calories',
                  value: '${report.avgCalories.round()}',
                  unit: 'kcal/day'),
              const SizedBox(width: 10),
              _SummaryTile(
                  label: 'Avg protein',
                  value: '${report.avgProtein.round()}',
                  unit: 'g/day'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryTile(
                  label: 'Habits kept',
                  value: '${report.habitsCompletionPct}',
                  unit: '%'),
              const SizedBox(width: 10),
              _SummaryTile(
                  label: 'Weight change',
                  value: report.weightDelta == null
                      ? '—'
                      : '${report.weightDelta! >= 0 ? '+' : ''}${report.weightDelta!.toStringAsFixed(1)}',
                  unit: 'kg'),
            ],
          ),
          SectionHeader('Calories eaten'),
          BodiCard(
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= report.days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('E')
                                  .format(report.days[index].day)[0],
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(enabled: false),
                  barGroups: [
                    for (var i = 0; i < report.days.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: report.days[i].calories,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.calories,
                        ),
                      ]),
                  ],
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: report.health.calorieTarget,
                      color: theme.colorScheme.onSurfaceVariant,
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    ),
                  ]),
                ),
              ),
            ),
          ),
          SectionHeader('Steps'),
          BodiCard(
            child: SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  barGroups: [
                    for (var i = 0; i < report.days.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: report.days[i].steps.toDouble(),
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.steps,
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ),
          SectionHeader('Week at a glance'),
          BodiCard(
            child: Column(
              children: [
                _GlanceRow(
                    label: 'Meals logged', value: '${report.mealsLogged}'),
                _GlanceRow(
                    label: 'Workouts completed',
                    value: '${report.workoutsCompleted}'),
                _GlanceRow(
                    label: 'Avg water',
                    value:
                        '${(report.avgWater / 1000).trimZeros()} L / day'),
                _GlanceRow(
                    label: 'Avg sleep',
                    value: report.avgSleep == null
                        ? '—'
                        : '${report.avgSleep!.toStringAsFixed(1)} h'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(
      {required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: BodiCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: theme.textTheme.headlineMedium),
                const SizedBox(width: 4),
                Text(unit, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlanceRow extends StatelessWidget {
  const _GlanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
