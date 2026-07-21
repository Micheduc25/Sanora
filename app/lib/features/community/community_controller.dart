import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/models/community.dart';

/// Everything here lives on the server, and the server has no way to tell this
/// device that a friend accepted an invite or that someone passed you on a
/// leaderboard. Re-asking on a timer is what stands in for that; it runs only
/// while a community screen is watching, and [appResumeProvider] covers the
/// gap while the app was away.
final communityTickProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream.periodic(const Duration(seconds: 60), (tick) => tick),
);

/// Watched by every community read: the session gate ([AuthFailure] and the
/// sign-in gate it drives), plus the two freshness signals. Signing in has to
/// reach these or the gate stays up over a perfectly good session.
void _communityDeps(Ref ref) {
  ref.watch(isSignedInProvider);
  ref.watch(communityTickProvider);
  ref.watch(appResumeProvider);
}

final friendsProvider = FutureProvider.autoDispose<List<Friend>>((ref) {
  _communityDeps(ref);
  return ref.watch(communityRepositoryProvider).friends();
});

final myGroupsProvider = FutureProvider.autoDispose<List<CommunityGroup>>((
  ref,
) {
  _communityDeps(ref);
  return ref.watch(communityRepositoryProvider).myGroups();
});

final discoverGroupsProvider = FutureProvider.autoDispose<List<CommunityGroup>>(
  (ref) {
    _communityDeps(ref);
    return ref.watch(communityRepositoryProvider).discoverGroups();
  },
);

final myInvitesProvider = FutureProvider.autoDispose<List<GroupInvite>>((ref) {
  _communityDeps(ref);
  return ref.watch(communityRepositoryProvider).myInvites();
});

final groupInvitesProvider = FutureProvider.autoDispose
    .family<List<SentGroupInvite>, String>((ref, groupId) {
      _communityDeps(ref);
      return ref.watch(communityRepositoryProvider).groupInvites(groupId);
    });

final groupChallengesProvider = FutureProvider.autoDispose
    .family<List<ChallengeSummary>, String>((ref, groupId) {
      _communityDeps(ref);
      return ref.watch(communityRepositoryProvider).groupChallenges(groupId);
    });

final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, String>((ref, challengeId) {
      _communityDeps(ref);
      return ref.watch(communityRepositoryProvider).leaderboard(challengeId);
    });

class CommunityController {
  CommunityController(this._ref);

  final Ref _ref;

  void _refreshFriends() => _ref.invalidate(friendsProvider);
  void _refreshGroups() {
    _ref.invalidate(myGroupsProvider);
    _ref.invalidate(discoverGroupsProvider);
  }

  Future<String> requestFriend(String email) async {
    final code = await _ref
        .read(communityRepositoryProvider)
        .requestFriend(email);
    _refreshFriends();
    return code;
  }

  Future<void> respond(String requesterId, {required bool accept}) async {
    await _ref
        .read(communityRepositoryProvider)
        .respondToRequest(requesterId, accept: accept);
    _refreshFriends();
  }

  Future<void> removeFriend(String userId) async {
    await _ref.read(communityRepositoryProvider).removeFriend(userId);
    _refreshFriends();
  }

  Future<void> blockUser(String userId) async {
    await _ref.read(communityRepositoryProvider).blockUser(userId);
    _refreshFriends();
  }

  Future<void> unblockUser(String userId) async {
    await _ref.read(communityRepositoryProvider).unblockUser(userId);
    _refreshFriends();
  }

  /// Nothing on this device changes when a report lands — the row is ours to
  /// act on, not theirs to see — so there is no provider to invalidate.
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String note = '',
  }) => _ref
      .read(communityRepositoryProvider)
      .reportContent(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        note: note,
      );

  Future<void> createGroup({
    required String name,
    required String description,
    required bool isPrivate,
  }) async {
    await _ref
        .read(communityRepositoryProvider)
        .createGroup(
          name: name,
          description: description,
          isPrivate: isPrivate,
        );
    _refreshGroups();
  }

  Future<void> joinGroup(String groupId) async {
    await _ref.read(communityRepositoryProvider).joinGroup(groupId);
    _refreshGroups();
  }

  Future<void> leaveGroup(String groupId) async {
    await _ref.read(communityRepositoryProvider).leaveGroup(groupId);
    _refreshGroups();
  }

  Future<String> inviteToGroup(String groupId, String email) async {
    final code = await _ref
        .read(communityRepositoryProvider)
        .inviteToGroup(groupId, email);
    _ref.invalidate(groupInvitesProvider(groupId));
    return code;
  }

  Future<void> acceptInvite(String inviteId) async {
    await _ref.read(communityRepositoryProvider).acceptInvite(inviteId);
    _ref.invalidate(myInvitesProvider);
    _refreshGroups();
  }

  /// The owner revoking one they sent, or the invitee declining.
  Future<void> revokeInvite(String inviteId, {String? groupId}) async {
    await _ref.read(communityRepositoryProvider).revokeInvite(inviteId);
    _ref.invalidate(myInvitesProvider);
    if (groupId != null) _ref.invalidate(groupInvitesProvider(groupId));
  }

  Future<void> createChallenge({
    required String groupId,
    required String name,
    required String metric,
    required double target,
    required DateTime starts,
    required DateTime ends,
  }) async {
    await _ref
        .read(communityRepositoryProvider)
        .createChallenge(
          groupId: groupId,
          name: name,
          metric: metric,
          target: target,
          starts: starts,
          ends: ends,
        );
    _ref.invalidate(groupChallengesProvider(groupId));
  }

  Future<void> joinChallenge(String groupId, String challengeId) async {
    await _ref.read(communityRepositoryProvider).joinChallenge(challengeId);
    _ref.invalidate(groupChallengesProvider(groupId));
    _ref.invalidate(leaderboardProvider(challengeId));
  }

  Future<void> setProgress(
    String groupId,
    String challengeId,
    double progress,
  ) async {
    await _ref
        .read(communityRepositoryProvider)
        .setProgress(challengeId, progress);
    _ref.invalidate(groupChallengesProvider(groupId));
    _ref.invalidate(leaderboardProvider(challengeId));
  }
}

final communityControllerProvider = Provider((ref) => CommunityController(ref));
