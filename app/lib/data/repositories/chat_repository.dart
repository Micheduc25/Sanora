import '../../core/storage/local_store.dart';
import '../../domain/models/chat_message.dart';
import '../sync/sync_service.dart';

class ChatRepository {
  ChatRepository(this._sync);

  final SyncService _sync;

  List<ChatMessage> history() =>
      LocalStore.readAll(LocalStore.chatBox, ChatMessage.fromJson)
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  /// The AI context window: last [limit] finalized messages.
  List<Map<String, String>> recentForContext({int limit = 20}) {
    final messages = history().where((m) => !m.pending).toList();
    final start = messages.length <= limit ? 0 : messages.length - limit;
    return messages
        .sublist(start)
        .map((m) => {'role': m.role.name, 'content': m.content})
        .toList();
  }

  Future<void> save(ChatMessage message) async {
    await LocalStore.put(LocalStore.chatBox, message.id, message.toJson());
    if (!message.pending) {
      await _sync.enqueue('chat_messages', 'upsert', message.toJson());
    }
  }

  Future<void> remove(String id) =>
      LocalStore.delete(LocalStore.chatBox, id);

  Future<void> clear() => LocalStore.box(LocalStore.chatBox).clear();
}
