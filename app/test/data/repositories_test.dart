import 'dart:io';

import 'package:bodi/core/storage/local_store.dart';
import 'package:bodi/data/repositories/habits_repository.dart';
import 'package:bodi/data/repositories/meals_repository.dart';
import 'package:bodi/data/repositories/metrics_repository.dart';
import 'package:bodi/data/notifications/notification_service.dart';
import 'package:bodi/data/supabase_service.dart';
import 'package:bodi/data/sync/sync_service.dart';
import 'package:bodi/domain/models/enums.dart';
import 'package:bodi/domain/models/habit.dart';
import 'package:bodi/domain/models/meal.dart';
import 'package:bodi/domain/models/metric_entry.dart';
import 'package:bodi/domain/models/nutrition.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  // No Supabase configured in tests, so SyncService is inert.
  final sync = SyncService(SupabaseService());
  final notifications = NotificationService();

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('bodi_test');
    Hive.init(tempDir.path);
    await LocalStore.open();
  });

  setUp(() async {
    await LocalStore.wipe();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('MetricsRepository', () {
    test('round-trips entries and sorts newest first', () async {
      final repo = MetricsRepository(sync);
      await repo.add(
        MetricEntry(
          id: 'a',
          type: MetricType.weight,
          value: 80,
          recordedAt: DateTime(2026, 7, 18),
        ),
      );
      await repo.add(
        MetricEntry(
          id: 'b',
          type: MetricType.weight,
          value: 79.5,
          recordedAt: DateTime(2026, 7, 20),
        ),
      );

      expect(repo.all().first.id, 'b');
      expect(repo.latest(MetricType.weight)!.value, 79.5);
    });

    test('dayTotal sums additive metrics for one day only', () async {
      final repo = MetricsRepository(sync);
      final day = DateTime(2026, 7, 20);
      await repo.add(
        MetricEntry(
          id: 'w1',
          type: MetricType.water,
          value: 250,
          recordedAt: day.add(const Duration(hours: 9)),
        ),
      );
      await repo.add(
        MetricEntry(
          id: 'w2',
          type: MetricType.water,
          value: 500,
          recordedAt: day.add(const Duration(hours: 14)),
        ),
      );
      await repo.add(
        MetricEntry(
          id: 'w3',
          type: MetricType.water,
          value: 1000,
          recordedAt: day.subtract(const Duration(days: 1)),
        ),
      );

      expect(repo.dayTotal(MetricType.water, day), 750);
    });

    test('remove deletes the entry', () async {
      final repo = MetricsRepository(sync);
      await repo.add(
        MetricEntry(
          id: 'x',
          type: MetricType.weight,
          value: 80,
          recordedAt: DateTime(2026, 7, 20),
        ),
      );
      await repo.remove('x');
      expect(repo.all(), isEmpty);
    });
  });

  group('MealsRepository', () {
    Meal meal(String id, DateTime eatenAt, {double calories = 500}) => Meal(
      id: id,
      name: 'Meal $id',
      type: MealType.lunch,
      source: MealSource.database,
      nutrition: Nutrition(calories: calories, proteinG: 20),
      eatenAt: eatenAt,
    );

    test('aggregates a day of nutrition', () async {
      final repo = MealsRepository(sync);
      final day = DateTime(2026, 7, 20);
      await repo.save(meal('1', day.add(const Duration(hours: 8))));
      await repo.save(
        meal('2', day.add(const Duration(hours: 13)), calories: 700),
      );
      await repo.save(meal('3', day.subtract(const Duration(days: 1))));

      final total = repo.dayNutrition(day);
      expect(total.calories, 1200);
      expect(total.proteinG, 40);
    });

    test('nested components survive the JSON round trip', () async {
      final repo = MealsRepository(sync);
      final withComponents = Meal(
        id: 'c',
        name: 'Eru with fufu',
        type: MealType.dinner,
        source: MealSource.text,
        components: const [
          MealComponent(
            name: 'Eru',
            portionG: 250,
            nutrition: Nutrition(calories: 350, proteinG: 16),
          ),
          MealComponent(
            name: 'Water fufu',
            portionG: 300,
            nutrition: Nutrition(calories: 390, proteinG: 2.7),
          ),
        ],
        nutrition: const Nutrition(calories: 740, proteinG: 18.7),
        eatenAt: DateTime(2026, 7, 20, 19),
      );
      await repo.save(withComponents);

      final loaded = repo.all().single;
      expect(loaded.components, hasLength(2));
      expect(loaded.components.first.name, 'Eru');
      expect(loaded.nutrition.calories, 740);
    });

    test('toggleFavorite flips and persists', () async {
      final repo = MealsRepository(sync);
      final m = meal('f', DateTime(2026, 7, 20, 12));
      await repo.save(m);
      await repo.toggleFavorite(m);
      expect(repo.favorites().single.id, 'f');
    });
  });

  group('HabitsRepository streaks', () {
    final today = DateTime(2026, 7, 20);

    Habit habit({List<int> weekdays = const []}) => Habit(
      id: 'h',
      name: 'Walk',
      scheduledWeekdays: weekdays,
      createdAt: today.subtract(const Duration(days: 30)),
    );

    test('unbroken run of completed days counts', () async {
      final repo = HabitsRepository(sync, notifications);
      final h = habit();
      await repo.save(h);
      for (var i = 0; i < 4; i++) {
        await repo.log(h, today.subtract(Duration(days: i)));
      }
      expect(repo.streak(h, today: today), 4);
    });

    test('an incomplete today does not break the streak', () async {
      final repo = HabitsRepository(sync, notifications);
      final h = habit();
      await repo.save(h);
      for (var i = 1; i <= 3; i++) {
        await repo.log(h, today.subtract(Duration(days: i)));
      }
      expect(repo.streak(h, today: today), 3);
    });

    test('a gap breaks the streak', () async {
      final repo = HabitsRepository(sync, notifications);
      final h = habit();
      await repo.save(h);
      await repo.log(h, today);
      await repo.log(h, today.subtract(const Duration(days: 2)));
      expect(repo.streak(h, today: today), 1);
    });

    test('unscheduled days are skipped, not broken', () async {
      final repo = HabitsRepository(sync, notifications);
      // 2026-07-20 is a Monday; schedule Mon/Wed/Fri.
      final h = habit(weekdays: [1, 3, 5]);
      await repo.save(h);
      await repo.log(h, today); // Mon
      await repo.log(h, today.subtract(const Duration(days: 3))); // Fri
      await repo.log(h, today.subtract(const Duration(days: 5))); // Wed
      expect(repo.streak(h, today: today), 3);
    });

    test('undoLog removes the most recent log for the day', () async {
      final repo = HabitsRepository(sync, notifications);
      final h = habit();
      await repo.save(h);
      await repo.log(h, today);
      expect(repo.isDoneForDay(h, today), isTrue);
      await repo.undoLog(h, today);
      expect(repo.isDoneForDay(h, today), isFalse);
    });
  });
}
