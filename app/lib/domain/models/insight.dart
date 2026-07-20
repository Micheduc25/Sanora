import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight.freezed.dart';
part 'insight.g.dart';

enum InsightSeverity {
  @JsonValue('celebrate')
  celebrate,
  @JsonValue('info')
  info,
  @JsonValue('nudge')
  nudge,
  @JsonValue('warning')
  warning,
}

@freezed
abstract class Insight with _$Insight {
  const factory Insight({
    required String id,
    required String title,
    required String body,
    @Default(InsightSeverity.info) InsightSeverity severity,
    @Default('') String action,
    @Default(false) bool read,
    required DateTime createdAt,
  }) = _Insight;

  factory Insight.fromJson(Map<String, dynamic> json) =>
      _$InsightFromJson(json);
}
