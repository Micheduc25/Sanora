import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/empty_state.dart';
import 'habits_controller.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New habit'),
      ),
      body: habits.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const EmptyState(
                  icon: Icons.spa_rounded,
                  title: 'Habits beat willpower',
                  message:
                      'Pick one tiny habit to start. Consistency, not intensity, is what changes your health.',
                ),
                Text('Popular starters', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final (emoji, name) in suggestedHabits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BodiCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onTap: () => ref
                          .read(habitsControllerProvider)
                          .create(name: name, emoji: emoji),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.add_circle_outline_rounded),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final habit in habits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BodiCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Dismissible(
                        key: ValueKey(habit.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            ref.read(habitsControllerProvider).remove(habit),
                        background: Container(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        child: HabitCheckRow(habit: habit),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateHabitSheet(),
    );
  }
}

class _CreateHabitSheet extends HookConsumerWidget {
  const _CreateHabitSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useTextEditingController();
    final emoji = useState('✅');
    final weekdays = useState<List<int>>([]);
    final theme = Theme.of(context);
    const emojis = ['✅', '💧', '🚶', '🏋️', '🥬', '😴', '🧘', '📖', '☀️', '🚫'];
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New habit', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Walk after dinner',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final e in emojis)
                ChoiceChip(
                  label: Text(e),
                  selected: emoji.value == e,
                  showCheckmark: false,
                  onSelected: (_) => emoji.value = e,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Days (empty = every day)', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 7; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(dayLabels[i - 1]),
                    selected: weekdays.value.contains(i),
                    showCheckmark: false,
                    onSelected: (_) {
                      final next = List<int>.from(weekdays.value);
                      next.contains(i) ? next.remove(i) : next.add(i);
                      weekdays.value = next;
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await ref
                  .read(habitsControllerProvider)
                  .create(
                    name: name.text.trim(),
                    emoji: emoji.value,
                    weekdays: weekdays.value..sort(),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create habit'),
          ),
        ],
      ),
    );
  }
}
