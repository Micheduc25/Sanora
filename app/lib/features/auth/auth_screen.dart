import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';

/// Email + password auth backed by Supabase. Fully skippable: Sanora is
/// offline-first and an account only adds cloud sync and AI features.
class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = useTextEditingController();
    final password = useTextEditingController();
    final isSignUp = useState(false);
    final loading = useState(false);
    final error = useState<String?>(null);
    final notice = useState<String?>(null);
    final theme = Theme.of(context);
    final l = L.of(context);

    Future<void> submit() async {
      final client = ref.read(supabaseServiceProvider).client;
      if (client == null) return;
      loading.value = true;
      error.value = null;
      notice.value = null;
      try {
        if (isSignUp.value) {
          final result = await client.auth.signUp(
            email: email.text.trim(),
            password: password.text,
          );
          // With email confirmation on — the Supabase default — there is no
          // session yet, so routing into the app would fake a signed-in state.
          if (result.session == null) {
            notice.value = l.authConfirmationSent(email.text.trim());
            isSignUp.value = false;
            return;
          }
        } else {
          await client.auth.signInWithPassword(
            email: email.text.trim(),
            password: password.text,
          );
        }
        // Push anything queued locally, then restore whatever this device is
        // missing, so a reinstall or a second device lands on real data.
        await ref.read(syncServiceProvider).synchronise();
        if (!context.mounted) return;
        final restored =
            ref.read(profileRepositoryProvider).getProfile() != null;
        context.go(restored ? '/' : '/onboarding');
      } on AuthException catch (e) {
        error.value = e.message;
      } catch (_) {
        error.value = l.authServerUnreachable;
      } finally {
        loading.value = false;
      }
    }

    Future<void> resetPassword() async {
      final client = ref.read(supabaseServiceProvider).client;
      final address = email.text.trim();
      if (client == null) return;
      if (address.isEmpty) {
        error.value = l.authEnterEmailFirst;
        return;
      }
      loading.value = true;
      error.value = null;
      notice.value = null;
      try {
        await client.auth.resetPasswordForEmail(address);
        notice.value = l.authResetLinkSent(address);
      } on AuthException catch (e) {
        error.value = e.message;
      } catch (_) {
        error.value = l.authServerUnreachable;
      } finally {
        loading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.authTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            isSignUp.value ? l.authCreateAccount : l.authWelcomeBack,
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            l.authIntro,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          if (!AppConfig.hasSupabase)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.authNoBackend, style: theme.textTheme.bodyMedium),
              ),
            )
          else ...[
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: l.authEmailHint,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                hintText: l.authPasswordHint,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
              ),
            ),
            if (error.value != null) ...[
              const SizedBox(height: 12),
              Text(
                error.value!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (notice.value != null) ...[
              const SizedBox(height: 12),
              Text(
                notice.value!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loading.value ? null : submit,
              child: loading.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(isSignUp.value ? l.authSignUp : l.authSignIn),
            ),
            TextButton(
              onPressed: () => isSignUp.value = !isSignUp.value,
              child: Text(isSignUp.value ? l.authHaveAccount : l.authNewHere),
            ),
            if (!isSignUp.value)
              TextButton(
                onPressed: loading.value ? null : resetPassword,
                child: Text(l.authForgotPassword),
              ),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: Text(l.authContinueWithoutAccount),
          ),
        ],
      ),
    );
  }
}
