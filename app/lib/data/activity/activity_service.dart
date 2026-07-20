import 'package:health/health.dart';

/// Bridges HealthKit (iOS) and Health Connect (Android). Falls back to
/// zero-values when the platform store is unavailable or permission is
/// denied — the app then relies on manually logged steps.
class ActivityService {
  final _health = Health();
  bool _configured = false;

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.DISTANCE_DELTA,
  ];

  Future<bool> requestPermissions() async {
    try {
      if (!_configured) {
        await _health.configure();
        _configured = true;
      }
      return await _health.requestAuthorization(_types);
    } catch (_) {
      return false;
    }
  }

  Future<int> stepsToday() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      return await _health.getTotalStepsInInterval(midnight, now) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<double> activeCaloriesToday() async {
    try {
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
    try {
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
    try {
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
