import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/error/failures.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/models/community.dart';
import 'community_controller.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.group});

  final CommunityGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(groupChallengesProvider(group.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          if (!group.isOwner)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Leave group',
              onPressed: () async {
                await ref
                    .read(communityControllerProvider)
                    .leaveGroup(group.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _CreateChallengeSheet(groupId: group.id),
        ),
        icon: const Icon(Icons.emoji_events_rounded),
        label: const Text('New challenge'),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.refresh(groupChallengesProvider(group.id).future),
        child: challenges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e is Failure ? e.message : '$e')),
          data: (list) => list.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const EmptyState(
                        icon: Icons.emoji_events_outlined,
                        title: 'No challenges yet',
                        message:
                            'Start a step or workout challenge and rally the group.',
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  children: [
                    Text(
                      '${group.memberCount} members',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    for (final challenge in list)
                      _ChallengeCard(groupId: group.id, challenge: challenge),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.groupId, required this.challenge});

  final String groupId;
  final ChallengeSummary challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leaderboard = ref.watch(leaderboardProvider(challenge.id));
    final dateFmt = DateFormat('d MMM');
    final controller = ref.read(communityControllerProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BodiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(challenge.name, style: theme.textTheme.titleMedium),
                      Text(
                        '${_fmt(challenge.target)} ${challenge.metricLabel} · '
                        '${dateFmt.format(DateTime.parse(challenge.startsOn))}–${dateFmt.format(DateTime.parse(challenge.endsOn))}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (challenge.joined) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: challenge.progressFraction,
                        minHeight: 10,
                        color: AppColors.vital,
                        backgroundColor: AppColors.vital.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(challenge.progressFraction * 100).round()}%',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Update my progress'),
                  onPressed: () => _updateProgress(context, ref),
                ),
              ),
            ] else
              FilledButton.tonal(
                onPressed: () =>
                    controller.joinChallenge(groupId, challenge.id),
                child: const Text('Join challenge'),
              ),
            const Divider(height: 24),
            Text('Leaderboard', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            leaderboard.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text(
                'Could not load leaderboard.',
                style: theme.textTheme.bodySmall,
              ),
              data: (entries) => entries.isEmpty
                  ? Text('No entries yet.', style: theme.textTheme.bodySmall)
                  : Column(
                      children: [
                        for (final entry in entries)
                          _LeaderRow(entry: entry, challenge: challenge),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProgress(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: challenge.myProgress == 0
          ? ''
          : challenge.myProgress.round().toString(),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Your ${challenge.metricLabel}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Total ${challenge.metricLabel}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null) {
      await ref
          .read(communityControllerProvider)
          .setProgress(groupId, challenge.id, value);
    }
  }

  static String _fmt(double v) => NumberFormat.compact().format(v);
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry, required this.challenge});

  final LeaderboardEntry entry;
  final ChallengeSummary challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = switch (entry.place) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.place}',
    };
    final fraction = challenge.target <= 0
        ? 0.0
        : (entry.progress / challenge.target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              medal,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 5,
                    color: AppColors.vital,
                    backgroundColor: AppColors.vital.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            NumberFormat.compact().format(entry.progress),
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _CreateChallengeSheet extends HookConsumerWidget {
  const _CreateChallengeSheet({required this.groupId});

  final String groupId;

  static const _metrics = [
    ('steps', 'Steps', '👟'),
    ('workouts', 'Workouts', '💪'),
    ('habit_completion', 'Habit days', '✅'),
    ('water', 'Water (ml)', '💧'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useTextEditingController();
    final target = useTextEditingController();
    final metric = useState('steps');
    final days = useState(7);
    final busy = useState(false);
    final theme = Theme.of(context);

    Future<void> submit() async {
      final targetValue = double.tryParse(target.text.trim());
      if (name.text.trim().isEmpty || targetValue == null) return;
      busy.value = true;
      try {
        final now = DateTime.now();
        await ref
            .read(communityControllerProvider)
            .createChallenge(
              groupId: groupId,
              name: name.text.trim(),
              metric: metric.value,
              target: targetValue,
              starts: now,
              ends: now.add(Duration(days: days.value)),
            );
        if (context.mounted) Navigator.pop(context);
      } on Failure catch (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(f.message)));
        }
      } finally {
        busy.value = false;
      }
    }

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
          Text('New challenge', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'e.g. August step-off'),
          ),
          const SizedBox(height: 16),
          Text('Metric', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (value, label, emoji) in _metrics)
                ChoiceChip(
                  label: Text('$emoji $label'),
                  selected: metric.value == value,
                  showCheckmark: false,
                  onSelected: (_) => metric.value = value,
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: target,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Target (per member)',
              prefixIcon: Icon(Icons.flag_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Length: ${days.value} days',
            style: theme.textTheme.labelMedium,
          ),
          Slider(
            value: days.value.toDouble(),
            min: 3,
            max: 60,
            divisions: 57,
            label: '${days.value} days',
            onChanged: (v) => days.value = v.round(),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: busy.value ? null : submit,
            child: const Text('Create challenge'),
          ),
        ],
      ),
    );
  }
}
