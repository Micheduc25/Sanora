import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/nutrition.dart';
import '../onboarding/onboarding_controller.dart';
import 'meal_detail_sheet.dart';
import 'meals_controller.dart';

class MealsScreen extends ConsumerWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsListProvider);
    final health = ref.watch(healthProfileProvider);
    final theme = Theme.of(context);
    final todayMeals = meals.where((m) => m.eatenAt.isToday).toList();
    final todayTotal = todayMeals.fold(
      const Nutrition(),
      (Nutrition sum, m) => sum + m.nutrition,
    );

    final byDay = <String, List<Meal>>{};
    for (final meal in meals) {
      byDay.putIfAbsent(meal.eatenAt.dayKey, () => []).add(meal);
    }
    final dayKeys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/meals/log'),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Log meal'),
      ),
      body: meals.isEmpty
          ? EmptyState(
              icon: Icons.restaurant_rounded,
              title: 'What did you eat today?',
              message:
                  'Snap a photo, describe it, or search the food database — Bodi estimates the nutrition for you.',
              actionLabel: 'Log your first meal',
              onAction: () => context.push('/meals/log'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                if (health != null)
                  BodiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Today', style: theme.textTheme.titleLarge),
                            Text(
                              '${todayTotal.calories.round()} / ${health.calorieTarget.round()} kcal',
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _MacroBar(
                          label: 'Protein',
                          value: todayTotal.proteinG,
                          goal: health.proteinTargetG,
                          unit: 'g',
                          color: AppColors.protein,
                        ),
                        _MacroBar(
                          label: 'Carbs',
                          value: todayTotal.carbsG,
                          goal: health.calorieTarget * 0.5 / 4,
                          unit: 'g',
                          color: AppColors.carbs,
                        ),
                        _MacroBar(
                          label: 'Fat',
                          value: todayTotal.fatG,
                          goal: health.calorieTarget * 0.3 / 9,
                          unit: 'g',
                          color: AppColors.fat,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                for (final key in dayKeys) ...[
                  SectionHeader(byDay[key]!.first.eatenAt.friendlyDay),
                  for (final meal in byDay[key]!) _MealRow(meal: meal),
                ],
              ],
            ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${value.round()}/${goal.round()} $unit',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _MealRow extends ConsumerWidget {
  const _MealRow({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final emoji = switch (meal.type) {
      MealType.breakfast => '🍳',
      MealType.lunch => '🍛',
      MealType.dinner => '🍲',
      MealType.snack => '🍌',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BodiCard(
        padding: const EdgeInsets.all(14),
        onTap: () => showMealDetailSheet(context, meal, editable: false),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${meal.type.label} · ${meal.eatenAt.timeLabel} · ${meal.nutrition.proteinG.round()}g protein',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.nutrition.calories.round()}',
                  style: theme.textTheme.titleMedium,
                ),
                Text('kcal', style: theme.textTheme.labelSmall),
              ],
            ),
            IconButton(
              icon: Icon(
                meal.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: meal.isFavorite ? AppColors.rose : null,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(mealsControllerProvider).toggleFavorite(meal),
            ),
          ],
        ),
      ),
    );
  }
}
