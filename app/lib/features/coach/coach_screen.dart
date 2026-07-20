import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/chat_message.dart';
import 'coach_controller.dart';

class CoachScreen extends HookConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coachControllerProvider);
    final input = useTextEditingController();
    final scrollController = useScrollController();
    final theme = Theme.of(context);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
      return null;
    }, [state.messages.length, state.messages.lastOrNull?.content.length]);

    void send([String? preset]) {
      final text = preset ?? input.text;
      if (text.trim().isEmpty) return;
      input.clear();
      ref.read(coachControllerProvider.notifier).send(text);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach'),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear conversation',
              onPressed: () =>
                  ref.read(coachControllerProvider.notifier).clearHistory(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyCoach(onSuggestion: send)
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) =>
                        _Bubble(message: state.messages[index]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ask your coach anything…',
                      ),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: state.streaming ? null : send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCoach extends StatelessWidget {
  const _EmptyCoach({required this.onSuggestion});

  final void Function(String) onSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Text('🧠', style: theme.textTheme.displayMedium),
        const SizedBox(height: 16),
        Text(
          'Your coach knows your goals,\nmeals, sleep and progress.',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Ask anything about your body, your food, or your plan. Answers are personal — built from your own data.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in coachSuggestions)
              ActionChip(
                label: Text(suggestion),
                onPressed: () => onSuggestion(suggestion),
              ),
          ],
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.radiusM),
            topRight: const Radius.circular(AppTheme.radiusM),
            bottomLeft: Radius.circular(isUser ? AppTheme.radiusM : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppTheme.radiusM),
          ),
          border: isUser ? null : Border.all(color: theme.colorScheme.outline),
        ),
        child: message.pending && message.content.isEmpty
            ? SizedBox(
                width: 36,
                child: Text(
                  '…',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : SelectableText(
                message.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isUser ? Colors.white : null,
                ),
              ),
      ),
    );
  }
}
