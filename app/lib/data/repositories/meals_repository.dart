import '../../core/storage/local_store.dart';
import '../../core/utils/extensions.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/nutrition.dart';
import '../sync/sync_service.dart';

class MealsRepository {
  MealsRepository(this._sync);

  final SyncService _sync;

  List<Meal> all() =>
      LocalStore.readAll(LocalStore.mealsBox, Meal.fromJson)
        ..sort((a, b) => b.eatenAt.compareTo(a.eatenAt));

  List<Meal> forDay(DateTime day) =>
      all().where((m) => m.eatenAt.isSameDay(day)).toList();

  List<Meal> favorites() => all().where((m) => m.isFavorite).toList();

  Nutrition dayNutrition(DateTime day) => forDay(
    day,
  ).fold(const Nutrition(), (total, meal) => total + meal.nutrition);

  Future<void> save(Meal meal) async {
    await LocalStore.put(LocalStore.mealsBox, meal.id, meal.toJson());
    // photo_path stays on-device; everything else syncs.
    final payload = meal.toJson()..remove('photo_path');
    await _sync.enqueue('meals', 'upsert', payload);
  }

  Future<void> toggleFavorite(Meal meal) =>
      save(meal.copyWith(isFavorite: !meal.isFavorite));

  Future<void> remove(String id) async {
    await LocalStore.delete(LocalStore.mealsBox, id);
    await _sync.enqueue('meals', 'delete', {'id': id});
  }
}
