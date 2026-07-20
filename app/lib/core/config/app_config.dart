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

  static const aiCoachFunction = 'ai-coach';
  static const mealAnalyzeFunction = 'meal-analyze';
  static const insightsFunction = 'generate-insights';
  static const workoutFunction = 'generate-workout';
}
