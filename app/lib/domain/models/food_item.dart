import 'package:freezed_annotation/freezed_annotation.dart';

import 'nutrition.dart';

part 'food_item.freezed.dart';
part 'food_item.g.dart';

/// A food in the reference database. [nutritionPer100g] is the canonical
/// basis; [typicalServingG] drives the default portion suggestion.
@freezed
abstract class FoodItem with _$FoodItem {
  const factory FoodItem({
    required String id,
    required String name,
    @Default([]) List<String> aliases,
    @Default('') String region,
    @Default('') String category,
    required Nutrition nutritionPer100g,
    @Default(100) double typicalServingG,
    @Default('') String servingLabel,
  }) = _FoodItem;

  factory FoodItem.fromJson(Map<String, dynamic> json) =>
      _$FoodItemFromJson(json);
}
