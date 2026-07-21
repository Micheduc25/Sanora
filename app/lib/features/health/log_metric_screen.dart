import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/extensions.dart';
import '../../domain/models/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/metric_entry.dart';
import '../onboarding/onboarding_controller.dart';

/// Logging any body metric. Weight/waist/hip/body-fat also update the
/// profile so the health engine recomputes targets.
class LogMetricScreen extends HookConsumerWidget {
  const LogMetricScreen({super.key, this.initialType});

  final MetricType? initialType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = useState(initialType ?? MetricType.weight);
    final theme = Theme.of(context);

    final defaults = {
      MetricType.weight: ref.read(userProfileProvider)?.weightKg ?? 75.0,
      MetricType.waist: ref.read(userProfileProvider)?.waistCm ?? 85.0,
      MetricType.hip: ref.read(userProfileProvider)?.hipCm ?? 95.0,
      MetricType.bodyFat: ref.read(userProfileProvider)?.bodyFatPct ?? 25.0,
      MetricType.water: 250.0,
      MetricType.sleep: 7.0,
      MetricType.heartRate: 70.0,
      MetricType.bpSystolic: 120.0,
      MetricType.bpDiastolic: 80.0,
      MetricType.bloodSugar: 95.0,
      MetricType.mood: 3.0,
      MetricType.stress: 3.0,
      MetricType.energy: 3.0,
      MetricType.steps: 5000.0,
    };
    final value = useState(defaults[type.value] ?? 0.0);
    final note = useTextEditingController();

    useEffect(() {
      value.value = defaults[type.value] ?? 0.0;
      return null;
    }, [type.value]);

    final (min, max, step) = switch (type.value) {
      MetricType.weight => (35.0, 200.0, 0.1),
      MetricType.waist => (50.0, 160.0, 0.5),
      MetricType.hip => (60.0, 170.0, 0.5),
      MetricType.bodyFat => (4.0, 60.0, 0.5),
      MetricType.water => (50.0, 2000.0, 50.0),
      MetricType.sleep => (0.0, 14.0, 0.25),
      MetricType.heartRate => (35.0, 200.0, 1.0),
      MetricType.bpSystolic => (80.0, 220.0, 1.0),
      MetricType.bpDiastolic => (40.0, 140.0, 1.0),
      MetricType.bloodSugar => (40.0, 400.0, 1.0),
      MetricType.mood ||
      MetricType.stress ||
      MetricType.energy => (1.0, 5.0, 1.0),
      MetricType.steps => (0.0, 40000.0, 500.0),
      _ => (0.0, 100.0, 1.0),
    };

    Future<void> save() async {
      final entry = MetricEntry(
        id: const Uuid().v4(),
        type: type.value,
        value: value.value,
        note: note.text.trim(),
        recordedAt: DateTime.now(),
      );
      await ref.read(metricsRepositoryProvider).add(entry);

      final profile = ref.read(userProfileProvider);
      if (profile != null) {
        final updated = switch (type.value) {
          MetricType.weight => profile.copyWith(weightKg: value.value),
          MetricType.waist => profile.copyWith(waistCm: value.value),
          MetricType.hip => profile.copyWith(hipCm: value.value),
          MetricType.bodyFat => profile.copyWith(bodyFatPct: value.value),
          _ => null,
        };
        if (updated != null) {
          await ref
              .read(profileRepositoryProvider)
              .saveProfile(updated.copyWith(updatedAt: DateTime.now()));
          ref.invalidate(userProfileProvider);
          ref.invalidate(healthProfileProvider);
        }
      }

      if (context.mounted) context.pop();
    }

    final loggable = MetricType.values
        .where((t) => t != MetricType.symptom && t != MetricType.medication)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(L.of(context).healthLogMeasurement)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in loggable)
                ChoiceChip(
                  label: Text(t.label),
                  selected: type.value == t,
                  showCheckmark: false,
                  onSelected: (_) => type.value = t,
                ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.value.trimZeros(step < 1 ? 1 : 0),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(type.value.unit, style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
          Slider(
            value: value.value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: (v) => value.value = v,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            decoration: InputDecoration(hintText: L.of(context).healthAddNote),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: save, child: const Text('Save')),
        ],
      ),
    );
  }
}
