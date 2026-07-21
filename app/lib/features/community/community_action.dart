import 'package:flutter/material.dart';

import '../../core/error/failures.dart';

/// Awaits a community mutation and says so when it fails.
///
/// Every one of these goes to the server, and the server can refuse — an
/// invite-only group, a finished challenge, a dropped connection. Called
/// without awaiting, the failure became an unhandled async error and the row
/// simply never changed.
Future<void> runCommunityAction(
  BuildContext context,
  Future<void> action,
) async {
  try {
    await action;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messageFor(e))));
    }
  }
}
