import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/extensions.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/enums.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/onboarding_controller.dart';

class CoachState {
  const CoachState({
    this.messages = const [],
    this.streaming = false,
    this.quotaReached = false,
    this.signInRequired = false,
  });

  final List<ChatMessage> messages;
  final bool streaming;

  /// The last send was refused on allowance grounds rather than failing, so
  /// the screen can offer an upgrade instead of "try again".
  final bool quotaReached;

  /// The last send never left the device for want of a session, so the screen
  /// can offer sign-in instead of blaming the connection.
  final bool signInRequired;

  CoachState copyWith({
    List<ChatMessage>? messages,
    bool? streaming,
    bool? quotaReached,
    bool? signInRequired,
  }) => CoachState(
    messages: messages ?? this.messages,
    streaming: streaming ?? this.streaming,
    quotaReached: quotaReached ?? this.quotaReached,
    signInRequired: signInRequired ?? this.signInRequired,
  );
}

class CoachController extends Notifier<CoachState> {
  @override
  CoachState build() =>
      CoachState(messages: ref.read(chatRepositoryProvider).history());

  /// [l] carries the caller's localizations: a failed turn is persisted as an
  /// assistant message, so its copy has to be resolved here rather than at
  /// render time.
  Future<void> send(String text, L l) async {
    final content = text.trim();
    if (content.isEmpty || state.streaming) return;

    final repo = ref.read(chatRepositoryProvider);
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.user,
      content: content,
      sentAt: DateTime.now(),
    );
    await repo.save(userMessage);

    var reply = ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.assistant,
      content: '',
      pending: true,
      sentAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage, reply],
      streaming: true,
    );

    var quota = false;
    var signInRequired = false;
    try {
      final profile = ref.read(userProfileProvider);
      final health = ref.read(healthProfileProvider);
      if (profile == null || health == null) {
        throw ValidationFailure(l.coachCompleteOnboardingFirst);
      }
      final stream = ref
          .read(aiServiceProvider)
          .coachReply(
            messages: repo.recentForContext(),
            profile: profile,
            health: health,
            todayContext: _todayContext(),
          );
      await for (final delta in stream) {
        reply = reply.copyWith(content: reply.content + delta);
        state = state.copyWith(
          messages: [
            ...state.messages.sublist(0, state.messages.length - 1),
            reply,
          ],
        );
      }
      // A stream that ends having said nothing leaves a blank bubble with no
      // way forward. Treat it as the failure it is.
      final empty = reply.content.isEmpty;
      reply = reply.copyWith(
        content: empty ? l.coachUnreachable : reply.content,
        pending: false,
        failed: empty,
      );
    } on Failure catch (f) {
      quota = f is QuotaFailure;
      signInRequired = f is SignInRequiredFailure;
      // [Failure] carries English defaults thrown from `core/`, which has no
      // localizations; the cases the screen acts on get resolved here instead.
      reply = reply.copyWith(
        content: signInRequired ? l.coachSignInRequired : f.message,
        pending: false,
        failed: true,
      );
    } catch (_) {
      reply = reply.copyWith(
        content: l.coachUnreachable,
        pending: false,
        failed: true,
      );
    } finally {
      // Persist the failed turn too, otherwise history reloads as a question
      // that was never answered.
      await repo.save(reply);
      state = state.copyWith(
        messages: [
          ...state.messages.sublist(0, state.messages.length - 1),
          reply,
        ],
        streaming: false,
        quotaReached: quota,
        signInRequired: signInRequired,
      );
    }
  }

  /// A compact snapshot of today so the coach can be concrete
  /// ("you're 2,000 steps from your goal") without another round trip.
  Map<String, dynamic> _todayContext() {
    final today = DateTime.now();
    final metrics = ref.read(metricsRepositoryProvider);
    final meals = ref.read(mealsRepositoryProvider);
    final habits = ref.read(habitsRepositoryProvider);
    final nutrition = meals.dayNutrition(today);
    final due = habits.activeForDay(today);
    return {
      'date': today.dayKey,
      'calories': nutrition.calories.round(),
      'protein_g': nutrition.proteinG.round(),
      'water_ml': metrics.dayTotal(MetricType.water, today).round(),
      'steps': metrics.dayTotal(MetricType.steps, today).round(),
      'meals': meals
          .forDay(today)
          .map((m) => '${m.type.name}: ${m.name}')
          .toList(),
      'weight_kg': metrics.latest(MetricType.weight)?.value,
      'waist_cm': metrics.latest(MetricType.waist)?.value,
      'habits_done': due.where((h) => habits.isDoneForDay(h, today)).length,
      'habits_total': due.length,
    };
  }

  Future<void> clearHistory() async {
    await ref.read(chatRepositoryProvider).clear();
    state = const CoachState();
  }
}

final coachControllerProvider = NotifierProvider<CoachController, CoachState>(
  CoachController.new,
);

/// Example questions on the empty coach screen. They are sent verbatim as the
/// user's own message, so they have to read as something the person would
/// actually type in their language — hence a lookup rather than a constant.
List<String> coachSuggestions(L l) => [
  l.coachSuggestionWeightGain,
  l.coachSuggestionFufu,
  l.coachSuggestionBellyFat,
  l.coachSuggestionDinnerHealthy,
  l.coachSuggestionProtein,
  l.coachSuggestionPlanMeals,
];
