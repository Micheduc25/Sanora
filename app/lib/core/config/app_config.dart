/// Build-time configuration, injected with --dart-define.
///
/// The app runs fully offline when Supabase credentials are absent:
/// repositories fall back to local Hive storage and AI features surface
/// a graceful "connect to unlock" state.
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Absent in local and debug builds — crash reporting stays off rather than
  /// failing to start.
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static bool get hasCrashReporting => sentryDsn.isNotEmpty;

  static const releaseChannel = String.fromEnvironment(
    'RELEASE_CHANNEL',
    defaultValue: 'development',
  );

  static const aiCoachFunction = 'ai-coach';
  static const mealAnalyzeFunction = 'meal-analyze';
  static const insightsFunction = 'generate-insights';
  static const workoutFunction = 'generate-workout';
}
