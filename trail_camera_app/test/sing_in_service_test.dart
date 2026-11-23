import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trail_camera_app/interfaces/interfaces.dart';
import 'package:trail_camera_app/models/models.dart';
import 'package:trail_camera_app/services/services.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('delegates sign in, current user and sign out to Google', () async {
    final google = FakeGoogleSignInService();
    final ISignInService service = SignInService(google);

    expect(service.currentUser, isNull);
    final user = await service.signIn(Provider.Google);
    expect(google.signIns, 1);
    expect(service.currentUser, same(user));
    expect(
      (await SharedPreferences.getInstance()).getBool('google_signed_in'),
      isTrue,
    );
    await service.signOut();
    expect(google.signOuts, 1);
    expect(service.currentUser, isNull);
    expect(
      (await SharedPreferences.getInstance()).getBool('google_signed_in'),
      isFalse,
    );
  });

  test('does not restore without a previous sign in', () async {
    final google = FakeGoogleSignInService();
    final service = SignInService(google);
    expect(await service.restoreSignIn(), isNull);
    expect(await service.restoreSignIn(), isNull);
    expect(google.restores, 0);
  });

  test('restores a previously signed in user once per app session', () async {
    SharedPreferences.setMockInitialValues({'google_signed_in': true});
    final google = FakeGoogleSignInService();
    google.restoredUser = User(
      id: 'restored',
      email: 'restored@example.com',
      name: 'Restored',
      provider: Provider.Google,
    );
    final service = SignInService(google);
    final results = await Future.wait([
      service.restoreSignIn(),
      service.restoreSignIn(),
    ]);
    expect(results, everyElement(same(google.restoredUser)));
    expect(service.currentUser, same(google.restoredUser));
    expect(await service.restoreSignIn(), same(google.restoredUser));
    expect(google.restores, 1);
  });

  test('a new session restores after sign in but not after sign out', () async {
    final google = FakeGoogleSignInService();
    final firstSession = SignInService(google);
    await firstSession.signIn(Provider.Google);
    google.restoredUser = google.user;
    final nextSession = SignInService(google);
    expect(await nextSession.restoreSignIn(), same(google.restoredUser));
    expect(google.restores, 1);
    await nextSession.signOut();
    expect(await nextSession.restoreSignIn(), isNull);
    expect(await SignInService(google).restoreSignIn(), isNull);
    expect(google.restores, 1);
  });

  test('clears stale sign-in state when restoration returns no user', () async {
    SharedPreferences.setMockInitialValues({'google_signed_in': true});
    final google = FakeGoogleSignInService();
    expect(await SignInService(google).restoreSignIn(), isNull);
    expect(
      (await SharedPreferences.getInstance()).getBool('google_signed_in'),
      isFalse,
    );
    expect(await SignInService(google).restoreSignIn(), isNull);
    expect(google.restores, 1);
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
    expect(
      (await SharedPreferences.getInstance()).getBool('google_signed_in'),
      isTrue,
    );
    await expectLater(
      service.signIn(Provider.Google),
      throwsA(isA<GoogleSignInException>()),
    );
    expect(await service.restoreSignIn(), same(user));
  });

  test(
    'reports restoration failure and preserves state for the next launch',
    () async {
      SharedPreferences.setMockInitialValues({'google_signed_in': true});
      final google = FakeGoogleSignInService()
        ..error = const GoogleSignInException('Google failure');
      final service = SignInService(google);
      await expectLater(
        service.restoreSignIn(),
        throwsA(isA<GoogleSignInException>()),
      );
      expect(
        (await SharedPreferences.getInstance()).getBool('google_signed_in'),
        isTrue,
      );
      await expectLater(
        SignInService(google).restoreSignIn(),
        throwsA(isA<GoogleSignInException>()),
      );
      expect(google.restores, 2);
    },
  );
}
