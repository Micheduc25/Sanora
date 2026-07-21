import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdfcolors;
import 'package:pdf/widgets.dart' as pw;

import '../../l10n/app_localizations.dart';
import 'report_controller.dart';

/// Renders the weekly report as a shareable PDF document.
///
/// The caller passes its `L` in: this runs outside the widget tree, and after
/// the export button's first await there is no BuildContext left to read.
Future<List<int>> buildWeeklyReportPdf(L l, WeeklyReport report) async {
  final doc = pw.Document();
  final green = pdfcolors.PdfColor.fromHex('#10A56D');
  final ink = pdfcolors.PdfColor.fromHex('#17211C');
  final muted = pdfcolors.PdfColor.fromHex('#5C6B63');
  final dateFormat = DateFormat('d MMM');
  final range =
      '${dateFormat.format(report.days.first.day)} – ${dateFormat.format(report.days.last.day)}';

  pw.Widget stat(String label, String value) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pdfcolors.PdfColor.fromHex('#E6EAE7')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: ink,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: muted)),
        ],
      ),
    ),
  );

  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Sanora',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: green,
                  ),
                ),
                pw.Text(
                  l.reportsPdfSubtitle,
                  style: pw.TextStyle(fontSize: 12, color: ink),
                ),
              ],
            ),
            pw.Text(range, style: pw.TextStyle(fontSize: 10, color: muted)),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            stat(
              l.reportsPdfAvgCaloriesPerDay,
              '${report.avgCalories.round()} kcal',
            ),
            stat(
              l.reportsPdfAvgProteinPerDay,
              '${report.avgProtein.round()} g',
            ),
            stat(l.reportsPdfAvgStepsPerDay, '${report.avgSteps.round()}'),
            stat(l.reportsPdfHabitCompletion, '${report.habitsCompletionPct}%'),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            stat(l.reportsMealsLogged, '${report.mealsLogged}'),
            stat(l.reportsWorkoutsCompleted, '${report.workoutsCompleted}'),
            stat(
              l.reportsWeightChange,
              report.weightDelta == null
                  ? '—'
                  : '${report.weightDelta! >= 0 ? '+' : ''}${report.weightDelta!.toStringAsFixed(1)} kg',
            ),
            stat(
              l.reportsAvgSleep,
              report.avgSleep == null
                  ? '—'
                  : '${report.avgSleep!.toStringAsFixed(1)} h',
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          l.reportsPdfDailyBreakdown,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: ink,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: pdfcolors.PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(color: green),
          cellStyle: pw.TextStyle(fontSize: 9, color: ink),
          cellAlignment: pw.Alignment.centerLeft,
          headers: [
            l.reportsPdfColDay,
            l.reportsPdfColCalories,
            l.reportsPdfColProtein,
            l.metricWater,
            l.metricSteps,
            l.metricSleep,
            l.metricWeight,
          ],
          data: [
            for (final day in report.days)
              [
                DateFormat('EEE d').format(day.day),
                '${day.calories.round()} kcal',
                '${day.proteinG.round()} g',
                '${(day.waterMl / 1000).toStringAsFixed(1)} L',
                '${day.steps}',
                day.sleepHours == null
                    ? '—'
                    : '${day.sleepHours!.toStringAsFixed(1)} h',
                day.weightKg == null
                    ? '—'
                    : '${day.weightKg!.toStringAsFixed(1)} kg',
              ],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          l.reportsPdfTargets,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: ink,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Bullet(
          text: l.reportsPdfTargetsIntake(
            '${report.health.calorieTarget.round()}',
            '${report.health.proteinTargetG.round()}',
            (report.health.waterTargetMl / 1000).toStringAsFixed(1),
          ),
          style: pw.TextStyle(fontSize: 10, color: ink),
        ),
        pw.Bullet(
          text: l.reportsPdfTargetsActivity(
            '${report.health.stepGoal}',
            '${report.health.sleepGoalHours}',
            '${report.health.exerciseMinutesPerWeek}',
          ),
          style: pw.TextStyle(fontSize: 10, color: ink),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          l.reportsPdfFooter,
          style: pw.TextStyle(fontSize: 8, color: muted),
        ),
      ],
    ),
  );

  return doc.save();
}
