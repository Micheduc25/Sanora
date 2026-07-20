import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/error/failures.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/health_profile.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/nutrition.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/workout.dart';
import '../supabase_service.dart';

/// Client for the Supabase Edge Functions that wrap the OpenAI Responses
/// API. All prompts and keys live server-side; the app only ever sends the
/// user's own data over their authenticated session.
class AiService {
  AiService(this._supabase, this._dio);

  final SupabaseService _supabase;
  final Dio _dio;

  Map<String, String> _headers() {
    final session = _supabase.client?.auth.currentSession;
    if (session == null) throw const AiUnavailableFailure();
    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'apikey': AppConfig.supabaseAnonKey,
      'Content-Type': 'application/json',
    };
  }

  String _functionUrl(String name) =>
      '${AppConfig.supabaseUrl}/functions/v1/$name';

  /// Streams assistant tokens for the coach conversation.
  Stream<String> coachReply({
    required List<Map<String, String>> messages,
    required UserProfile profile,
    required HealthProfile health,
    required Map<String, dynamic> todayContext,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      _functionUrl(AppConfig.aiCoachFunction),
      options: Options(
        headers: _headers(),
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(minutes: 2),
      ),
      data: jsonEncode({
        'messages': messages,
        'profile': profile.toJson(),
        'health': health.toJson(),
        'today': todayContext,
      }),
    );

    final stream = response.data;
    if (stream == null) throw const ServerFailure();

    var buffer = '';
    await for (final chunk in stream.stream.cast<List<int>>().transform(utf8.decoder)) {
      buffer += chunk;
      while (true) {
        final split = buffer.indexOf('\n\n');
        if (split == -1) break;
        final event = buffer.substring(0, split);
        buffer = buffer.substring(split + 2);
        for (final line in event.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') return;
          final parsed = jsonDecode(data) as Map<String, dynamic>;
          final delta = parsed['delta'] as String?;
          if (delta != null && delta.isNotEmpty) yield delta;
        }
      }
    }
  }

  /// Analyzes a meal from a photo (base64) and/or a text description.
  Future<Meal> analyzeMeal({
    String? imageBase64,
    String? description,
    required UserProfile profile,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _functionUrl(AppConfig.mealAnalyzeFunction),
      options: Options(
        headers: _headers(),
        receiveTimeout: const Duration(minutes: 2),
      ),
      data: jsonEncode({
        if (imageBase64 != null) 'image_base64': imageBase64,
        if (description != null) 'description': description,
        'country': profile.country,
        'allergies': profile.allergies,
        'preferences': profile.foodPreferences,
      }),
    );

    final data = response.data;
    if (data == null) throw const ServerFailure();
    return _mealFromAnalysis(data);
  }

  Meal _mealFromAnalysis(Map<String, dynamic> data) {
    final components = (data['components'] as List? ?? [])
        .map((c) => MealComponent.fromJson(c as Map<String, dynamic>))
        .toList();
    final nutrition = components.isEmpty
        ? Nutrition.fromJson(
            (data['nutrition'] as Map<String, dynamic>?) ?? const {})
        : components.fold(
            const Nutrition(), (total, c) => total + c.nutrition);
    return Meal(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Meal',
      type: MealTypeParsing.parse(data['meal_type'] as String?),
      source: MealSource.photo,
      components: components,
      nutrition: nutrition,
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.7,
      aiNotes: data['notes'] as String? ?? '',
      healthierSwaps: (data['healthier_swaps'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      eatenAt: DateTime.now(),
    );
  }

  Future<Workout> generateWorkout({
    required WorkoutCategory category,
    required int durationMinutes,
    required UserProfile profile,
    required HealthProfile health,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _functionUrl(AppConfig.workoutFunction),
      options: Options(
        headers: _headers(),
        receiveTimeout: const Duration(minutes: 2),
      ),
      data: jsonEncode({
        'category': category.name,
        'duration_minutes': durationMinutes,
        'profile': profile.toJson(),
        'health': health.toJson(),
      }),
    );
    final data = response.data;
    if (data == null) throw const ServerFailure();
    return Workout.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> generateInsights({
    required Map<String, dynamic> weekContext,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _functionUrl(AppConfig.insightsFunction),
      options: Options(
        headers: _headers(),
        receiveTimeout: const Duration(minutes: 2),
      ),
      data: jsonEncode({'context': weekContext}),
    );
    final data = response.data;
    if (data == null) throw const ServerFailure();
    return (data['insights'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}

extension MealTypeParsing on MealType {
  static MealType parse(String? value) => MealType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => MealType.forTime(DateTime.now()),
      );
}
