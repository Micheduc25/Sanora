import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/food_item.dart';

/// Bundled reference food database (African foods first-class), loaded once
/// from assets. The Supabase `foods` table mirrors this and allows server-side
/// expansion without an app release.
class FoodRepository {
  List<FoodItem>? _cache;

  Future<List<FoodItem>> allFoods() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/foods.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }

  Future<List<FoodItem>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allFoods();
    final foods = await allFoods();
    bool matches(FoodItem f) =>
        f.name.toLowerCase().contains(q) ||
        f.aliases.any((a) => a.toLowerCase().contains(q)) ||
        f.category.toLowerCase().contains(q);
    final results = foods.where(matches).toList()
      ..sort((a, b) {
        final aStarts = a.name.toLowerCase().startsWith(q) ? 0 : 1;
        final bStarts = b.name.toLowerCase().startsWith(q) ? 0 : 1;
        return aStarts != bStarts
            ? aStarts - bStarts
            : a.name.compareTo(b.name);
      });
    return results;
  }

  Future<List<String>> categories() async {
    final foods = await allFoods();
    return foods.map((f) => f.category).toSet().toList()..sort();
  }
}
