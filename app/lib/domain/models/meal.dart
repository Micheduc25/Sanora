import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'nutrition.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

@freezed
abstract class MealComponent with _$MealComponent {
  const factory MealComponent({
    required String name,
    required double portionG,
    required Nutrition nutrition,
  }) = _MealComponent;

  factory MealComponent.fromJson(Map<String, dynamic> json) =>
      _$MealComponentFromJson(json);
}

@freezed
abstract class Meal with _$Meal {
  const Meal._();

  const factory Meal({
    required String id,
    required String name,
    required MealType type,
    required MealSource source,
    @Default([]) List<MealComponent> components,
    required Nutrition nutrition,
    @Default(0.8) double confidence,
    String? photoPath,
    @Default('') String aiNotes,
    @Default([]) List<String> healthierSwaps,
    @Default(false) bool isFavorite,
    required DateTime eatenAt,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
