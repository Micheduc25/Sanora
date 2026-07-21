import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/error/failures.dart';
import '../../l10n/app_localizations.dart';
import 'community_controller.dart';

/// What can be reported. The strings are the `target_type` values the
/// `report_content` RPC checks, so they are not free text.
enum ReportTarget {
  group('group'),
  challenge('challenge'),
  user('user');

  const ReportTarget(this.value);

  final String value;
}

/// Opens the report sheet for one piece of user-generated content.
///
/// [label] is what the reader sees named in the sheet — a group name, a
/// challenge name, a display name — so it is clear what is being reported
/// when the same sheet is reached from a leaderboard row and a group header.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
  required String label,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) =>
      _ReportSheet(target: target, targetId: targetId, label: label),
);

class _ReportSheet extends HookConsumerWidget {
  const _ReportSheet({
    required this.target,
    required this.targetId,
    required this.label,
  });

  final ReportTarget target;
  final String targetId;
  final String label;

  /// The `reason` values the table's check constraint allows.
  static const _reasons = ['spam', 'harassment', 'hate', 'sexual', 'other'];

  static String _reasonLabel(BuildContext context, String reason) {
    final l = L.of(context);
    return switch (reason) {
      'spam' => l.communityReasonSpam,
      'harassment' => l.communityReasonHarassment,
      'hate' => l.communityReasonHate,
      'sexual' => l.communityReasonSexual,
      _ => l.communityReasonOther,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = useState(_reasons.first);
    final note = useTextEditingController();
    // Reporting a stranger off a leaderboard is the one case where there is
    // no other way to stop seeing them, so the block lives in this sheet.
    final alsoBlock = useState(target == ReportTarget.user);
    final busy = useState(false);
    final theme = Theme.of(context);
    final l = L.of(context);

    Future<void> submit() async {
      busy.value = true;
      try {
        final controller = ref.read(communityControllerProvider);
        await controller.report(
          targetType: target.value,
          targetId: targetId,
          reason: reason.value,
          note: note.text.trim(),
        );
        if (target == ReportTarget.user && alsoBlock.value) {
          await controller.blockUser(targetId);
        }
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.communityReportThanks)));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(messageFor(e))));
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
          Text(
            l.communityReportTitle(label),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(l.communityReportHelp, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(l.communityReportReason, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in _reasons)
                ChoiceChip(
                  label: Text(_reasonLabel(context, value)),
                  selected: reason.value == value,
                  showCheckmark: false,
                  onSelected: (_) => reason.value = value,
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: note,
            maxLines: 3,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.communityReportNoteHint),
          ),
          if (target == ReportTarget.user)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: alsoBlock.value,
              onChanged: (v) => alsoBlock.value = v ?? false,
              title: Text(l.communityReportAlsoBlock),
              subtitle: Text(
                l.communityBlockHelp,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
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
                : Text(l.communityReportSubmit),
          ),
        ],
      ),
    );
  }
}
