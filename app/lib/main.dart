import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/local_store.dart';
import 'data/supabase_service.dart';

Future<void> main() async {
  if (AppConfig.hasCrashReporting) {
    await SentryFlutter.init(
      (options) => options
        ..dsn = AppConfig.sentryDsn
        ..environment = AppConfig.releaseChannel
        // Health data is the whole point of the app, so never let request
        // bodies or user content ride along with a crash report.
        ..sendDefaultPii = false
        ..tracesSampleRate = 0.2,
      appRunner: _start,
    );
  } else {
    await _start();
  }
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _report(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _report(error, stack);
    return true;
  };

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Without this every DateFormat falls back to English month and weekday
  // names regardless of the app locale.
  await initializeDateFormatting();
  await Hive.initFlutter();
  await LocalStore.open();
  if (AppConfig.hasSupabase) {
    final storage = SessionRestoreStorage(
      SharedPreferencesLocalStorage(
        persistSessionKey: SupabaseService.persistSessionKey(
          AppConfig.supabaseUrl,
        ),
      ),
    );
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(localStorage: storage),
    );
    // `initialize` returns before the session is back; the app must not start
    // reading auth state until it is, or a signed-in user boots signed out.
    await SupabaseService.awaitSessionRestore(storage);
  }

  // Owned here rather than by ProviderScope so startup work can run against
  // the same container the widget tree will use.
  final container = ProviderContainer();
  // Replays anything queued offline and restores what this install is
  // missing. A no-op when signed out or running local-only.
  unawaited(container.read(syncServiceProvider).synchronise());

  runApp(
    UncontrolledProviderScope(container: container, child: const BodiApp()),
  );
}

void _report(Object error, StackTrace? stack) {
  if (AppConfig.hasCrashReporting) {
    unawaited(Sentry.captureException(error, stackTrace: stack));
  } else {
    debugPrint('unhandled: $error\n$stack');
  }
}
