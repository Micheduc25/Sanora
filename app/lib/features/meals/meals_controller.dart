import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../../core/providers/app_providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/nutrition.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_controller.dart';
import '../onboarding/onboarding_controller.dart';

final mealsListProvider = Provider.autoDispose(
  (ref) => ref.watch(mealsRepositoryProvider).all(),
);

final foodSearchProvider = FutureProvider.autoDispose
    .family<List<FoodItem>, String>(
      (ref, query) => ref.watch(foodRepositoryProvider).search(query),
    );

class MealsController {
  MealsController(this._ref);

  final Ref _ref;

  void _refresh() {
    _ref.invalidate(mealsListProvider);
    _ref.invalidate(dashboardProvider);
  }

  Meal draftFromFood(FoodItem food, {double? portionG, MealType? type}) {
    final grams = portionG ?? food.typicalServingG;
    final nutrition = food.nutritionPer100g.scale(grams / 100);
    return Meal(
      id: const Uuid().v4(),
      name: food.name,
      type: type ?? MealType.forTime(DateTime.now()),
      source: MealSource.database,
      components: [
        MealComponent(name: food.name, portionG: grams, nutrition: nutrition),
      ],
      nutrition: nutrition,
      // Looked up, not estimated — the detail sheet labels database entries
      // by source rather than quoting a confidence.
      confidence: 1,
      eatenAt: DateTime.now(),
    );
  }

  /// AI photo analysis. Requires a signed-in session; throws
  /// [AiUnavailableFailure] otherwise so the UI can point to search instead.
  ///
  /// [l] carries the caller's localizations: [Failure] is sealed in `core/` and
  /// holds finished copy, so the message has to be resolved before it is
  /// thrown rather than at the catch site.
  Future<Meal> analyzePhoto(File image, L l) async {
    final profile = _ref.read(userProfileProvider);
    if (profile == null) {
      throw ValidationFailure(l.mealsCompleteOnboardingFirst);
    }
    final bytes = await image.readAsBytes();
    if (bytes.length > 6 * 1024 * 1024) {
      throw ValidationFailure(l.mealsPhotoTooLarge);
    }
    final meal = await _ref
        .read(aiServiceProvider)
        .analyzeMeal(imageBase64: base64Encode(bytes), profile: profile);
    return meal.copyWith(
      id: const Uuid().v4(),
      source: MealSource.photo,
      photoPath: image.path,
    );
  }

  /// Text/voice description → AI when online, local food-database matching
  /// as the offline path.
  Future<Meal> analyzeDescription(String description, L l) async {
    final profile = _ref.read(userProfileProvider);
    if (profile == null) {
      throw ValidationFailure(l.mealsCompleteOnboardingFirst);
    }
    try {
      final meal = await _ref
          .read(aiServiceProvider)
          .analyzeMeal(description: description, profile: profile);
      return meal.copyWith(id: const Uuid().v4(), source: MealSource.text);
    } on Failure catch (f) {
      // No connection, or no AI allowance left today — either way the bundled
      // African-first food database can still log this meal.
      if (f is AiUnavailableFailure || f is QuotaFailure) {
        return _matchLocally(description, l);
      }
      rethrow;
    }
  }

  Future<Meal> _matchLocally(String description, L l) async {
    final foods = _ref.read(foodRepositoryProvider);
    // Splits what the user typed, not what the UI displays: people describe a
    // plate in either language whatever the app locale is, so both separators
    // stay regardless of the active translation.
    final words = description
        .toLowerCase()
        .split(RegExp(r'[,;+&]| with | and | et '))
        .map((w) => w.trim())
        .where((w) => w.length > 2);
    final components = <MealComponent>[];
    for (final word in words) {
      final matches = await foods.search(word);
      if (matches.isEmpty) continue;
      final food = matches.first;
      components.add(
        MealComponent(
          name: food.name,
          portionG: food.typicalServingG,
          nutrition: food.nutritionPer100g.scale(food.typicalServingG / 100),
        ),
      );
    }
    if (components.isEmpty) {
      throw ValidationFailure(l.mealsOfflineNoMatch);
    }
    final total = components.fold(
      const Nutrition(),
      (sum, c) => sum + c.nutrition,
    );
    return Meal(
      id: const Uuid().v4(),
      name: description.trim().capitalizeFirst(),
      type: MealType.forTime(DateTime.now()),
      source: MealSource.text,
      components: components,
      nutrition: total,
      confidence: 0.6,
      aiNotes: l.mealsOfflineNotes,
      eatenAt: DateTime.now(),
    );
  }

  Future<void> save(Meal meal) async {
    await _ref.read(mealsRepositoryProvider).save(meal);
    _refresh();
  }

  Future<void> remove(String id) async {
    await _ref.read(mealsRepositoryProvider).remove(id);
    _refresh();
  }

  Future<void> toggleFavorite(Meal meal) async {
    await _ref.read(mealsRepositoryProvider).toggleFavorite(meal);
    _refresh();
  }
}

final mealsControllerProvider = Provider((ref) => MealsController(ref));

extension on String {
  String capitalizeFirst() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
