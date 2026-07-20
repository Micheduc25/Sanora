import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/activity/activity_service.dart';
import '../../data/ai/ai_service.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/repositories/habits_repository.dart';
import '../../data/repositories/insights_repository.dart';
import '../../data/repositories/meals_repository.dart';
import '../../data/repositories/metrics_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../data/repositories/workouts_repository.dart';
import '../../data/supabase_service.dart';
import '../../data/sync/sync_service.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());

final dioProvider = Provider(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  ),
);

final syncServiceProvider = Provider((ref) {
  final service = SyncService(ref.watch(supabaseServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});

final notificationServiceProvider = Provider((ref) => NotificationService());

final activityServiceProvider = Provider((ref) => ActivityService());

final aiServiceProvider = Provider(
  (ref) =>
      AiService(ref.watch(supabaseServiceProvider), ref.watch(dioProvider)),
);

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(syncServiceProvider)),
);

final metricsRepositoryProvider = Provider(
  (ref) => MetricsRepository(ref.watch(syncServiceProvider)),
);

final mealsRepositoryProvider = Provider(
  (ref) => MealsRepository(ref.watch(syncServiceProvider)),
);

final habitsRepositoryProvider = Provider(
  (ref) => HabitsRepository(ref.watch(syncServiceProvider)),
);

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(ref.watch(syncServiceProvider)),
);

final insightsRepositoryProvider = Provider((ref) => InsightsRepository());

final communityRepositoryProvider = Provider(
  (ref) => CommunityRepository(ref.watch(supabaseServiceProvider)),
);

final foodRepositoryProvider = Provider((ref) => FoodRepository());

final remindersRepositoryProvider = Provider(
  (ref) => RemindersRepository(
    ref.watch(syncServiceProvider),
    ref.watch(notificationServiceProvider),
  ),
);

final workoutsRepositoryProvider = Provider(
  (ref) => WorkoutsRepository(ref.watch(syncServiceProvider)),
);
