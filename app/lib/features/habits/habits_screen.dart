import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';
import 'habits_controller.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsListProvider);
    final theme = Theme.of(context);
    final l = L.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.habitsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-habits',
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.habitsNewHabit),
      ),
      body: habits.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                EmptyState(
                  icon: Icons.spa_rounded,
                  title: l.habitsEmptyTitle,
                  message: l.habitsEmptyMessage,
                ),
                Text(
                  l.habitsPopularStarters,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final (emoji, name) in suggestedHabits(l))
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
    final reminder = useState<TimeOfDay?>(null);
    final dailyTarget = useState(1);
    final theme = Theme.of(context);
    final l = L.of(context);
    const emojis = ['✅', '💧', '🚶', '🏋️', '🥬', '😴', '🧘', '📖', '☀️', '🚫'];
    final dayLabels = [
      l.habitsDayMon,
      l.habitsDayTue,
      l.habitsDayWed,
      l.habitsDayThu,
      l.habitsDayFri,
      l.habitsDaySat,
      l.habitsDaySun,
    ];

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
          Text(l.habitsNewHabit, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.habitsNameHint),
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
          Text(l.habitsDaysLabel, style: theme.textTheme.labelMedium),
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
          const SizedBox(height: 16),
          Text(l.habitsTimesPerDay, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                onPressed: dailyTarget.value > 1
                    ? () => dailyTarget.value--
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '${dailyTarget.value}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton.outlined(
                onPressed: dailyTarget.value < 20
                    ? () => dailyTarget.value++
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: Text(
                    reminder.value == null
                        ? l.habitsRemindOptional
                        : l.habitsRemindAt(reminder.value!.format(context)),
                  ),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime:
                          reminder.value ?? const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null) reminder.value = picked;
                  },
                ),
              ),
              if (reminder.value != null)
                IconButton(
                  tooltip: l.habitsClearReminder,
                  onPressed: () => reminder.value = null,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              final at = reminder.value;
              await ref
                  .read(habitsControllerProvider)
                  .create(
                    name: name.text.trim(),
                    emoji: emoji.value,
                    weekdays: weekdays.value..sort(),
                    dailyTarget: dailyTarget.value,
                    reminderTime: at == null
                        ? null
                        : '${at.hour.toString().padLeft(2, '0')}:'
                              '${at.minute.toString().padLeft(2, '0')}',
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l.habitsCreate),
          ),
        ],
      ),
    );
  }
}
