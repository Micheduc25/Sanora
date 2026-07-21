import 'package:sanora/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a missing session still reads as AI-unavailable to the fallbacks', () {
    // MealsController and WorkoutsScreen fall back to the bundled food
    // database and the curated templates on AiUnavailableFailure. Breaking
    // this subtype would leave a signed-out user with an error where the
    // offline path used to be.
    expect(const SignInRequiredFailure(), isA<AiUnavailableFailure>());
  });

  test('messageFor never leaks a raw exception', () {
    expect(messageFor(const SignInRequiredFailure()), contains('Sign in'));
    expect(messageFor(StateError('boom')), isNot(contains('boom')));
  });
}
