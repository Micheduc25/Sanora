import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdfcolors;
import 'package:pdf/widgets.dart' as pw;

import 'report_controller.dart';

/// Renders the weekly report as a shareable PDF document.
Future<List<int>> buildWeeklyReportPdf(WeeklyReport report) async {
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
                  'Bodi',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: green,
                  ),
                ),
                pw.Text(
                  'Weekly Health Report',
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
            stat('Avg calories / day', '${report.avgCalories.round()} kcal'),
            stat('Avg protein / day', '${report.avgProtein.round()} g'),
            stat('Avg steps / day', '${report.avgSteps.round()}'),
            stat('Habit completion', '${report.habitsCompletionPct}%'),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            stat('Meals logged', '${report.mealsLogged}'),
            stat('Workouts completed', '${report.workoutsCompleted}'),
            stat(
              'Weight change',
              report.weightDelta == null
                  ? '—'
                  : '${report.weightDelta! >= 0 ? '+' : ''}${report.weightDelta!.toStringAsFixed(1)} kg',
            ),
            stat(
              'Avg sleep',
              report.avgSleep == null
                  ? '—'
                  : '${report.avgSleep!.toStringAsFixed(1)} h',
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Daily breakdown',
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
            'Day',
            'Calories',
            'Protein',
            'Water',
            'Steps',
            'Sleep',
            'Weight',
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
          'Your targets',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: ink,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Bullet(
          text:
              'Calories: ${report.health.calorieTarget.round()} kcal · Protein: ${report.health.proteinTargetG.round()} g · Water: ${(report.health.waterTargetMl / 1000).toStringAsFixed(1)} L',
          style: pw.TextStyle(fontSize: 10, color: ink),
        ),
        pw.Bullet(
          text:
              'Steps: ${report.health.stepGoal} · Sleep: ${report.health.sleepGoalHours} h · Exercise: ${report.health.exerciseMinutesPerWeek} min/week',
          style: pw.TextStyle(fontSize: 10, color: ink),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Generated by Bodi. This report is informational and not a substitute for professional medical advice.',
          style: pw.TextStyle(fontSize: 8, color: muted),
        ),
      ],
    ),
  );

  return doc.save();
}
