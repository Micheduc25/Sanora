import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/health/insight_rules_engine.dart';
import '../../domain/models/insight.dart';
import '../dashboard/dashboard_controller.dart';
import '../onboarding/onboarding_controller.dart';

final insightsListProvider = Provider.autoDispose(
    (ref) => ref.watch(insightsRepositoryProvider).all());

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  Future<void> _regenerate(WidgetRef ref) async {
    final profile = ref.read(userProfileProvider);
    final health = ref.read(healthProfileProvider);
    if (profile == null || health == null) return;
    final insights = InsightRulesEngine.generate(
      profile: profile,
      health: health,
      meals: ref.read(mealsRepositoryProvider).all(),
      metrics: ref.read(metricsRepositoryProvider).all(),
    );
    await ref.read(insightsRepositoryProvider).replaceAll(insights);
    ref.invalidate(insightsListProvider);
    ref.invalidate(dashboardProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Analyze my week',
            onPressed: () => _regenerate(ref),
          ),
        ],
      ),
      body: insights.isEmpty
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'Your patterns, decoded',
              message:
                  'Bodi studies your meals, sleep, weight and movement to find what is really driving your results.',
              actionLabel: 'Analyze my week',
              onAction: () => _regenerate(ref),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: insights.length,
              itemBuilder: (context, index) {
                final insight = insights[index];
                final (color, icon) = switch (insight.severity) {
                  InsightSeverity.celebrate => (
                      AppColors.success,
                      Icons.celebration_rounded
                    ),
                  InsightSeverity.info => (
                      AppColors.ocean,
                      Icons.lightbulb_rounded
                    ),
                  InsightSeverity.nudge => (
                      AppColors.sun,
                      Icons.tips_and_updates_rounded
                    ),
                  InsightSeverity.warning => (
                      AppColors.coral,
                      Icons.priority_high_rounded
                    ),
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BodiCard(
                    onTap: () {
                      ref
                          .read(insightsRepositoryProvider)
                          .markRead(insight);
                      ref.invalidate(insightsListProvider);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(insight.title,
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(insight.body,
                                  style: theme.textTheme.bodyMedium),
                              if (insight.action.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(insight.action,
                                    style: theme.textTheme.labelLarge
                                        ?.copyWith(color: color)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
