import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';

/// Thin access point for the Supabase client. Null client means the app is
/// running in local-only mode (no credentials at build time).
class SupabaseService {
  SupabaseClient? get client =>
      AppConfig.hasSupabase ? Supabase.instance.client : null;

  String? get userId => client?.auth.currentUser?.id;

  bool get isSignedIn => userId != null;

  Stream<AuthState>? get authChanges => client?.auth.onAuthStateChange;

  static bool _hadPersistedSession = false;

  /// The device has an account but its session has not come back — a dead
  /// network, not a missing sign-in. Screens that would otherwise say "sign
  /// in" ask this first, because telling a signed-in user to sign in is worse
  /// than telling them to check their connection.
  bool get isRestoringSession => _hadPersistedSession && !isSignedIn;

  /// The key supabase_flutter would have picked on its own. Passing the
  /// storage explicitly must not move where the session lives, or the upgrade
  /// silently signs out every device that already has one.
  static String persistSessionKey(String url) =>
      'sb-${Uri.parse(url).host.split('.').first}-auth-token';

  /// Blocks until the persisted session has been restored, or gives up.
  ///
  /// `Supabase.initialize` starts session recovery and returns without
  /// awaiting it, and a stored access token expires within the hour — which
  /// turns recovery into a network refresh. Until it lands `currentSession` is
  /// null, so a signed-in user who opens the app and goes straight to the
  /// coach is told to sign in. Waiting here closes that window for the common
  /// case; `authSessionProvider` covers a restore that outlives the timeout.
  ///
  /// Costs nothing when the device has no session, which is what
  /// [SessionRestoreStorage] is for — otherwise every signed-out cold start
  /// would sit on the splash waiting for an event that never comes.
  static Future<void> awaitSessionRestore(
    SessionRestoreStorage storage, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) return;
    // Subscribed before the storage check, or a restore landing in between is
    // missed and the wait runs to its timeout.
    final restored = auth.onAuthStateChange.firstWhere(
      (state) => state.session != null,
    );
    try {
      final hadSession = await storage.hadPersistedSession.timeout(
        const Duration(seconds: 2),
      );
      _hadPersistedSession = hadSession;
      if (!hadSession || auth.currentSession != null) {
        restored.ignore();
        return;
      }
      await restored.timeout(timeout);
    } on TimeoutException {
      // Offline, or the refresh token is dead. Start signed-out rather than
      // hold the splash — this app is usable without an account.
      restored.ignore();
    }
  }
}

/// Wraps supabase_flutter's own storage to learn whether this device has a
/// session to restore.
///
/// Recovery calls [hasAccessToken] exactly once at startup, and that is the
/// only signal the package exposes for "is a restore in flight?" — the
/// operation itself is held in a private field.
class SessionRestoreStorage extends LocalStorage {
  SessionRestoreStorage(this._inner);

  final LocalStorage _inner;
  final Completer<bool> _persisted = Completer<bool>();

  /// Whether a session was on disk. Completes as soon as recovery looks.
  Future<bool> get hadPersistedSession => _persisted.future;

  @override
  Future<void> initialize() => _inner.initialize();

  @override
  Future<bool> hasAccessToken() async {
    final has = await _inner.hasAccessToken();
    if (!_persisted.isCompleted) _persisted.complete(has);
    return has;
  }

  @override
  Future<String?> accessToken() => _inner.accessToken();

  @override
  Future<void> removePersistedSession() => _inner.removePersistedSession();

  @override
  Future<void> persistSession(String persistSessionString) =>
      _inner.persistSession(persistSessionString);
}
