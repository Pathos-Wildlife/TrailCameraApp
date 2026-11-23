import 'package:flutter_test/flutter_test.dart';
import 'package:trail_camera_app/interfaces/i_sign_in_service.dart';
import 'package:trail_camera_app/models/user.dart';
import 'package:trail_camera_app/services/google_sign_in_service.dart';
import 'package:trail_camera_app/services/sign_in_service.dart';

class FakeGoogleSignInService extends GoogleSignInService {
  User? user;
  User? restoredUser;
  Object? error;
  int restores = 0;
  int signIns = 0;
  int signOuts = 0;

  @override
  User? get currentUser => user;

  @override
  Future<User?> restoreSignIn() async {
    restores++;
    if (error case final failure?) throw failure;
    return user = restoredUser;
  }

  @override
  Future<User> signIn() async {
    signIns++;
    if (error case final failure?) throw failure;
    return user = User(
      id: 'id',
      email: 'user@example.com',
      name: 'User',
      provider: Provider.Google,
    );
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (error case final failure?) throw failure;
    user = null;
  }
}

void main() {
  test('delegates sign in, current user and sign out to Google', () async {
    final google = FakeGoogleSignInService();
    final ISignInService service = SignInService(google);

    expect(service.currentUser, isNull);
    final user = await service.signIn(Provider.Google);
    expect(google.signIns, 1);
    expect(service.currentUser, same(user));
    await service.signOut();
    expect(google.signOuts, 1);
    expect(service.currentUser, isNull);
  });

  test('attempts Google restoration when no user is signed in', () async {
    final google = FakeGoogleSignInService();
    final service = SignInService(google);
    expect(await service.restoreSignIn(), isNull);
    expect(google.restores, 1);

    google.restoredUser = User(
      id: 'restored',
      email: 'restored@example.com',
      name: 'Restored',
      provider: Provider.Google,
    );
    expect(await service.restoreSignIn(), same(google.restoredUser));
    expect(service.currentUser, same(google.restoredUser));
    expect(google.restores, 2);
  });

  test('reports sign out without a current user', () async {
    final google = FakeGoogleSignInService();
    final service = SignInService(google);
    await expectLater(service.signOut(), throwsStateError);
    expect(google.signOuts, 0);
  });

  test('propagates Google failures without changing the user', () async {
    final google = FakeGoogleSignInService();
    final service = SignInService(google);
    final user = await service.signIn(Provider.Google);
    google.error = const GoogleSignInException('Google failure');
    await expectLater(service.signOut(), throwsA(isA<GoogleSignInException>()));
    expect(service.currentUser, same(user));
    await expectLater(
      service.signIn(Provider.Google),
      throwsA(isA<GoogleSignInException>()),
    );
    await expectLater(
      service.restoreSignIn(),
      throwsA(isA<GoogleSignInException>()),
    );
  });
}
