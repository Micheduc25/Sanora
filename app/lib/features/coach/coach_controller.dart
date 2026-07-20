import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/extensions.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/enums.dart';
import '../onboarding/onboarding_controller.dart';

class CoachState {
  const CoachState({this.messages = const [], this.streaming = false});

  final List<ChatMessage> messages;
  final bool streaming;

  CoachState copyWith({List<ChatMessage>? messages, bool? streaming}) =>
      CoachState(
        messages: messages ?? this.messages,
        streaming: streaming ?? this.streaming,
      );
}

class CoachController extends Notifier<CoachState> {
  @override
  CoachState build() =>
      CoachState(messages: ref.read(chatRepositoryProvider).history());

  Future<void> send(String text) async {
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

    try {
      final profile = ref.read(userProfileProvider);
      final health = ref.read(healthProfileProvider);
      if (profile == null || health == null) {
        throw const ValidationFailure('Complete onboarding first.');
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
      reply = reply.copyWith(pending: false);
      await repo.save(reply);
    } on Failure catch (f) {
      reply = reply.copyWith(content: f.message, pending: false);
    } catch (_) {
      reply = reply.copyWith(
        content:
            'I could not reach the coach service just now. Your message is saved — try again in a moment.',
        pending: false,
      );
    } finally {
      state = state.copyWith(
        messages: [
          ...state.messages.sublist(0, state.messages.length - 1),
          reply,
        ],
        streaming: false,
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

const coachSuggestions = [
  'Why am I gaining weight?',
  'Can I eat fufu tonight?',
  'How do I lose belly fat?',
  'Is my dinner healthy?',
  'How much protein do I need?',
  'Plan my meals for tomorrow',
];
