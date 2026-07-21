import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

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

/// Auth changes as a rebuild signal.
///
/// [SupabaseService] reads live state off the client, but nothing tells a
/// widget to look again. A session that arrives after the first frame —
/// restored from disk, refreshed, or signed in on another screen — has to
/// reach every gate that asks "is this user signed in?", so those gates watch
/// [isSignedInProvider] rather than reading the service directly.
final authSessionProvider = StreamProvider<Session?>((ref) {
  final changes = ref.watch(supabaseServiceProvider).authChanges;
  if (changes == null) return const Stream<Session?>.empty();
  return changes.map((state) => state.session);
});

final isSignedInProvider = Provider<bool>((ref) {
  ref.watch(authSessionProvider);
  return ref.watch(supabaseServiceProvider).isSignedIn;
});

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
  (ref) => ProfileRepository(
    ref.watch(syncServiceProvider),
    ref.watch(supabaseServiceProvider),
  ),
);

final metricsRepositoryProvider = Provider(
  (ref) => MetricsRepository(ref.watch(syncServiceProvider)),
);

final mealsRepositoryProvider = Provider(
  (ref) => MealsRepository(ref.watch(syncServiceProvider)),
);

final habitsRepositoryProvider = Provider(
  (ref) => HabitsRepository(
    ref.watch(syncServiceProvider),
    ref.watch(notificationServiceProvider),
  ),
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
