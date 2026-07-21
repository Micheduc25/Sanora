import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../storage/local_store.dart';

/// Locales Bodi ships. English and French cover the app's target markets;
/// French is not optional here — Cameroon is officially bilingual and the
/// meal parser already accepts French input.
const supportedLocales = [Locale('en'), Locale('fr')];

/// The user's explicit language choice, or null to follow the device.
///
/// Stored in settings rather than on the profile: it is a device preference,
/// and a user restoring onto a French phone should get French immediately,
/// before any profile has been pulled down.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'locale';

  @override
  Locale? build() {
    final code = LocalStore.get(LocalStore.settingsBox, _key)?['code'];
    if (code is! String || code.isEmpty) return null;
    return supportedLocales
        .where((l) => l.languageCode == code)
        .cast<Locale?>()
        .firstWhere((l) => true, orElse: () => null);
  }

  /// Pass null to go back to following the device language.
  Future<void> set(Locale? locale) async {
    await LocalStore.put(LocalStore.settingsBox, _key, {
      'code': locale?.languageCode ?? '',
    });
    state = locale;
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
