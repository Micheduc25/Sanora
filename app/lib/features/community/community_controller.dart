import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../domain/models/community.dart';

final friendsProvider = FutureProvider.autoDispose<List<Friend>>(
  (ref) => ref.watch(communityRepositoryProvider).friends(),
);

final myGroupsProvider = FutureProvider.autoDispose<List<CommunityGroup>>(
  (ref) => ref.watch(communityRepositoryProvider).myGroups(),
);

final discoverGroupsProvider = FutureProvider.autoDispose<List<CommunityGroup>>(
  (ref) => ref.watch(communityRepositoryProvider).discoverGroups(),
);

final groupChallengesProvider = FutureProvider.autoDispose
    .family<List<ChallengeSummary>, String>(
      (ref, groupId) =>
          ref.watch(communityRepositoryProvider).groupChallenges(groupId),
    );

final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntry>, String>(
      (ref, challengeId) =>
          ref.watch(communityRepositoryProvider).leaderboard(challengeId),
    );

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
