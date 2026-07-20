import '../../core/storage/local_store.dart';
import '../../core/utils/extensions.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/metric_entry.dart';
import '../sync/sync_service.dart';

class MetricsRepository {
  MetricsRepository(this._sync);

  final SyncService _sync;

  List<MetricEntry> all() =>
      LocalStore.readAll(LocalStore.metricsBox, MetricEntry.fromJson)
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  List<MetricEntry> byType(MetricType type) =>
      all().where((e) => e.type == type).toList();

  MetricEntry? latest(MetricType type) {
    final entries = byType(type);
    return entries.isEmpty ? null : entries.first;
  }

  List<MetricEntry> forDay(DateTime day) =>
      all().where((e) => e.recordedAt.isSameDay(day)).toList();

  /// Total for additive metrics (water, steps) on a given day.
  double dayTotal(MetricType type, DateTime day) => forDay(
    day,
  ).where((e) => e.type == type).fold(0.0, (sum, e) => sum + e.value);

  Future<void> add(MetricEntry entry) async {
    await LocalStore.put(LocalStore.metricsBox, entry.id, entry.toJson());
    await _sync.enqueue('metric_entries', 'upsert', entry.toJson());
  }

  Future<void> remove(String id) async {
    await LocalStore.delete(LocalStore.metricsBox, id);
    await _sync.enqueue('metric_entries', 'delete', {'id': id});
  }
}
