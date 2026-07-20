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
}
