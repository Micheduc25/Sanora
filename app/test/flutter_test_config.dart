import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auto-loaded by flutter_test for every test in this directory tree. Loads
/// the bundled brand fonts so golden tests render real glyphs instead of the
/// blank test fallback.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _load('Inter', const [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
  ]);
  await _load('Manrope', const [
    'assets/fonts/Manrope-Bold.ttf',
    'assets/fonts/Manrope-ExtraBold.ttf',
  ]);
  await testMain();
}

Future<void> _load(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}
