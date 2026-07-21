import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sanora_card.dart';
import '../../l10n/app_localizations.dart';
import 'premium_controller.dart';
import 'premium_products.dart';

/// The one thing Premium changes is the AI allowance. The screen says that
/// plainly: Apple rejects a paywall that advertises an upgrade it cannot sell,
/// and users leave one that implies their existing features are about to be
/// taken away.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);
    final signedIn = ref.watch(isSignedInProvider);
    final theme = Theme.of(context);
    final l = L.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.premiumTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SanoraCard(
            color: theme.colorScheme.primaryContainer,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  l.premiumHeroTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.premiumHeroBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          SectionHeader(l.premiumUnlocksSection),
          SanoraCard(
            child: Column(
              children: [
                _Feature(
                  icon: Icons.forum_rounded,
                  color: AppColors.vital,
                  title: l.premiumFeatureCoachTitle,
                  body: l.premiumFeatureCoachBody,
                ),
                _Feature(
                  icon: Icons.restaurant_rounded,
                  color: AppColors.calories,
                  title: l.premiumFeatureMealsTitle,
                  body: l.premiumFeatureMealsBody,
                ),
                _Feature(
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.ocean,
                  title: l.premiumFeatureWorkoutsTitle,
                  body: l.premiumFeatureWorkoutsBody,
                ),
                _Feature(
                  icon: Icons.insights_rounded,
                  color: AppColors.lavender,
                  title: l.premiumFeatureInsightsTitle,
                  body: l.premiumFeatureInsightsBody,
                  last: true,
                ),
              ],
            ),
          ),

          SectionHeader(l.premiumFreeForeverSection),
          SanoraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.premiumFreeForeverBody,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.premiumFreeAllowance(
                          PremiumProducts.freeDailyAiCalls,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SectionHeader(l.premiumChoosePlanSection),
          if (!signedIn)
            _NoticeCard(
              icon: Icons.person_outline_rounded,
              title: l.premiumSignInTitle,
              body: l.premiumSignInBody,
              actionLabel: l.premiumSignIn,
              onAction: () => context.push('/auth'),
            )
          else if (state.premium)
            _NoticeCard(
              icon: Icons.verified_rounded,
              color: AppColors.vital,
              title: l.premiumActiveTitle,
              body: state.validUntil == null
                  ? l.premiumActiveBody
                  : l.premiumActiveUntil(_formatDate(state.validUntil!)),
            )
          else if (state.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.unavailable != PremiumUnavailable.none)
            _NoticeCard(
              icon: Icons.storefront_outlined,
              title: l.premiumUnavailableTitle,
              body: _unavailableText(l, state),
              actionLabel: l.actionRetry,
              onAction: () =>
                  ref.read(premiumControllerProvider.notifier).refresh(),
            )
          else
            for (final product in state.products)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanCard(
                  product: product,
                  saving: _savingLabel(l, state.products, product),
                  enabled: !state.busy,
                  onTap: () =>
                      ref.read(premiumControllerProvider.notifier).buy(product),
                ),
              ),

          if (state.notice != PremiumNotice.none) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 3, right: 10),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _noticeText(l, state),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],

          if (signedIn && !state.premium) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: state.busy
                  ? null
                  : () =>
                        ref.read(premiumControllerProvider.notifier).restore(),
              child: Text(l.premiumRestore),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            l.premiumBillingNotice,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              TextButton(
                onPressed: () => context.push('/legal/terms'),
                child: Text(l.premiumTerms),
              ),
              TextButton(
                onPressed: () => context.push('/legal/privacy'),
                child: Text(l.premiumPrivacy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _unavailableText(L l, PremiumState state) =>
      switch (state.unavailable) {
        PremiumUnavailable.none => '',
        PremiumUnavailable.unsupportedPlatform =>
          l.premiumUnavailableUnsupportedPlatform,
        PremiumUnavailable.storeUnavailable => l.premiumUnavailableStore,
        PremiumUnavailable.planQueryFailed => l.premiumUnavailableQueryFailed(
          state.unavailableDetail,
        ),
        PremiumUnavailable.noPlans => l.premiumUnavailableNoPlans,
      };

  static String _noticeText(L l, PremiumState state) => switch (state.notice) {
    PremiumNotice.none => '',
    PremiumNotice.purchaseNotStarted =>
      state.noticeDetail.isEmpty
          ? l.premiumNoticePurchaseNotStarted
          : l.premiumNoticePurchaseNotStartedDetail(state.noticeDetail),
    PremiumNotice.lookingForPurchases => l.premiumNoticeLookingForPurchases,
    PremiumNotice.restoreUnreachable => l.premiumNoticeRestoreUnreachable,
    PremiumNotice.noSubscription => l.premiumNoticeNoSubscription,
    PremiumNotice.awaitingPayment => l.premiumNoticeAwaitingPayment,
    PremiumNotice.checkingPurchase => l.premiumNoticeCheckingPurchase,
    PremiumNotice.purchaseNotCompleted => l.premiumNoticePurchaseNotCompleted,
    PremiumNotice.purchaseNotConfirmed => l.premiumNoticePurchaseNotConfirmed,
    PremiumNotice.signInRequired => l.premiumNoticeSignInRequired,
    PremiumNotice.noReceipt => l.premiumNoticeNoReceipt,
    PremiumNotice.verificationOffline => l.premiumNoticeVerificationOffline,
    PremiumNotice.sessionExpired => l.premiumNoticeSessionExpired,
    // Already a sentence written for a human by the store or our server.
    PremiumNotice.storeMessage => state.noticeDetail,
  };

  /// Only claims a saving when both plans loaded in the same currency and the
  /// arithmetic actually holds.
  static String _savingLabel(
    L l,
    List<ProductDetails> products,
    ProductDetails p,
  ) {
    if (p.id != PremiumProducts.yearly) return '';
    final monthly = products.where(
      (other) => other.id == PremiumProducts.monthly,
    );
    if (monthly.isEmpty || monthly.first.currencyCode != p.currencyCode) {
      return '';
    }
    final year = monthly.first.rawPrice * 12;
    if (year <= 0 || p.rawPrice >= year) return '';
    return l.premiumSave((100 * (1 - p.rawPrice / year)).round());
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
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
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.saving,
    required this.enabled,
    required this.onTap,
  });

  final ProductDetails product;
  final String saving;
  final bool enabled;
  final VoidCallback onTap;

  /// The store returns its own English titles, so the plan name and billing
  /// period are named here instead.
  static String _planName(L l, String productId) => switch (productId) {
    PremiumProducts.monthly => l.premiumPlanMonthly,
    PremiumProducts.yearly => l.premiumPlanYearly,
    _ => productId,
  };

  static String _planPeriod(L l, String productId) => switch (productId) {
    PremiumProducts.monthly => l.premiumPerMonth,
    PremiumProducts.yearly => l.premiumPerYear,
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    return SanoraCard(
      onTap: enabled ? onTap : null,
      borderColor: saving.isEmpty ? null : theme.colorScheme.primary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _planName(l, product.id),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (saving.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Text(
                          saving,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l.premiumPricePerPeriod(
                    product.price,
                    _planPeriod(l, product.id),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.body,
    this.color,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return SanoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tint, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
