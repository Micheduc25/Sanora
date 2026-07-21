import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failures.dart';
import '../../domain/models/community.dart';
import '../supabase_service.dart';

/// Community is inherently online and social, so — unlike the rest of Sanora —
/// it reads and writes Supabase directly rather than the local store. Every
/// call requires a signed-in session; otherwise it surfaces [AuthFailure] so
/// the UI can show a sign-in gate.
class CommunityRepository {
  CommunityRepository(this._supabase);

  final SupabaseService _supabase;

  SupabaseClient get _client {
    final client = _supabase.client;
    if (client == null || !_supabase.isSignedIn) {
      // Telling someone whose session is still coming back to sign in is worse
      // than telling them to wait — the same rule AiService follows.
      if (_supabase.isRestoringSession) {
        throw const NetworkFailure('Reconnecting to your account…');
      }
      throw const AuthFailure(
        'Sign in to connect with friends, groups and challenges.',
      );
    }
    return client;
  }

  /// Runs one RPC and turns everything it can throw into a [Failure].
  ///
  /// Without this the UI cannot tell a dropped connection from a refusal, and
  /// both arrive as "Something went wrong" — the generic fallback in
  /// [messageFor] for anything that is not a [Failure].
  Future<dynamic> _rpc(String function, [Map<String, dynamic>? params]) async {
    final client = _client;
    try {
      return await client.rpc(function, params: params);
    } on PostgrestException catch (e) {
      // The membership guards raise; their messages are written to be read.
      if (e.code == '42501' || e.code == 'P0001') {
        throw ValidationFailure(e.message);
      }
      throw const ServerFailure();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const NetworkFailure(
        'No connection. Community needs one — the rest of Sanora works '
        'offline.',
      );
    }
  }

  List<Map<String, dynamic>> _rows(dynamic result) =>
      (result as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<List<Friend>> friends() async =>
      _rows(await _rpc('my_friends')).map(Friend.fromJson).toList();

  /// Returns a status code: ok | not_found | self | already_friends | blocked.
  Future<String> requestFriend(String email) async {
    final result = await _rpc('send_friend_request', {'p_email': email});
    return result as String;
  }

  Future<void> respondToRequest(String requesterId, {required bool accept}) =>
      _rpc('respond_friend_request', {
        'p_requester': requesterId,
        'p_accept': accept,
      });

  Future<void> removeFriend(String userId) =>
      _rpc('remove_friend', {'p_other': userId});

  Future<void> blockUser(String userId) =>
      _rpc('block_user', {'p_other': userId});

  Future<void> unblockUser(String userId) =>
      _rpc('unblock_user', {'p_other': userId});

  /// Flags a group, a challenge or a person for review.
  ///
  /// [targetType] is one of group | challenge | user; [reason] one of
  /// spam | harassment | hate | sexual | other. Reporting the same target
  /// again replaces the previous report rather than adding one.
  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String note = '',
  }) => _rpc('report_content', {
    'p_target_type': targetType,
    'p_target_id': targetId,
    'p_reason': reason,
    'p_note': note,
  });

  Future<List<CommunityGroup>> myGroups() async =>
      _rows(await _rpc('my_groups')).map(CommunityGroup.fromJson).toList();

  Future<List<CommunityGroup>> discoverGroups() async => _rows(
    await _rpc('discover_groups'),
  ).map(CommunityGroup.fromJson).toList();

  Future<String> createGroup({
    required String name,
    String description = '',
    bool isPrivate = true,
  }) async {
    final result = await _rpc('create_group', {
      'p_name': name,
      'p_description': description,
      'p_private': isPrivate,
    });
    return result as String;
  }

  Future<void> joinGroup(String groupId) =>
      _rpc('join_group', {'p_group': groupId});

  Future<void> leaveGroup(String groupId) =>
      _rpc('leave_group', {'p_group': groupId});

  /// Returns a status code:
  /// ok | not_found | self | not_owner | already_member | already_invited |
  /// blocked.
  Future<String> inviteToGroup(String groupId, String email) async {
    final result = await _rpc('invite_to_group', {
      'p_group': groupId,
      'p_email': email,
    });
    return result as String;
  }

  Future<List<GroupInvite>> myInvites() async =>
      _rows(await _rpc('my_group_invites')).map(GroupInvite.fromJson).toList();

  Future<List<SentGroupInvite>> groupInvites(String groupId) async => _rows(
    await _rpc('group_invites', {'p_group': groupId}),
  ).map(SentGroupInvite.fromJson).toList();

  /// Returns the group joined, so the caller knows what to refresh.
  Future<String> acceptInvite(String inviteId) async {
    final result = await _rpc('accept_group_invite', {'p_invite': inviteId});
    return result as String;
  }

  /// Serves both sides: the owner revoking and the invitee declining.
  Future<void> revokeInvite(String inviteId) =>
      _rpc('revoke_group_invite', {'p_invite': inviteId});

  Future<List<ChallengeSummary>> groupChallenges(String groupId) async => _rows(
    await _rpc('group_challenges', {'p_group': groupId}),
  ).map(ChallengeSummary.fromJson).toList();

  Future<String> createChallenge({
    required String groupId,
    required String name,
    required String metric,
    required double target,
    required DateTime starts,
    required DateTime ends,
  }) async {
    final result = await _rpc('create_challenge', {
      'p_group': groupId,
      'p_name': name,
      'p_metric': metric,
      'p_target': target,
      'p_starts': starts.toIso8601String().split('T').first,
      'p_ends': ends.toIso8601String().split('T').first,
    });
    return result as String;
  }

  Future<void> joinChallenge(String challengeId) =>
      _rpc('join_challenge', {'p_challenge': challengeId});

  Future<void> setProgress(String challengeId, double progress) => _rpc(
    'set_challenge_progress',
    {'p_challenge': challengeId, 'p_progress': progress},
  );

  Future<List<LeaderboardEntry>> leaderboard(String challengeId) async => _rows(
    await _rpc('challenge_leaderboard', {'p_challenge': challengeId}),
  ).map(LeaderboardEntry.fromJson).toList();
}
