import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'onboarding_controller.dart';

/// Runs the health engine over the completed draft with a short staged
/// reveal, then lands on the dashboard.
class GeneratingScreen extends ConsumerStatefulWidget {
  const GeneratingScreen({super.key});

  @override
  ConsumerState<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends ConsumerState<GeneratingScreen> {
  static const _stageCount = 5;

  static List<String> _stages(L l) => [
    l.onboardingGeneratingStageMeasurements,
    l.onboardingGeneratingStageEnergy,
    l.onboardingGeneratingStageTargets,
    l.onboardingGeneratingStageRisks,
    l.onboardingGeneratingStagePlan,
  ];

  int _stage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (!mounted) return;
      if (_stage < _stageCount - 1) setState(() => _stage++);
    });
    // Only reached by first-run onboarding; editing saves in place instead.
    final controllerFuture = ref
        .read(onboardingControllerProvider(false).notifier)
        .complete();
    await Future.wait([
      controllerFuture,
      Future.delayed(const Duration(milliseconds: 3600)),
    ]);
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                l.onboardingGeneratingTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _stages(l)[_stage],
                  key: ValueKey(_stage),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
