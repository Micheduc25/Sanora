import '../../core/storage/local_store.dart';
import '../../domain/health/health_engine.dart';
import '../../domain/models/health_profile.dart';
import '../../domain/models/user_profile.dart';
import '../supabase_service.dart';
import '../sync/sync_service.dart';

class ProfileRepository {
  ProfileRepository(this._sync, this._supabase);

  final SyncService _sync;
  final SupabaseService _supabase;

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
    // `profiles.id` is client-minted and a fresh one is generated whenever the
    // user re-onboards, so conflicting on the primary key would collide with
    // the `user_id` unique constraint instead of updating the existing row.
    await _sync.enqueue('profiles', 'upsert', {
      'id': profile.id,
      'data': profile.toJson(),
      'health': health.toJson(),
      'updated_at': profile.updatedAt.toIso8601String(),
    }, conflictTarget: 'user_id');
    return health;
  }

  /// Clears this device only. The server copy, if any, is untouched and will
  /// come back on the next sign-in.
  Future<void> clear() => LocalStore.wipe();

  /// Full erasure: drops every server-side row and stored meal photo, signs
  /// out, then clears the device. Required by Apple 5.1.1(v) and GDPR, and
  /// irreversible — callers must confirm first.
  Future<void> deleteAccount() async {
    final client = _supabase.client;
    if (client == null) {
      await LocalStore.wipe();
      return;
    }
    // Server first: if this throws, the user still has their data locally
    // rather than a device wiped against a live account.
    await client.rpc('delete_account');
    await client.auth.signOut();
    await LocalStore.wipe();
  }
}
