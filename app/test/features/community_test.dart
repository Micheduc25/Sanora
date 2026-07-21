import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sanora/core/error/failures.dart';
import 'package:sanora/core/providers/app_providers.dart';
import 'package:sanora/core/theme/app_theme.dart';
import 'package:sanora/data/repositories/community_repository.dart';
import 'package:sanora/data/supabase_service.dart';
import 'package:sanora/domain/models/community.dart';
import 'package:sanora/features/community/community_controller.dart';
import 'package:sanora/features/community/community_screen.dart';
import 'package:sanora/l10n/app_localizations.dart';

/// Serves fixed lists; nothing here talks to Supabase.
class _FakeCommunityRepository extends CommunityRepository {
  _FakeCommunityRepository({
    this.friendList = const [],
    this.invites = const [],
    this.discoverable = const [],
  }) : super(SupabaseService());

  final List<Friend> friendList;
  final List<GroupInvite> invites;
  final List<CommunityGroup> discoverable;
  final List<String> accepted = [];
  final List<Map<String, String>> reports = [];
  final List<String> blocked = [];
  final List<String> joined = [];

  @override
  Future<List<Friend>> friends() async => friendList;

  @override
  Future<List<CommunityGroup>> myGroups() async => const [];

  @override
  Future<List<CommunityGroup>> discoverGroups() async => discoverable;

  @override
  Future<void> joinGroup(String groupId) async => joined.add(groupId);

  @override
  Future<List<GroupInvite>> myInvites() async => invites;

  @override
  Future<String> acceptInvite(String inviteId) async {
    accepted.add(inviteId);
    return 'group-1';
  }

  @override
  Future<void> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String note = '',
  }) async {
    reports.add({
      'type': targetType,
      'id': targetId,
      'reason': reason,
      'note': note,
    });
  }

  @override
  Future<void> blockUser(String userId) async => blocked.add(userId);
}

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: const [
      L.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: L.supportedLocales,
    home: const CommunityScreen(),
  ),
);

void main() {
  test('a signed-out call fails with AuthFailure, not a raw exception', () {
    final repository = CommunityRepository(SupabaseService());
    expect(repository.friends(), throwsA(isA<AuthFailure>()));
    expect(repository.myGroups(), throwsA(isA<AuthFailure>()));
    expect(repository.joinGroup('g'), throwsA(isA<AuthFailure>()));
    expect(repository.blockUser('u'), throwsA(isA<AuthFailure>()));
    expect(repository.myInvites(), throwsA(isA<AuthFailure>()));
    expect(repository.acceptInvite('i'), throwsA(isA<AuthFailure>()));
    expect(repository.inviteToGroup('g', 'a@b.c'), throwsA(isA<AuthFailure>()));
  });

  testWidgets('blocked friendships get their own section rather than a blank '
      'list', (tester) async {
    final container = ProviderContainer(
      overrides: [
        // Wall-clock polling and a widget test's fake async do not mix; the
        // refresh cadence is not what this test is about.
        communityTickProvider.overrideWith((ref) => const Stream<int>.empty()),
        communityRepositoryProvider.overrideWithValue(
          _FakeCommunityRepository(
            friendList: const [
              Friend(
                userId: 'blocked-user',
                name: 'Sam',
                status: FriendStatus.blocked,
              ),
            ],
          ),
        ),
      ],
    );
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Unblock'), findsOneWidget);

    // The community poller holds a periodic timer for as long as something is
    // watching, and the binding fails the test if one outlives the tree.
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('reporting a friend files a report and blocks them by '
      'default', (tester) async {
    final repository = _FakeCommunityRepository(
      friendList: const [
        Friend(
          userId: 'rude-user',
          name: 'Sam',
          status: FriendStatus.accepted,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        communityTickProvider.overrideWith((ref) => const Stream<int>.empty()),
        communityRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Harassment or bullying'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    expect(repository.reports, [
      {'type': 'user', 'id': 'rude-user', 'reason': 'harassment', 'note': ''},
    ]);
    // Reporting someone you can still see is half a remedy; the sheet offers
    // the block with it and it is on unless the reporter turns it off.
    expect(repository.blocked, ['rude-user']);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('an invite to a private group is offered even when the user is '
      'in no groups at all', (tester) async {
    final repository = _FakeCommunityRepository(
      invites: const [
        GroupInvite(
          id: 'invite-1',
          groupId: 'group-1',
          groupName: 'Family',
          invitedBy: 'Ama',
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        communityTickProvider.overrideWith((ref) => const Stream<int>.empty()),
        communityRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groups'));
    await tester.pumpAndSettle();

    // The empty state is the group list's, and must not hide the invitation.
    expect(find.text('Invitations'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Ama invited you'), findsOneWidget);
    expect(find.text('No groups yet'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(repository.accepted, ['invite-1']);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });

  testWidgets('a discoverable group lays out and can be joined', (tester) async {
    final repository = _FakeCommunityRepository(
      discoverable: const [
        CommunityGroup(
          id: 'group-2',
          name: 'Morning Walkers',
          description: 'Steps before sunrise',
          memberCount: 12,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        communityTickProvider.overrideWith((ref) => const Stream<int>.empty()),
        communityRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.pumpWidget(_app(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groups'));
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Morning Walkers'), findsOneWidget);

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(repository.joined, ['group-2']);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
