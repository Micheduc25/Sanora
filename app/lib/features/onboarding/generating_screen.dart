import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'onboarding_controller.dart';

/// Runs the health engine over the completed draft with a short staged
/// reveal, then lands on the dashboard.
class GeneratingScreen extends ConsumerStatefulWidget {
  const GeneratingScreen({super.key});

  @override
  ConsumerState<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends ConsumerState<GeneratingScreen> {
  static const _stages = [
    'Reading your measurements…',
    'Calculating your energy needs…',
    'Setting protein and water targets…',
    'Estimating health risks…',
    'Building your daily plan…',
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
      if (_stage < _stages.length - 1) setState(() => _stage++);
    });
    final controllerFuture = ref
        .read(onboardingControllerProvider.notifier)
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
                'Building your health profile',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _stages[_stage],
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
