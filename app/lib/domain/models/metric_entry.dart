import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'metric_entry.freezed.dart';
part 'metric_entry.g.dart';

@freezed
abstract class MetricEntry with _$MetricEntry {
  const factory MetricEntry({
    required String id,
    required MetricType type,
    required double value,
    @Default('') String note,
    required DateTime recordedAt,
  }) = _MetricEntry;

  factory MetricEntry.fromJson(Map<String, dynamic> json) =>
      _$MetricEntryFromJson(json);
}
