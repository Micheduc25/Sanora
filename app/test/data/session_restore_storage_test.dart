import 'package:sanora/data/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeStorage extends LocalStorage {
  _FakeStorage(this.token);

  final String? token;
  var initialized = false;
  var removed = false;
  String? persisted;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<bool> hasAccessToken() async => token != null;

  @override
  Future<String?> accessToken() async => token;

  @override
  Future<void> removePersistedSession() async => removed = true;

  @override
  Future<void> persistSession(String value) async => persisted = value;
}

void main() {
  test('reports whether recovery found a session', () async {
    final withSession = SessionRestoreStorage(_FakeStorage('token'));
    await withSession.hasAccessToken();
    expect(await withSession.hadPersistedSession, isTrue);

    final without = SessionRestoreStorage(_FakeStorage(null));
    await without.hasAccessToken();
    expect(await without.hadPersistedSession, isFalse);
  });

  test('delegates every operation to the wrapped storage', () async {
    final inner = _FakeStorage('token');
    final storage = SessionRestoreStorage(inner);

    await storage.initialize();
    await storage.persistSession('{}');
    await storage.removePersistedSession();

    expect(inner.initialized, isTrue);
    expect(inner.persisted, '{}');
    expect(inner.removed, isTrue);
    expect(await storage.accessToken(), 'token');
  });

  test(
    'keeps supabase_flutter default key so sessions survive the upgrade',
    () {
      // Changing this logs out every device that is already signed in.
      expect(
        SupabaseService.persistSessionKey(
          'https://fbswsafqzxypqzibaogn.supabase.co',
        ),
        'sb-fbswsafqzxypqzibaogn-auth-token',
      );
    },
  );
}
