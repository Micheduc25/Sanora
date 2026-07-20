import '../../core/storage/local_store.dart';
import '../../domain/health/health_engine.dart';
import '../../domain/models/health_profile.dart';
import '../../domain/models/user_profile.dart';
import '../sync/sync_service.dart';

class ProfileRepository {
  ProfileRepository(this._sync);

  final SyncService _sync;

  static const _profileKey = 'user';
  static const _healthKey = 'health';

  UserProfile? getProfile() {
    final json = LocalStore.get(LocalStore.profileBox, _profileKey);
    return json == null ? null : UserProfile.fromJson(json);
  }

  HealthProfile? getHealthProfile() {
    final json = LocalStore.get(LocalStore.profileBox, _healthKey);
    return json == null ? null : HealthProfile.fromJson(json);
  }

  /// Saving a profile always recomputes the AI Health Profile so derived
  /// targets stay in step with the data that produced them.
  Future<HealthProfile> saveProfile(UserProfile profile) async {
    final health = HealthEngine.compute(profile);
    await LocalStore.put(LocalStore.profileBox, _profileKey, profile.toJson());
    await LocalStore.put(LocalStore.profileBox, _healthKey, health.toJson());
    await _sync.enqueue('profiles', 'upsert', {
      'id': profile.id,
      'data': profile.toJson(),
      'health': health.toJson(),
      'updated_at': profile.updatedAt.toIso8601String(),
    });
    return health;
  }

  Future<void> clear() => LocalStore.wipe();
}
