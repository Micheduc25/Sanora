import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/models/habit.dart';
import '../dashboard/dashboard_controller.dart';

final habitsListProvider = Provider.autoDispose<List<Habit>>(
  (ref) => ref.watch(habitsRepositoryProvider).all(),
);

class HabitsController {
  HabitsController(this._ref);

  final Ref _ref;

  void _refresh() {
    _ref.invalidate(habitsListProvider);
    _ref.invalidate(dashboardProvider);
  }

  Future<void> toggleToday(Habit habit) async {
    final repo = _ref.read(habitsRepositoryProvider);
    final today = DateTime.now();
    if (repo.isDoneForDay(habit, today)) {
      await repo.undoLog(habit, today);
    } else {
      await repo.log(habit, today);
    }
    _refresh();
  }

  Future<void> create({
    required String name,
    required String emoji,
    List<int> weekdays = const [],
    String? reminderTime,
  }) async {
    final repo = _ref.read(habitsRepositoryProvider);
    await repo.save(
      Habit(
        id: const Uuid().v4(),
        name: name,
        emoji: emoji,
        scheduledWeekdays: weekdays,
        reminderTime: reminderTime,
        createdAt: DateTime.now(),
      ),
    );
    _refresh();
  }

  Future<void> remove(Habit habit) async {
    await _ref.read(habitsRepositoryProvider).remove(habit.id);
    _refresh();
  }
}

final habitsControllerProvider = Provider((ref) => HabitsController(ref));

/// Starter habits offered on the empty state — one tap to adopt.
const suggestedHabits = [
  ('💧', 'Drink 2L of water'),
  ('🚶', 'Walk after lunch'),
  ('🏋️', 'Exercise 20 minutes'),
  ('🥬', 'Vegetables with dinner'),
  ('🚫', 'No sugary drinks'),
  ('😴', 'In bed before 11 PM'),
  ('☀️', 'Morning sunlight'),
  ('🧘', 'Meditate 5 minutes'),
  ('📖', 'Read 10 pages'),
  ('🧎', 'Stretch before bed'),
];

class HabitCheckRow extends ConsumerWidget {
  const HabitCheckRow({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(habitsRepositoryProvider);
    ref.watch(habitsListProvider);
    final done = repo.isDoneForDay(habit, DateTime.now());
    final streak = repo.streak(habit);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ref.read(habitsControllerProvider).toggleToday(habit),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(habit.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            ),
            if (streak > 1) ...[
              Text('🔥 $streak', style: theme.textTheme.labelMedium),
              const SizedBox(width: 10),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? theme.colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: done
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
