import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/l10n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

class BodiApp extends ConsumerWidget {
  const BodiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Sanora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Null follows the device. Flutter falls back to English for any locale
      // outside supportedLocales.
      locale: ref.watch(localeControllerProvider),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Runs inside Localizations, so this is the locale actually resolved
      // after device/supported negotiation — not the raw preference. Keeps
      // bare `DateFormat('EEEE, d MMMM')` call sites correct without every
      // one of them having to thread a locale through.
      builder: (context, child) {
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        return child ?? const SizedBox.shrink();
      },
      routerConfig: router,
    );
  }
}
