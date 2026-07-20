import '../../core/storage/local_store.dart';
import '../../domain/models/reminder.dart';
import '../notifications/notification_service.dart';
import '../sync/sync_service.dart';

class RemindersRepository {
  RemindersRepository(this._sync, this._notifications);

  final SyncService _sync;
  final NotificationService _notifications;

  List<Reminder> all() =>
      LocalStore.readAll(LocalStore.remindersBox, Reminder.fromJson)
        ..sort((a, b) => a.time.compareTo(b.time));

  Future<void> save(Reminder reminder) async {
    await LocalStore.put(
      LocalStore.remindersBox,
      reminder.id,
      reminder.toJson(),
    );
    await _notifications.schedule(reminder);
    await _sync.enqueue('reminders', 'upsert', reminder.toJson());
  }

  Future<void> remove(Reminder reminder) async {
    await _notifications.cancel(reminder);
    await LocalStore.delete(LocalStore.remindersBox, reminder.id);
    await _sync.enqueue('reminders', 'delete', {'id': reminder.id});
  }
}
