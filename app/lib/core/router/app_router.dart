import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/coach/coach_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/health/log_metric_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/legal/legal_screen.dart';
import '../../features/meals/log_meal_screen.dart';
import '../../features/meals/meals_screen.dart';
import '../../features/onboarding/generating_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/premium/paywall_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/language_screen.dart';
import '../../features/workouts/workouts_screen.dart';
import '../../domain/models/enums.dart';
import '../../l10n/app_localizations.dart';
import '../providers/app_providers.dart';

/// Bridges a stream to [GoRouter.refreshListenable], which only speaks
/// [Listenable].
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authChanges = ref.watch(supabaseServiceProvider).authChanges;
  final refresh = authChanges == null ? null : _StreamListenable(authChanges);
  if (refresh != null) ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    // Sign-in and sign-out change which profile the app should be showing.
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      // Signing in is how a returning user restores their profile onto a new
      // device, so auth has to stay reachable before one exists locally. The
      // legal documents must be reachable for the same reason and one more:
      // Play's Health Connect review opens the privacy policy on a fresh
      // install, before anyone has onboarded.
      if (location == '/auth' || location.startsWith('/legal')) return null;
      final hasProfile =
          ref.read(profileRepositoryProvider).getProfile() != null;
      final inOnboarding = location.startsWith('/onboarding');
      if (!hasProfile && !inOnboarding) return '/onboarding';
      if (hasProfile && inOnboarding && location != '/onboarding/generating') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'generating',
            builder: (context, state) => const GeneratingScreen(),
          ),
        ],
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const OnboardingScreen(editing: true),
      ),
      GoRoute(
        path: '/settings/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/meals/log',
        builder: (context, state) => const LogMealScreen(),
      ),
      GoRoute(
        path: '/health/log',
        builder: (context, state) {
          final typeName = state.uri.queryParameters['type'];
          final type = MetricType.values
              .where((t) => t.name == typeName)
              .firstOrNull;
          return LogMetricScreen(initialType: type);
        },
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/workouts',
        builder: (context, state) => const WorkoutsScreen(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/community',
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocument.privacy),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocument.terms),
      ),
      GoRoute(
        path: '/legal/disclaimer',
        builder: (context, state) =>
            const LegalScreen(document: LegalDocument.disclaimer),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meals',
                builder: (context, state) => const MealsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/coach',
                builder: (context, state) => const CoachScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/health',
                builder: (context, state) => const HealthScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.space_dashboard_outlined),
            selectedIcon: const Icon(Icons.space_dashboard_rounded),
            label: l.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: const Icon(Icons.restaurant_rounded),
            label: l.navMeals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum_rounded),
            label: l.navCoach,
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_heart_outlined),
            selectedIcon: const Icon(Icons.monitor_heart_rounded),
            label: l.navHealth,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l.navYou,
          ),
        ],
      ),
    );
  }
}
