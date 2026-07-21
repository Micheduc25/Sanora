import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/sanora_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';
import 'report_controller.dart';
import 'report_pdf.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    return ref
        .watch(weeklyReportProvider)
        .when(
          loading: () => const _ReportShell(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _ReportShell(
            child: EmptyState(
              icon: Icons.description_rounded,
              title: l.reportsErrorTitle,
              message: l.reportsErrorMessage,
            ),
          ),
          data: (report) => report == null
              ? _ReportShell(
                  child: EmptyState(
                    icon: Icons.description_rounded,
                    title: l.reportsEmptyTitle,
                    message: l.reportsEmptyMessage,
                  ),
                )
              : _buildReport(context, report),
        );
  }

  Widget _buildReport(BuildContext context, WeeklyReport report) {
    final theme = Theme.of(context);
    final l = L.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.reportsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: l.reportsExportTooltip,
            onPressed: () => _exportPdf(context, report),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              _SummaryTile(
                label: l.reportsAvgCalories,
                value: '${report.avgCalories.round()}',
                unit: l.reportsUnitKcalPerDay,
              ),
              const SizedBox(width: 10),
              _SummaryTile(
                label: l.reportsAvgProtein,
                value: '${report.avgProtein.round()}',
                unit: l.reportsUnitGramsPerDay,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryTile(
                label: l.reportsHabitsKept,
                value: '${report.habitsCompletionPct}',
                unit: '%',
              ),
              const SizedBox(width: 10),
              _SummaryTile(
                label: l.reportsWeightChange,
                value: report.weightDelta == null
                    ? '—'
                    : '${report.weightDelta! >= 0 ? '+' : ''}${report.weightDelta!.toStringAsFixed(1)}',
                unit: 'kg',
              ),
            ],
          ),
          SectionHeader(l.reportsCaloriesEaten),
          SanoraCard(
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
                              DateFormat('E').format(report.days[index].day)[0],
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
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: report.days[i].calories,
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.calories,
                          ),
                        ],
                      ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: report.health.calorieTarget,
                        color: theme.colorScheme.onSurfaceVariant,
                        strokeWidth: 1,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SectionHeader(l.metricSteps),
          SanoraCard(
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
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: report.days[i].steps.toDouble(),
                            width: 18,
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.steps,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          SectionHeader(l.reportsWeekAtAGlance),
          SanoraCard(
            child: Column(
              children: [
                _GlanceRow(
                  label: l.reportsMealsLogged,
                  value: '${report.mealsLogged}',
                ),
                _GlanceRow(
                  label: l.reportsWorkoutsCompleted,
                  value: '${report.workoutsCompleted}',
                ),
                _GlanceRow(
                  label: l.reportsAvgWater,
                  value: l.reportsLitresPerDay(
                    (report.avgWater / 1000).trimZeros(),
                  ),
                ),
                _GlanceRow(
                  label: l.reportsAvgSleep,
                  value: report.avgSleep == null
                      ? '—'
                      : l.reportsHours(report.avgSleep!.toStringAsFixed(1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sharing can fail for reasons the user can act on (no share targets, a
/// cancelled sheet, a full disk), and silently swallowing that looks like the
/// export button is broken.
Future<void> _exportPdf(BuildContext context, WeeklyReport report) async {
  // Read the strings before the first await: the PDF builder has no
  // BuildContext of its own, and after an await this one may be gone.
  final l = L.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await buildWeeklyReportPdf(l, report);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'sanora-weekly-report.pdf',
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.reportsExportError)));
  }
}

class _ReportShell extends StatelessWidget {
  const _ReportShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(L.of(context).reportsTitle)),
    body: child,
  );
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: SanoraCard(
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
