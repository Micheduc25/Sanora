import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrition.freezed.dart';
part 'nutrition.g.dart';

@freezed
abstract class Nutrition with _$Nutrition {
  const Nutrition._();

  const factory Nutrition({
    @Default(0) double calories,
    @Default(0) double proteinG,
    @Default(0) double fatG,
    @Default(0) double carbsG,
    @Default(0) double fiberG,
    @Default(0) double sugarG,
    @Default(0) double sodiumMg,
    @Default({}) Map<String, double> micronutrients,
  }) = _Nutrition;

  factory Nutrition.fromJson(Map<String, dynamic> json) =>
      _$NutritionFromJson(json);

  Nutrition operator +(Nutrition other) => Nutrition(
    calories: calories + other.calories,
    proteinG: proteinG + other.proteinG,
    fatG: fatG + other.fatG,
    carbsG: carbsG + other.carbsG,
    fiberG: fiberG + other.fiberG,
    sugarG: sugarG + other.sugarG,
    sodiumMg: sodiumMg + other.sodiumMg,
    micronutrients: {
      ...micronutrients,
      for (final e in other.micronutrients.entries)
        e.key: (micronutrients[e.key] ?? 0) + e.value,
    },
  );

  Nutrition scale(double factor) => Nutrition(
    calories: calories * factor,
    proteinG: proteinG * factor,
    fatG: fatG * factor,
    carbsG: carbsG * factor,
    fiberG: fiberG * factor,
    sugarG: sugarG * factor,
    sodiumMg: sodiumMg * factor,
    micronutrients: micronutrients.map((k, v) => MapEntry(k, v * factor)),
  );
}
