import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum ChatRole {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant,
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required ChatRole role,
    required String content,
    @Default(false) bool pending,
    /// This turn is an error notice, not something the coach said. Shown in
    /// the transcript so the user knows what happened, but kept out of the
    /// context sent back to the model — otherwise the coach is told it
    /// previously answered "Sign in to talk to your coach", and every failure
    /// poisons the next request.
    @Default(false) bool failed,
    required DateTime sentAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
