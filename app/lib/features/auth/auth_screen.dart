import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';

/// Email + password auth backed by Supabase. Fully skippable: Bodi is
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
    final theme = Theme.of(context);

    Future<void> submit() async {
      final client = ref.read(supabaseServiceProvider).client;
      if (client == null) return;
      loading.value = true;
      error.value = null;
      try {
        if (isSignUp.value) {
          await client.auth.signUp(
            email: email.text.trim(),
            password: password.text,
          );
        } else {
          await client.auth.signInWithPassword(
            email: email.text.trim(),
            password: password.text,
          );
        }
        await ref.read(syncServiceProvider).flush();
        if (context.mounted) context.go('/');
      } on AuthException catch (e) {
        error.value = e.message;
      } catch (_) {
        error.value = 'Could not reach the server. Please try again.';
      } finally {
        loading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            isSignUp.value ? 'Create your account' : 'Welcome back',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'An account keeps your data safe across devices and unlocks the AI coach, meal recognition and insights.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          if (!AppConfig.hasSupabase)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'This build has no backend configured. You can keep using '
                  'Bodi fully offline — everything is stored on your device.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
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
                  : Text(isSignUp.value ? 'Sign up' : 'Sign in'),
            ),
            TextButton(
              onPressed: () => isSignUp.value = !isSignUp.value,
              child: Text(
                isSignUp.value
                    ? 'I already have an account'
                    : 'New here? Create an account',
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('Continue without an account'),
          ),
        ],
      ),
    );
  }
}
