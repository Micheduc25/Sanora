import '../../core/storage/local_store.dart';
import '../../domain/models/insight.dart';

/// Deliberately device-local and the only repository without a [SyncService].
///
/// Insights are derived, not authored: [InsightRulesEngine] regenerates them
/// from the meals and metrics that do sync, so a restored device rebuilds them
/// on its own. A table would add a write path and a conflict story for data the
/// app can recompute for free. The one real cost is that read state does not
/// follow the user between devices.
class InsightsRepository {
  List<Insight> all() =>
      LocalStore.readAll(LocalStore.insightsBox, Insight.fromJson)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> save(Insight insight) =>
      LocalStore.put(LocalStore.insightsBox, insight.id, insight.toJson());

  Future<void> replaceAll(List<Insight> insights) async {
    await LocalStore.box(LocalStore.insightsBox).clear();
    for (final insight in insights) {
      await save(insight);
    }
  }

  Future<void> markRead(Insight insight) => save(insight.copyWith(read: true));
}
