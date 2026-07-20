import '../../core/storage/local_store.dart';
import '../../domain/models/insight.dart';

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
