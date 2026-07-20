import '../../core/error/failures.dart';
import '../../domain/models/community.dart';
import '../supabase_service.dart';

/// Community is inherently online and social, so — unlike the rest of Bodi —
/// it reads and writes Supabase directly rather than the local store. Every
/// call requires a signed-in session; otherwise it surfaces [AuthFailure] so
/// the UI can show a sign-in gate.
class CommunityRepository {
  CommunityRepository(this._supabase);

  final SupabaseService _supabase;

  dynamic get _client {
    final client = _supabase.client;
    if (client == null || !_supabase.isSignedIn) {
      throw const AuthFailure(
        'Sign in to connect with friends, groups and challenges.',
      );
    }
    return client;
  }

  List<Map<String, dynamic>> _rows(dynamic result) =>
      (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<List<Friend>> friends() async {
    final result = await _client.rpc('my_friends');
    return _rows(result).map(Friend.fromJson).toList();
  }

  /// Returns a status code: ok | not_found | self | already_friends.
  Future<String> requestFriend(String email) async {
    final result = await _client.rpc(
      'send_friend_request',
      params: {'p_email': email},
    );
    return result as String;
  }

  Future<void> respondToRequest(String requesterId, {required bool accept}) =>
      _client.rpc(
        'respond_friend_request',
        params: {'p_requester': requesterId, 'p_accept': accept},
      );

  Future<void> removeFriend(String userId) =>
      _client.rpc('remove_friend', params: {'p_other': userId});

  Future<List<CommunityGroup>> myGroups() async {
    final result = await _client.rpc('my_groups');
    return _rows(result).map(CommunityGroup.fromJson).toList();
  }

  Future<List<CommunityGroup>> discoverGroups() async {
    final result = await _client.rpc('discover_groups');
    return _rows(result).map(CommunityGroup.fromJson).toList();
  }

  Future<String> createGroup({
    required String name,
    String description = '',
    bool isPrivate = true,
  }) async {
    final result = await _client.rpc(
      'create_group',
      params: {
        'p_name': name,
        'p_description': description,
        'p_private': isPrivate,
      },
    );
    return result as String;
  }

  Future<void> joinGroup(String groupId) =>
      _client.rpc('join_group', params: {'p_group': groupId});

  Future<void> leaveGroup(String groupId) =>
      _client.rpc('leave_group', params: {'p_group': groupId});

  Future<List<ChallengeSummary>> groupChallenges(String groupId) async {
    final result = await _client.rpc(
      'group_challenges',
      params: {'p_group': groupId},
    );
    return _rows(result).map(ChallengeSummary.fromJson).toList();
  }

  Future<String> createChallenge({
    required String groupId,
    required String name,
    required String metric,
    required double target,
    required DateTime starts,
    required DateTime ends,
  }) async {
    final result = await _client.rpc(
      'create_challenge',
      params: {
        'p_group': groupId,
        'p_name': name,
        'p_metric': metric,
        'p_target': target,
        'p_starts': starts.toIso8601String().split('T').first,
        'p_ends': ends.toIso8601String().split('T').first,
      },
    );
    return result as String;
  }

  Future<void> joinChallenge(String challengeId) =>
      _client.rpc('join_challenge', params: {'p_challenge': challengeId});

  Future<void> setProgress(String challengeId, double progress) => _client.rpc(
    'set_challenge_progress',
    params: {'p_challenge': challengeId, 'p_progress': progress},
  );

  Future<List<LeaderboardEntry>> leaderboard(String challengeId) async {
    final result = await _client.rpc(
      'challenge_leaderboard',
      params: {'p_challenge': challengeId},
    );
    return _rows(result).map(LeaderboardEntry.fromJson).toList();
  }
}
