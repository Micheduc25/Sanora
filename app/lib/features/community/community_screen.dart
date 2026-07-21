import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/error/failures.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/bodi_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/models/community.dart';
import '../../l10n/app_localizations.dart';
import 'community_controller.dart';
import 'group_detail_screen.dart';

class CommunityScreen extends HookConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final tab = useState(0);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.communityTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  icon: const Icon(Icons.people_rounded),
                  label: Text(l.communityTabFriends),
                ),
                ButtonSegment(
                  value: 1,
                  icon: const Icon(Icons.groups_rounded),
                  label: Text(l.communityTabGroups),
                ),
              ],
              selected: {tab.value},
              onSelectionChanged: (s) => tab.value = s.first,
            ),
          ),
        ),
      ),
      body: tab.value == 0 ? const _FriendsTab() : const _GroupsTab(),
    );
  }
}

/// Shown when a community provider fails because the user is not signed in.
class _SignInGate extends StatelessWidget {
  const _SignInGate();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return EmptyState(
      icon: Icons.lock_outline_rounded,
      title: l.communitySignInTitle,
      message: l.communitySignInMessage,
      actionLabel: l.communitySignIn,
      onAction: () => context.push('/auth'),
    );
  }
}

Widget _whenCommunity<T>(
  AsyncValue<T> value, {
  required Widget Function(T) data,
}) {
  return value.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => e is AuthFailure
        ? const _SignInGate()
        : Center(child: Text(messageFor(e))),
    data: data,
  );
}

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final friends = ref.watch(friendsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-community-friends',
        onPressed: () => _showAddFriend(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(l.communityAddFriend),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(friendsProvider.future),
        child: _whenCommunity(
          friends,
          data: (list) {
            final incoming = list.where((f) => f.incoming).toList();
            final accepted = list
                .where((f) => f.status == FriendStatus.accepted)
                .toList();
            final outgoing = list
                .where((f) => f.status == FriendStatus.pending && !f.incoming)
                .toList();
            if (list.isEmpty) {
              return _ScrollableEmpty(
                icon: Icons.people_outline_rounded,
                title: l.communityNoFriendsTitle,
                message: l.communityNoFriendsMessage,
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                if (incoming.isNotEmpty) ...[
                  SectionHeader(l.communityRequests),
                  for (final f in incoming) _RequestRow(friend: f),
                ],
                if (accepted.isNotEmpty) ...[
                  SectionHeader(l.communityFriendsWithCount(accepted.length)),
                  for (final f in accepted) _FriendRow(friend: f),
                ],
                if (outgoing.isNotEmpty) ...[
                  SectionHeader(l.communityInvitedSection),
                  for (final f in outgoing)
                    _FriendRow(friend: f, pending: true),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddFriend(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddFriendSheet(),
    );
  }
}

class _RequestRow extends ConsumerWidget {
  const _RequestRow({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(communityControllerProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BodiCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _Avatar(name: friend.name),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friend.name ?? L.of(context).communitySomeone,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.check_rounded),
              onPressed: () => controller.respond(friend.userId, accept: true),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => controller.respond(friend.userId, accept: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRow extends ConsumerWidget {
  const _FriendRow({required this.friend, this.pending = false});

  final Friend friend;
  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BodiCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _Avatar(name: friend.name),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friend.name ?? l.communityBodiUser,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (pending)
              Text(l.communityInvited, style: theme.textTheme.labelMedium)
            else
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: ListTile(
                      leading: Icon(
                        Icons.person_remove_rounded,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(l.communityRemoveFriend),
                      onTap: () {
                        ref
                            .read(communityControllerProvider)
                            .removeFriend(friend.userId);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddFriendSheet extends HookConsumerWidget {
  const _AddFriendSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = useTextEditingController();
    final busy = useState(false);
    final theme = Theme.of(context);
    final l = L.of(context);

    Future<void> submit() async {
      final value = email.text.trim();
      if (value.isEmpty) return;
      busy.value = true;
      try {
        final code = await ref
            .read(communityControllerProvider)
            .requestFriend(value);
        if (!context.mounted) return;
        final message = switch (code) {
          'ok' => l.communityRequestSentTo(value),
          'not_found' => l.communityNoAccountForEmail,
          'self' => l.communityOwnEmail,
          'already_friends' => l.communityAlreadyFriends,
          _ => l.communityRequestSent,
        };
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } on Failure catch (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(f.message)));
        }
      } finally {
        busy.value = false;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.communityAddFriendTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l.communityAddFriendHelp, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: l.communityEmailHint,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy.value ? null : submit,
            child: busy.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(l.communitySendRequest),
          ),
        ],
      ),
    );
  }
}

class _GroupsTab extends ConsumerWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final mine = ref.watch(myGroupsProvider);
    final discover = ref.watch(discoverGroupsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-community-groups',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _CreateGroupSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.communityNewGroup),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.refresh(myGroupsProvider.future),
          ref.refresh(discoverGroupsProvider.future),
        ]),
        child: _whenCommunity(
          mine,
          data: (myGroups) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                if (myGroups.isEmpty)
                  _InlineEmpty(
                    icon: Icons.groups_outlined,
                    title: l.communityNoGroupsTitle,
                    message: l.communityNoGroupsMessage,
                  )
                else ...[
                  SectionHeader(l.communityYourGroups),
                  for (final g in myGroups) _GroupRow(group: g, joined: true),
                ],
                discover.maybeWhen(
                  data: (groups) => groups.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(l.communityDiscover),
                            for (final g in groups)
                              _GroupRow(group: g, joined: false),
                          ],
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GroupRow extends ConsumerWidget {
  const _GroupRow({required this.group, required this.joined});

  final CommunityGroup group;
  final bool joined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = L.of(context);
    final members = l.communityMemberCount(group.memberCount);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BodiCard(
        onTap: joined
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(group: group),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.groups_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: theme.textTheme.titleMedium),
                  Text(
                    group.description.isEmpty
                        ? members
                        : l.communityGroupSubtitle(members, group.description),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (joined)
              const Icon(Icons.chevron_right_rounded)
            else
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(communityControllerProvider).joinGroup(group.id),
                child: Text(l.communityJoin),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupSheet extends HookConsumerWidget {
  const _CreateGroupSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = useTextEditingController();
    final description = useTextEditingController();
    final isPrivate = useState(true);
    final busy = useState(false);
    final theme = Theme.of(context);
    final l = L.of(context);

    Future<void> submit() async {
      if (name.text.trim().isEmpty) return;
      busy.value = true;
      try {
        await ref
            .read(communityControllerProvider)
            .createGroup(
              name: name.text.trim(),
              description: description.text.trim(),
              isPrivate: isPrivate.value,
            );
        if (context.mounted) Navigator.pop(context);
      } on Failure catch (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(f.message)));
        }
      } finally {
        busy.value = false;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.communityNewGroup, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: l.communityGroupNameHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            decoration: InputDecoration(
              hintText: l.communityGroupDescriptionHint,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: isPrivate.value,
            onChanged: (v) => isPrivate.value = v,
            title: Text(l.communityPrivateGroup),
            subtitle: Text(
              isPrivate.value
                  ? l.communityPrivateGroupOn
                  : l.communityPrivateGroupOff,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy.value ? null : submit,
            child: Text(l.communityCreateGroup),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (name == null || name!.isEmpty)
        ? '?'
        : name![0].toUpperCase();
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.mint,
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.vitalDark,
        ),
      ),
    );
  }
}

class _ScrollableEmpty extends StatelessWidget {
  const _ScrollableEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyState(icon: icon, title: title, message: message),
        ),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: EmptyState(icon: icon, title: title, message: message),
    );
  }
}
