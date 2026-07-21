import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
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
import '../storage/local_store.dart';

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

/// The signed-in user's id, or null. Community rows use it to tell the
/// reader's own entry from everyone else's — you cannot report yourself.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authSessionProvider);
  return ref.watch(supabaseServiceProvider).userId;
});

/// Writes to one local box, as a rebuild signal.
///
/// The repositories read Hive synchronously, which is fine for a screen that
/// only ever sees its own writes. It is not fine for boxes the app fills from
/// behind the UI — the sync pull restoring a device, or the activity import
/// bringing in steps from the watch — so anything derived from those watches
/// this first.
final boxRevisionProvider = StreamProvider.family<void, String>(
  (ref, box) => LocalStore.watch(box),
);

/// Counts foreground returns.
///
/// The step count someone cares about most is the one from the walk they just
/// took with the phone in a pocket — recorded while this app was suspended and
/// nothing could poll for it. Anything reading the platform's activity data
/// watches this so it re-reads on the way back in.
final appResumeProvider = NotifierProvider<AppResumeNotifier, int>(
  AppResumeNotifier.new,
);

class AppResumeNotifier extends Notifier<int> {
  @override
  int build() {
    final listener = AppLifecycleListener(onResume: () => state++);
    ref.onDispose(listener.dispose);
    return 0;
  }
}

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
