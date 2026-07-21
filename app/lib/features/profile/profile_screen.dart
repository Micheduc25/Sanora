import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/l10n/enum_labels.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/bodi_card.dart';
import '../../data/sync/sync_service.dart';
import '../../domain/models/enums.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/onboarding_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final health = ref.watch(healthProfileProvider);
    final supabase = ref.watch(supabaseServiceProvider);
    final signedIn = ref.watch(isSignedInProvider);
    final theme = Theme.of(context);
    final l = L.of(context);

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
      appBar: AppBar(title: Text(l.navYou)),
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
                    profile.name.isEmpty ? '🙂' : profile.name[0].toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty
                            ? l.profileNameFallback
                            : profile.name,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        profile.country.isEmpty
                            ? l.profileSummary(
                                '${profile.age}',
                                profile.sex.labelOf(context),
                                '${profile.heightCm.round()}',
                              )
                            : l.profileSummaryWithCountry(
                                '${profile.age}',
                                profile.sex.labelOf(context),
                                '${profile.heightCm.round()}',
                                profile.country,
                              ),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(l.profileHealthSection),
          BodiCard(
            child: Column(
              children: [
                _ProfileRow(
                  l.profileBmi,
                  l.profileBmiValue(
                    health.bmi.trimZeros(),
                    health.bmiCategory.labelOf(context),
                  ),
                ),
                _ProfileRow(
                  l.profileBodyFat,
                  '${health.estimatedBodyFatPct.trimZeros()} %',
                ),
                _ProfileRow(l.profileBmr, '${health.bmr.round()} kcal'),
                _ProfileRow(l.profileTdee, '${health.tdee.round()} kcal'),
                _ProfileRow(
                  l.profileCalorieTarget,
                  '${health.calorieTarget.round()} kcal',
                ),
                _ProfileRow(
                  l.profileProteinTarget,
                  '${health.proteinTargetG.round()} g',
                ),
                _ProfileRow(
                  l.profileWaterTarget,
                  '${(health.waterTargetMl / 1000).trimZeros()} L',
                ),
                _ProfileRow(l.profileStepGoal, '${health.stepGoal}'),
                _ProfileRow(
                  l.profileSleepGoal,
                  '${health.sleepGoalHours.trimZeros()} h',
                ),
                _ProfileRow(
                  l.profileHealthyWeightRange,
                  '${health.healthyWeightMinKg.round()}–${health.healthyWeightMaxKg.round()} kg',
                ),
                if (health.waistToHeightRatio != null)
                  _ProfileRow(
                    l.profileWaistToHeight,
                    '${health.waistToHeightRatio}',
                  ),
                _ProfileRow(
                  l.profileVisceralFatRisk,
                  health.visceralFatRisk.labelOf(context),
                  valueColor: riskColor,
                ),
                _ProfileRow(
                  l.profileMetabolicScore,
                  l.profileScoreOutOf100(health.metabolicHealthScore),
                ),
                _ProfileRow(
                  l.profileLifestyleRiskScore,
                  l.profileScoreOutOf100(health.lifestyleRiskScore),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(l.profileDisclaimer, style: theme.textTheme.bodySmall),
          SectionHeader(l.profileAccountSection),
          BodiCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_rounded),
                  title: Text(
                    signedIn ? l.profileCloudSyncOn : l.profileSignInPrompt,
                  ),
                  subtitle: signedIn
                      ? ValueListenableBuilder<SyncStatus>(
                          valueListenable: ref.read(syncServiceProvider).status,
                          builder: (context, status, _) =>
                              Text(_syncSummary(l, status)),
                        )
                      : Text(l.profileLocalOnly),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    if (signedIn) {
                      await supabase.client?.auth.signOut();
                      ref.invalidate(userProfileProvider);
                    } else {
                      context.push('/auth');
                    }
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(l.profileEditTitle),
                  subtitle: Text(l.profileEditSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    // Drop any draft left over from a previous open so the
                    // wizard re-seeds from the saved profile. Abandoned edits
                    // must not reappear as if they had been saved.
                    ref.invalidate(onboardingControllerProvider(true));
                    context.push('/profile/edit');
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text(l.profileMeasurementsTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/health/log'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(l.settingsLanguage),
                  subtitle: Text(l.settingsLanguageSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/language'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: Text(l.profilePremiumTitle),
                  subtitle: Text(l.profilePremiumSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/premium'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: Text(l.profileCommunityTitle),
                  subtitle: Text(l.profileCommunitySubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/community'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_rounded),
                  title: Text(l.profileRemindersTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/reminders'),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    l.profileDeleteDataTitle,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () => _confirmWipe(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A backup claim the queue can actually back up. Silence about a stuck
  /// queue is what turns "your data is safe" into a lie.
  static String _syncSummary(L l, SyncStatus status) => switch (status.state) {
    SyncState.syncing => l.profileSyncBackingUp,
    SyncState.offline => l.profileSyncWaiting(status.pending),
    SyncState.failed => l.profileSyncFailed(status.rejected),
    SyncState.idle =>
      status.pending > 0
          ? l.profileSyncPending(status.pending)
          : l.profileSyncIdle,
  };

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final signedIn = ref.read(isSignedInProvider);
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showDialog<_WipeScope>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.profileWipeDialogTitle),
        content: Text(
          signedIn ? l.profileWipeBodySignedIn : l.profileWipeBodyLocal,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(l.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _WipeScope.device),
            child: Text(l.profileWipeClearDevice),
          ),
          if (signedIn)
            TextButton(
              onPressed: () => Navigator.pop(context, _WipeScope.account),
              child: Text(
                l.profileWipeDeleteAccount,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
    if (choice == null) return;

    final repo = ref.read(profileRepositoryProvider);
    try {
      if (choice == _WipeScope.account) {
        await repo.deleteAccount();
      } else {
        await repo.clear();
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.profileWipeError)));
      return;
    }
    ref.invalidate(userProfileProvider);
    ref.invalidate(healthProfileProvider);
    if (context.mounted) context.go('/onboarding');
  }
}

enum _WipeScope { device, account }

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
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
