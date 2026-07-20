import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/bodi_card.dart';
import '../../domain/models/enums.dart';
import '../onboarding/onboarding_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final health = ref.watch(healthProfileProvider);
    final supabase = ref.watch(supabaseServiceProvider);
    final theme = Theme.of(context);

    if (profile == null || health == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final riskColor = switch (health.visceralFatRisk) {
      RiskBand.low => AppColors.success,
      RiskBand.moderate => AppColors.sun,
      RiskBand.elevated => AppColors.calories,
      RiskBand.high => AppColors.coral,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          BodiCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    profile.name.isEmpty
                        ? '🙂'
                        : profile.name[0].toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          profile.name.isEmpty ? 'Your profile' : profile.name,
                          style: theme.textTheme.titleLarge),
                      Text(
                        '${profile.age} · ${profile.sex.label} · ${profile.heightCm.round()} cm'
                        '${profile.country.isEmpty ? '' : ' · ${profile.country}'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SectionHeader('Your health profile'),
          BodiCard(
            child: Column(
              children: [
                _ProfileRow('BMI',
                    '${health.bmi.trimZeros()} · ${health.bmiCategory.label}'),
                _ProfileRow('Estimated body fat',
                    '${health.estimatedBodyFatPct.trimZeros()} %'),
                _ProfileRow('Basal metabolic rate',
                    '${health.bmr.round()} kcal'),
                _ProfileRow(
                    'Daily energy needs', '${health.tdee.round()} kcal'),
                _ProfileRow('Daily calorie target',
                    '${health.calorieTarget.round()} kcal'),
                _ProfileRow('Protein target',
                    '${health.proteinTargetG.round()} g'),
                _ProfileRow('Water target',
                    '${(health.waterTargetMl / 1000).trimZeros()} L'),
                _ProfileRow('Step goal', '${health.stepGoal}'),
                _ProfileRow('Sleep goal',
                    '${health.sleepGoalHours.trimZeros()} h'),
                _ProfileRow(
                  'Healthy weight range',
                  '${health.healthyWeightMinKg.round()}–${health.healthyWeightMaxKg.round()} kg',
                ),
                if (health.waistToHeightRatio != null)
                  _ProfileRow('Waist-to-height ratio',
                      '${health.waistToHeightRatio}'),
                _ProfileRow('Visceral fat risk',
                    health.visceralFatRisk.label,
                    valueColor: riskColor),
                _ProfileRow('Metabolic health score',
                    '${health.metabolicHealthScore}/100'),
                _ProfileRow('Lifestyle risk score',
                    '${health.lifestyleRiskScore}/100'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recomputed automatically whenever your measurements change. '
            'Estimates are informational, not medical advice.',
            style: theme.textTheme.bodySmall,
          ),
          SectionHeader('Account & data'),
          BodiCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_rounded),
                  title: Text(supabase.isSignedIn
                      ? 'Cloud sync is on'
                      : 'Sign in to sync & unlock AI'),
                  subtitle: Text(supabase.isSignedIn
                      ? 'Your data backs up automatically.'
                      : 'Your data currently lives only on this device.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    if (supabase.isSignedIn) {
                      await supabase.client?.auth.signOut();
                      ref.invalidate(userProfileProvider);
                    } else {
                      context.push('/auth');
                    }
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Update measurements'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/health/log'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_rounded),
                  title: const Text('Reminders'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/reminders'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.delete_forever_rounded,
                      color: theme.colorScheme.error),
                  title: Text('Delete all my data',
                      style:
                          TextStyle(color: theme.colorScheme.error)),
                  onTap: () => _confirmWipe(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
            'This removes your profile, meals, measurements, habits and chat history from this device. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(profileRepositoryProvider).clear();
    ref.invalidate(userProfileProvider);
    ref.invalidate(healthProfileProvider);
    if (context.mounted) context.go('/onboarding');
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
