import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

/// Client for the Supabase Edge Functions that wrap the Gemini
/// API. All prompts and keys live server-side; the app only ever sends the
/// user's own data over their authenticated session.
class AiService {
  AiService(this._supabase, this._dio);

  final SupabaseService _supabase;
  final Dio _dio;

  Map<String, String> _headers() {
    final client = _supabase.client;
    // No credentials at build time: the app is in local-only mode and no
    // amount of signing in will help, so this stays the generic message.
    if (client == null) throw const AiUnavailableFailure();
    final session = client.auth.currentSession;
    if (session == null) {
      throw _supabase.isRestoringSession
          ? const AiUnavailableFailure()
          : const SignInRequiredFailure();
    }
    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'apikey': AppConfig.supabaseAnonKey,
      'Content-Type': 'application/json',
    };
  }

  String _functionUrl(String name) =>
      '${AppConfig.supabaseUrl}/functions/v1/$name';

  /// Turns transport noise into the domain failures callers switch on.
  ///
  /// Connectivity has to arrive as [AiUnavailableFailure] because that is what
  /// the offline fallbacks catch — otherwise a signed-in user with no network
  /// gets a raw `DioException` and never reaches the bundled food database or
  /// the curated workout templates.
  Failure _translate(Object error) {
    if (error is Failure) return error;
    if (error is! DioException) return const ServerFailure();

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AiUnavailableFailure();
      case DioExceptionType.unknown:
        return error.error is SocketException
            ? const AiUnavailableFailure()
            : const ServerFailure();
      default:
        break;
    }

    final status = error.response?.statusCode;
    if (status == 429) {
      return QuotaFailure(
        _serverMessage(error) ??
            'You have used today\'s free AI calls. They reset tomorrow.',
      );
    }
    if (status == 401 || status == 403) {
      return const AuthFailure('Please sign in again to use AI features.');
    }
    return ServerFailure(
      _serverMessage(error) ??
          'Something went wrong on our side. Please try again.',
    );
  }

  /// The edge functions answer errors as `{"error": "..."}`.
  String? _serverMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return null;
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw _translate(e);
    }
  }

  /// Streams assistant tokens for the coach conversation.
  Stream<String> coachReply({
    required List<Map<String, String>> messages,
    required UserProfile profile,
    required HealthProfile health,
    required Map<String, dynamic> todayContext,
  }) async* {
    final response = await _guard(
      () => _dio.post<ResponseBody>(
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
      ),
    );

    final stream = response.data;
    if (stream == null) throw const ServerFailure();

    var buffer = '';
    final chunks = stream.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        // A connection dropping mid-answer must read as a connectivity
        // problem, not as a truncated success.
        .handleError((Object e) => throw _translate(e));
    // The SSE grammar terminates lines with CRLF, LF or CR — matching only
    // "\n\n" leaves every event stuck in the buffer and the answer blank.
    final separator = RegExp(r'\r\n\r\n|\n\n|\r\r');
    await for (final chunk in chunks) {
      buffer += chunk;
      while (true) {
        final match = separator.firstMatch(buffer);
        if (match == null) break;
        final event = buffer.substring(0, match.start);
        buffer = buffer.substring(match.end);
        for (final line in event.split(RegExp(r'\r\n|\n|\r'))) {
          if (!line.startsWith('data:')) continue;
          final data = line.substring(5).trim();
          if (data == '[DONE]') return;
          if (data.isEmpty) continue;
          final parsed = jsonDecode(data) as Map<String, dynamic>;
          // The stream can fail after the headers are already 200, so an
          // error can only arrive as an event.
          final error = parsed['error'] as String?;
          if (error != null) throw ServerFailure(error);
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
    final response = await _guard(
      () => _dio.post<Map<String, dynamic>>(
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
      ),
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
            (data['nutrition'] as Map<String, dynamic>?) ?? const {},
          )
        : components.fold(const Nutrition(), (total, c) => total + c.nutrition);
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
    final response = await _guard(
      () => _dio.post<Map<String, dynamic>>(
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
      ),
    );
    final data = response.data;
    if (data == null) throw const ServerFailure();
    return Workout.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> generateInsights({
    required Map<String, dynamic> weekContext,
  }) async {
    final response = await _guard(
      () => _dio.post<Map<String, dynamic>>(
        _functionUrl(AppConfig.insightsFunction),
        options: Options(
          headers: _headers(),
          receiveTimeout: const Duration(minutes: 2),
        ),
        data: jsonEncode({'context': weekContext}),
      ),
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
