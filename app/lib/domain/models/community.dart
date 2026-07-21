import 'package:freezed_annotation/freezed_annotation.dart';

part 'community.freezed.dart';
part 'community.g.dart';

enum FriendStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('blocked')
  blocked,
}

@freezed
abstract class Friend with _$Friend {
  const factory Friend({
    required String userId,
    String? name,
    required FriendStatus status,
    @Default(false) bool incoming,
  }) = _Friend;

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
}

@freezed
abstract class CommunityGroup with _$CommunityGroup {
  const factory CommunityGroup({
    required String id,
    required String name,
    @Default('') String description,
    bool? isPrivate,
    @Default(0) int memberCount,
    @Default(false) bool isOwner,
  }) = _CommunityGroup;

  factory CommunityGroup.fromJson(Map<String, dynamic> json) =>
      _$CommunityGroupFromJson(json);
}

/// An invite to a private group, as the person invited sees it: enough about
/// the group to decide on it before joining.
@freezed
abstract class GroupInvite with _$GroupInvite {
  const factory GroupInvite({
    required String id,
    required String groupId,
    required String groupName,
    @Default('') String groupDescription,
    String? invitedBy,
    String? expiresAt,
  }) = _GroupInvite;

  factory GroupInvite.fromJson(Map<String, dynamic> json) =>
      _$GroupInviteFromJson(json);
}

/// An invite the group's owner sent and nobody has answered yet.
@freezed
abstract class SentGroupInvite with _$SentGroupInvite {
  const factory SentGroupInvite({
    required String id,
    required String email,
    String? expiresAt,
  }) = _SentGroupInvite;

  factory SentGroupInvite.fromJson(Map<String, dynamic> json) =>
      _$SentGroupInviteFromJson(json);
}

@freezed
abstract class ChallengeSummary with _$ChallengeSummary {
  const ChallengeSummary._();

  const factory ChallengeSummary({
    required String id,
    required String name,
    required String metric,
    required double target,
    required String startsOn,
    required String endsOn,
    @Default(false) bool joined,
    @Default(0) double myProgress,
  }) = _ChallengeSummary;

  factory ChallengeSummary.fromJson(Map<String, dynamic> json) =>
      _$ChallengeSummaryFromJson(json);

  double get progressFraction =>
      target <= 0 ? 0 : (myProgress / target).clamp(0.0, 1.0);

  String get metricLabel => switch (metric) {
    'steps' => 'steps',
    'workouts' => 'workouts',
    'habit_completion' => 'habit days',
    'water' => 'ml water',
    _ => metric,
  };
}

@freezed
abstract class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String userId,
    @Default('Member') String name,
    @Default(0) double progress,
    required int place,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}
