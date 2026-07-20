import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/app_providers.dart';
import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/models/reminder.dart';

final remindersListProvider = Provider.autoDispose(
    (ref) => ref.watch(remindersRepositoryProvider).all());

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart reminders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _CreateReminderSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
      body: reminders.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_active_rounded,
              title: 'Nudges that fit your day',
              message:
                  'Water, movement, meals, medication, sleep — gentle reminders exactly when you need them.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final reminder in reminders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BodiCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(reminder.kind.emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(reminder.title,
                                    style: theme.textTheme.titleMedium),
                                Text(
                                  '${reminder.time} · ${_daysLabel(reminder.weekdays)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: reminder.enabled,
                            onChanged: (enabled) async {
                              await ref
                                  .read(remindersRepositoryProvider)
                                  .save(reminder.copyWith(
                                      enabled: enabled));
                              ref.invalidate(remindersListProvider);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20),
                            onPressed: () async {
                              await ref
                                  .read(remindersRepositoryProvider)
                                  .remove(reminder);
                              ref.invalidate(remindersListProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  static String _daysLabel(List<int> weekdays) {
    if (weekdays.isEmpty || weekdays.length == 7) return 'every day';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays.map((d) => names[d - 1]).join(', ');
  }
}

class _CreateReminderSheet extends HookConsumerWidget {
  const _CreateReminderSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = useState(ReminderKind.water);
    final title = useTextEditingController();
    final time = useState(const TimeOfDay(hour: 9, minute: 0));
    final theme = Theme.of(context);

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
          Text('New reminder', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in ReminderKind.values)
                ChoiceChip(
                  label: Text('${k.emoji} ${k.defaultTitle}'),
                  selected: kind.value == k,
                  showCheckmark: false,
                  onSelected: (_) => kind.value = k,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (kind.value == ReminderKind.custom)
            TextField(
              controller: title,
              decoration:
                  const InputDecoration(hintText: 'Reminder title'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule_rounded),
            label: Text(time.value.format(context)),
            onPressed: () async {
              final picked = await showTimePicker(
                  context: context, initialTime: time.value);
              if (picked != null) time.value = picked;
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final reminder = Reminder(
                id: const Uuid().v4(),
                kind: kind.value,
                title: kind.value == ReminderKind.custom &&
                        title.text.trim().isNotEmpty
                    ? title.text.trim()
                    : kind.value.defaultTitle,
                time:
                    '${time.value.hour.toString().padLeft(2, '0')}:${time.value.minute.toString().padLeft(2, '0')}',
                createdAt: DateTime.now(),
              );
              await ref.read(remindersRepositoryProvider).save(reminder);
              ref.invalidate(remindersListProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create reminder'),
          ),
        ],
      ),
    );
  }
}
