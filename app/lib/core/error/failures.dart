/// Domain-level failures surfaced to the UI. Repositories catch transport
/// and storage exceptions and translate them into one of these.
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No connection. Changes are saved on your device and will sync automatically.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sign-in failed. Please try again.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on our side. Please try again.']);
}

class AiUnavailableFailure extends Failure {
  const AiUnavailableFailure([super.message = 'AI features need a connection. Your data is safe on your device.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not save to this device.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
