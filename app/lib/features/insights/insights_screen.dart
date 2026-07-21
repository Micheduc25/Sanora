import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/sanora_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/health/insight_rules_engine.dart';
import '../../domain/models/health_profile.dart';
import '../../domain/models/insight.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/meal.dart';
import '../../domain/models/metric_entry.dart';
import '../dashboard/dashboard_controller.dart';
import '../onboarding/onboarding_controller.dart';

final insightsListProvider = Provider.autoDispose(
  (ref) => ref.watch(insightsRepositoryProvider).all(),
);

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  /// Rules first — they are deterministic, instant and work offline. The AI
  /// pass then adds free-form patterns the fixed rules cannot express, and is
  /// purely additive: if it is unreachable or out of allowance the user still
  /// gets the full deterministic set.
  Future<void> _regenerate(WidgetRef ref) async {
    final profile = ref.read(userProfileProvider);
    final health = ref.read(healthProfileProvider);
    if (profile == null || health == null) return;

    final meals = ref.read(mealsRepositoryProvider).all();
    final metrics = ref.read(metricsRepositoryProvider).all();
    final insights = InsightRulesEngine.generate(
      profile: profile,
      health: health,
      meals: meals,
      metrics: metrics,
    );
    await ref.read(insightsRepositoryProvider).replaceAll(insights);
    ref.invalidate(insightsListProvider);
    ref.invalidate(dashboardProvider);

    final generated = await _aiInsights(ref, meals, metrics, health);
    if (generated.isEmpty) return;
    final repo = ref.read(insightsRepositoryProvider);
    for (final insight in generated) {
      await repo.save(insight);
    }
    ref.invalidate(insightsListProvider);
    ref.invalidate(dashboardProvider);
  }

  Future<List<Insight>> _aiInsights(
    WidgetRef ref,
    List<Meal> meals,
    List<MetricEntry> metrics,
    HealthProfile health,
  ) async {
    final today = DateTime.now().dateOnly;
    bool recent(DateTime at) => today.difference(at.dateOnly).inDays < 7;
    try {
      final raw = await ref
          .read(aiServiceProvider)
          .generateInsights(
            weekContext: {
              'calorie_target': health.calorieTarget,
              'protein_target_g': health.proteinTargetG,
              'water_target_ml': health.waterTargetMl,
              'step_goal': health.stepGoal,
              'meals': [
                for (final m in meals.where((m) => recent(m.eatenAt)))
                  {
                    'name': m.name,
                    'type': m.type.name,
                    'calories': m.nutrition.calories.round(),
                    'protein_g': m.nutrition.proteinG.round(),
                    'eaten_at': m.eatenAt.toIso8601String(),
                  },
              ],
              'metrics': [
                for (final e in metrics.where((e) => recent(e.recordedAt)))
                  {
                    'type': e.type.name,
                    'value': e.value,
                    'recorded_at': e.recordedAt.toIso8601String(),
                  },
              ],
            },
          );
      return [
        for (final item in raw)
          Insight(
            id: const Uuid().v4(),
            title: item['title'] as String? ?? 'Pattern spotted',
            body: item['body'] as String? ?? '',
            severity: InsightSeverity.values.firstWhere(
              (s) => s.name == item['severity'],
              orElse: () => InsightSeverity.info,
            ),
            action: item['action'] as String? ?? '',
            actionRoute: InsightRulesEngine.routeForAction(
              item['action'] as String? ?? '',
            ),
            createdAt: DateTime.now(),
          ),
      ];
    } on Failure {
      // Offline, signed out, or out of allowance — the rules already ran.
      return const [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsListProvider);
    final theme = Theme.of(context);
    final l = L.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.insightsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l.insightsAnalyzeWeek,
            onPressed: () => _regenerate(ref),
          ),
        ],
      ),
      body: insights.isEmpty
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: l.insightsEmptyTitle,
              message: l.insightsEmptyBody,
              actionLabel: l.insightsAnalyzeWeek,
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
                    Icons.celebration_rounded,
                  ),
                  InsightSeverity.info => (
                    AppColors.ocean,
                    Icons.lightbulb_rounded,
                  ),
                  InsightSeverity.nudge => (
                    AppColors.sun,
                    Icons.tips_and_updates_rounded,
                  ),
                  InsightSeverity.warning => (
                    AppColors.coral,
                    Icons.priority_high_rounded,
                  ),
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SanoraCard(
                    onTap: () {
                      ref.read(insightsRepositoryProvider).markRead(insight);
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
                              Text(
                                insight.title,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                insight.body,
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (insight.action.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                if (insight.actionRoute.isEmpty)
                                  Text(
                                    insight.action,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: color,
                                    ),
                                  )
                                else
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: color,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 36),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(insightsRepositoryProvider)
                                          .markRead(insight);
                                      ref.invalidate(insightsListProvider);
                                      context.push(insight.actionRoute);
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(insight.action),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
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
