/// Domain-level failures surfaced to the UI. [AiService] and
/// [CommunityRepository] translate transport exceptions into these; the
/// offline-first repositories write to Hive and cannot meaningfully fail, so
/// they do not.
///
/// Every [message] is user-facing copy. Screens should render `failure.message`
/// and never a raw exception — use [messageFor] for the mixed case.
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Safe display text for anything caught in a UI error branch. Raw exceptions
/// leak stack detail and mean nothing to the person reading them.
String messageFor(Object error) => error is Failure
    ? error.message
    : 'Something went wrong. Please try again.';

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'No connection. Changes are saved on your device and will sync automatically.',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sign-in failed. Please try again.']);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on our side. Please try again.',
  ]);
}

class AiUnavailableFailure extends Failure {
  const AiUnavailableFailure([
    super.message =
        'AI features need a connection. Your data is safe on your device.',
  ]);
}

/// The request never left the device because there is no session. A subtype of
/// [AiUnavailableFailure] so the offline fallbacks — the bundled food database,
/// the curated workout templates — still catch it; screens that can do better
/// than a fallback check for this type first and offer sign-in, because
/// "check your connection" is wrong advice when the fix is one tap away.
class SignInRequiredFailure extends AiUnavailableFailure {
  const SignInRequiredFailure([
    super.message = 'Sign in to use AI features. Your data stays on this '
        'device either way.',
  ]);
}

/// The server accepted the request and refused it on allowance grounds. Kept
/// separate from [AiUnavailableFailure] so the UI can offer an upgrade rather
/// than blaming the connection.
class QuotaFailure extends Failure {
  const QuotaFailure([
    super.message =
        'You have used today\'s free AI calls. They reset tomorrow.',
  ]);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not save to this device.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
