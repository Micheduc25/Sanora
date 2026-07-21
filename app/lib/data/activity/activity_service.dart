import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../../core/storage/local_store.dart';

/// Bridges HealthKit (iOS) and Health Connect (Android). Falls back to
/// zero-values when the platform store is unavailable or permission is
/// denied — the app then relies on manually logged steps.
class ActivityService {
  final _health = Health();
  bool _configured = false;

  /// Exactly what the app reads, nothing held in reserve: Health Connect
  /// review rejects an app that asks for a permission it never uses, and the
  /// permission sheet is easier to say yes to when every row is justified.
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
  ];

  /// Every read has to go through this. The plugin returns nothing at all
  /// until `configure()` has run, and a read on an unconfigured instance
  /// throws — which the catch blocks below would quietly turn into "0 steps".
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Types the platform has confirmed we may read.
  ///
  /// Health Connect throws a `SecurityException` for every unauthorised read,
  /// and the plugin logs the native stack trace before our catch blocks ever
  /// see it — so a user who has not granted access gets four stack traces per
  /// dashboard refresh and we still return zeroes. Asking first is quieter and
  /// cheaper than catching afterwards.
  ///
  /// Only grants are remembered. A denial has to be re-checked, or granting
  /// access in system settings would not take effect until the app restarts.
  final _granted = <HealthDataType>{};

  Future<bool> _canRead(HealthDataType type) async {
    if (_granted.contains(type)) return true;
    try {
      await _ensureConfigured();
      // HealthKit refuses to disclose read access; null means "try and see".
      final granted = await _health.hasPermissions([type]) ?? true;
      if (granted) _granted.add(type);
      return granted;
    } catch (e) {
      debugPrint('activity: permission check failed for $type: $e');
      return false;
    }
  }

  static const _askedKey = 'health_permission_requested';

  /// HealthKit will not tell an app whether it has *read* access — Apple treats
  /// the answer as itself revealing (a refusal implies the data exists). So
  /// `hasPermissions` can return true for types the user has never seen a
  /// prompt for, and gating the connect card on it alone hides it forever.
  /// Whether we have actually shown the prompt is the signal we can trust.
  bool get _hasBeenAsked =>
      LocalStore.get(LocalStore.settingsBox, _askedKey)?['value'] == true;

  /// Whether to stop offering the connect prompt: either the user has already
  /// been through it, or the platform positively confirms access.
  Future<bool> isConnected() async {
    if (!_hasBeenAsked) return false;
    try {
      await _ensureConfigured();
      // Health Connect grants type by type, and `hasPermissions` over the
      // whole list answers "all of them". Requiring that leaves the connect
      // prompt on screen forever for someone who allowed steps but not sleep.
      for (final type in _types) {
        // Null means "cannot say" (the iOS read case) — having asked is enough.
        if (await _health.hasPermissions([type]) ?? true) return true;
      }
      return false;
    } catch (e) {
      debugPrint('activity: permission check failed: $e');
      return false;
    }
  }

  /// Records that the prompt was shown even when it fails, so a user who
  /// declines is not asked again on every dashboard build.
  Future<bool> requestPermissions() async {
    await LocalStore.put(LocalStore.settingsBox, _askedKey, {'value': true});
    try {
      await _ensureConfigured();
      _granted.clear();
      return await _health.requestAuthorization(_types);
    } catch (e) {
      debugPrint('activity: authorization failed: $e');
      return false;
    }
  }

  Future<int> stepsToday() async {
    if (!await _canRead(HealthDataType.STEPS)) return 0;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      return await _health.getTotalStepsInInterval(midnight, now) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Platform step total for one calendar day. The weekly report needs this
  /// so its numbers match the dashboard instead of counting manual logs only.
  Future<int> stepsForDay(DateTime day) async {
    if (!await _canRead(HealthDataType.STEPS)) return 0;
    try {
      await _ensureConfigured();
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      final now = DateTime.now();
      return await _health.getTotalStepsInInterval(
            start,
            end.isAfter(now) ? now : end,
          ) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  Future<double> activeCaloriesToday() async {
    if (!await _canRead(HealthDataType.ACTIVE_ENERGY_BURNED)) return 0;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      return points.fold<double>(0.0, (sum, p) {
        final value = p.value;
        return value is NumericHealthValue
            ? sum + value.numericValue.toDouble()
            : sum;
      });
    } catch (_) {
      return 0;
    }
  }

  Future<double?> latestHeartRate() async {
    if (!await _canRead(HealthDataType.HEART_RATE)) return null;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: now.subtract(const Duration(hours: 24)),
        endTime: now,
      );
      if (points.isEmpty) return null;
      points.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = points.first.value;
      return value is NumericHealthValue ? value.numericValue.toDouble() : null;
    } catch (_) {
      return null;
    }
  }

  Future<double?> sleepHoursLastNight() async {
    if (!await _canRead(HealthDataType.SLEEP_ASLEEP)) return null;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final from = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(hours: 6));
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: from,
        endTime: now,
      );
      if (points.isEmpty) return null;
      final minutes = points.fold(
        0.0,
        (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes,
      );
      return minutes / 60;
    } catch (_) {
      return null;
    }
  }
}
