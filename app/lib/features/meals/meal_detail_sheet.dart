import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/meal.dart';
import 'meals_controller.dart';

/// Shows an analyzed or logged meal. When [editable] the sheet acts as a
/// confirmation step (Save / discard); otherwise it is a read-only detail
/// view with delete.
Future<void> showMealDetailSheet(
  BuildContext context,
  Meal meal, {
  required bool editable,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MealDetailSheet(meal: meal, editable: editable),
  );
}

class _MealDetailSheet extends ConsumerWidget {
  const _MealDetailSheet({required this.meal, required this.editable});

  final Meal meal;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final n = meal.nutrition;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          if (meal.photoPath != null && File(meal.photoPath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              child: Image.file(
                File(meal.photoPath!),
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(meal.name, style: theme.textTheme.headlineSmall),
              ),
              _ConfidencePill(confidence: meal.confidence),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${meal.type.label} · estimated portion sizes',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _MacroChip(
                label: 'kcal',
                value: n.calories.round().toString(),
                color: AppColors.calories,
              ),
              _MacroChip(
                label: 'protein',
                value: '${n.proteinG.round()}g',
                color: AppColors.protein,
              ),
              _MacroChip(
                label: 'carbs',
                value: '${n.carbsG.round()}g',
                color: AppColors.carbs,
              ),
              _MacroChip(
                label: 'fat',
                value: '${n.fatG.round()}g',
                color: AppColors.fat,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              Text(
                'Fiber ${n.fiberG.round()}g',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Sugar ${n.sugarG.round()}g',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Sodium ${n.sodiumMg.round()}mg',
                style: theme.textTheme.bodySmall,
              ),
              for (final micro in n.micronutrients.entries.take(4))
                Text(
                  '${_microLabel(micro.key)} ${micro.value.round()}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          if (meal.components.length > 1) ...[
            const SizedBox(height: 20),
            Text('On the plate', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final component in meal.components)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        component.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${component.portionG.round()}g · ${component.nutrition.calories.round()} kcal',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
          if (meal.aiNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Text(meal.aiNotes, style: theme.textTheme.bodyMedium),
            ),
          ],
          if (meal.healthierSwaps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Healthier swaps', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final swap in meal.healthierSwaps)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 '),
                    Expanded(
                      child: Text(swap, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 24),
          if (editable)
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save meal'),
              onPressed: () async {
                await ref.read(mealsControllerProvider).save(meal);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).maybePop();
                }
              },
            )
          else
            OutlinedButton.icon(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
              label: Text(
                'Delete',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onPressed: () async {
                await ref.read(mealsControllerProvider).remove(meal.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  String _microLabel(String key) => key
      .replaceAll('_', ' ')
      .replaceFirst('mg', '(mg)')
      .replaceFirst('ug', '(µg)');
}

class _ConfidencePill extends StatelessWidget {
  const _ConfidencePill({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (confidence * 100).round();
    final color = confidence >= 0.8
        ? AppColors.success
        : confidence >= 0.6
        ? AppColors.sun
        : AppColors.coral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$pct% sure',
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
