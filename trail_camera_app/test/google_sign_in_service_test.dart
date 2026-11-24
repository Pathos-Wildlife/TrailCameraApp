import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    as platform;
import 'package:trail_camera_app/models/models.dart';
import 'package:trail_camera_app/services/services.dart';

class FakeGoogleSignIn extends platform.GoogleSignInPlatform {
  int initializationCount = 0;
  int authenticationCount = 0;
  int signOutCount = 0;
  String? clientId;
  String? serverClientId;
  platform.GoogleSignInException? authenticationError;
  platform.AuthenticationResults? restoredAccount;
  platform.GoogleSignInException? restorationError;
  platform.GoogleSignInException? signOutError;

  @override
  Future<void> signOut(platform.SignOutParams params) async {
    signOutCount++;
    if (signOutError case final error?) throw error;
  }

  @override
  Future<platform.AuthenticationResults?> attemptLightweightAuthentication(
    platform.AttemptLightweightAuthenticationParameters params,
  ) async {
    if (restorationError case final error?) throw error;
    return restoredAccount;
  }

  @override
  Future<void> init(platform.InitParameters params) async {
    initializationCount++;
    clientId = params.clientId;
    serverClientId = params.serverClientId;
  }

  @override
  Future<platform.AuthenticationResults> authenticate(
    platform.AuthenticateParameters params,
  ) async {
    authenticationCount++;
    if (authenticationError case final error?) throw error;
    return const platform.AuthenticationResults(
      user: platform.GoogleSignInUserData(
        id: 'google-user-id',
        email: 'user@example.com',
        displayName: 'Example User',
      ),
      authenticationTokens: platform.AuthenticationTokenData(idToken: null),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(
    'org.pathoswildlife.trail_camera_app/google_sign_in_config',
  );

  setUp(GoogleSignInService.resetInitializationForTesting);

  test('uses the configured iOS client ID by default', () async {
    const clientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    final fake = FakeGoogleSignIn();
    platform.GoogleSignInPlatform.instance = fake;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => [clientId.split('.').reversed.join('.')],
        );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final signIn = GoogleSignInService(
      targetPlatform: TargetPlatform.iOS,
    ).signIn();
    if (clientId.isEmpty) {
      await expectLater(
        signIn,
        throwsA(
          isA<GoogleSignInException>().having(
            (error) => error.message,
            'message',
            contains('GOOGLE_IOS_CLIENT_ID'),
          ),
        ),
      );
      expect(fake.initializationCount, 0);
    } else {
      await signIn;
      expect(fake.clientId, clientId);
    }
  });

  test('uses the configured Android client ID by default', () async {
    const clientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    final fake = FakeGoogleSignIn();
    platform.GoogleSignInPlatform.instance = fake;
    final signIn = GoogleSignInService(
      targetPlatform: TargetPlatform.android,
    ).signIn();
    if (clientId.isEmpty) {
      await expectLater(
        signIn,
        throwsA(
          isA<GoogleSignInException>().having(
            (error) => error.message,
            'message',
            contains('GOOGLE_SERVER_CLIENT_ID'),
          ),
        ),
      );
      expect(fake.initializationCount, 0);
    } else {
      await signIn;
      expect(fake.serverClientId, clientId);
    }
  });

  test('reports a missing client ID before calling the plugin', () async {
    final fake = FakeGoogleSignIn();
    platform.GoogleSignInPlatform.instance = fake;
    await expectLater(
      GoogleSignInService(
        clientId: '',
        targetPlatform: TargetPlatform.iOS,
      ).signIn(),
      throwsA(
        isA<GoogleSignInException>().having(
          (error) => error.message,
          'message',
          contains('GOOGLE_IOS_CLIENT_ID'),
        ),
      ),
    );
    expect(fake.initializationCount, 0);
  });

  test('reports a mismatched URL scheme before calling the plugin', () async {
    final fake = FakeGoogleSignIn();
    platform.GoogleSignInPlatform.instance = fake;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => ['wrong.scheme']);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await expectLater(
      GoogleSignInService(
        clientId: '123-example.apps.googleusercontent.com',
        targetPlatform: TargetPlatform.iOS,
      ).signIn(),
      throwsA(
        isA<GoogleSignInException>().having(
          (error) => error.message,
          'message',
          contains('URL scheme'),
        ),
      ),
    );
    expect(fake.initializationCount, 0);
  });

  test('initializes the plugin once and handles success and errors', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => ['com.googleusercontent.apps.123-example'],
        );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final fake = FakeGoogleSignIn();
    platform.GoogleSignInPlatform.instance = fake;
    final service = GoogleSignInService(
      clientId: '123-example.apps.googleusercontent.com',
      targetPlatform: TargetPlatform.iOS,
    );

    final user = await service.signIn();
    expect(service.currentUser, same(user));
    expect(fake.clientId, '123-example.apps.googleusercontent.com');
    expect(fake.serverClientId, isNull);
    expect(user.id, 'google-user-id');
    expect(user.email, 'user@example.com');
    expect(user.name, 'Example User');
    expect(user.provider, Provider.google);

    fake.authenticationError = const platform.GoogleSignInException(
      code: platform.GoogleSignInExceptionCode.canceled,
    );
    await expectLater(
      service.signIn(),
      throwsA(
        isA<GoogleSignInException>().having(
          (error) => error.message,
          'message',
          contains('canceled'),
        ),
      ),
    );

    fake.authenticationError = const platform.GoogleSignInException(
      code: platform.GoogleSignInExceptionCode.clientConfigurationError,
    );
    await expectLater(
      service.signIn(),
      throwsA(
        isA<GoogleSignInException>().having(
          (error) => error.message,
          'message',
          contains('not configured correctly'),
        ),
      ),
    );
    expect(fake.initializationCount, 1);
    expect(fake.authenticationCount, 3);
  });

  test(
    'uses the Web client ID for Android without checking iOS URL schemes',
    () async {
      var configChannelCallCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            configChannelCallCount++;
            return <String>[];
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final fake = FakeGoogleSignIn();
      platform.GoogleSignInPlatform.instance = fake;
      final user = await GoogleSignInService(
        serverClientId: '123-web.apps.googleusercontent.com',
        targetPlatform: TargetPlatform.android,
      ).signIn();

      expect(fake.clientId, isNull);
      expect(fake.serverClientId, '123-web.apps.googleusercontent.com');
      expect(configChannelCallCount, 0);
      expect(user.email, 'user@example.com');
    },
  );

  test(
    'reports a missing Android Web client ID before calling the plugin',
    () async {
      final fake = FakeGoogleSignIn();
      platform.GoogleSignInPlatform.instance = fake;

      await expectLater(
        GoogleSignInService(
          serverClientId: '',
          targetPlatform: TargetPlatform.android,
        ).signIn(),
        throwsA(
          isA<GoogleSignInException>().having(
            (error) => error.message,
            'message',
            contains('GOOGLE_SERVER_CLIENT_ID'),
          ),
        ),
      );
      expect(fake.initializationCount, 0);
    },
  );

  test(
    'restores an existing Android credential or returns signed out',
    () async {
      final fake = FakeGoogleSignIn();
      platform.GoogleSignInPlatform.instance = fake;
      final service = GoogleSignInService(
        serverClientId: '123-web.apps.googleusercontent.com',
        targetPlatform: TargetPlatform.android,
      );

      expect(await service.restoreSignIn(), isNull);
      expect(service.currentUser, isNull);
      fake.restoredAccount = const platform.AuthenticationResults(
        user: platform.GoogleSignInUserData(
          id: 'restored-id',
          email: 'restored@example.com',
          displayName: 'Restored User',
        ),
        authenticationTokens: platform.AuthenticationTokenData(
          idToken: 'token',
        ),
      );
      final user = await service.restoreSignIn();
      expect(service.currentUser, same(user));
      expect(user?.id, 'restored-id');
      expect(user?.email, 'restored@example.com');
      expect(user?.provider, Provider.google);
      fake.restoredAccount = null;
      expect(await service.restoreSignIn(), isNull);
      expect(service.currentUser, isNull);
      expect(fake.initializationCount, 1);
      expect(fake.authenticationCount, 0);
    },
  );

  test('reports restoration configuration errors', () async {
    final fake = FakeGoogleSignIn()
      ..restorationError = const platform.GoogleSignInException(
        code: platform.GoogleSignInExceptionCode.clientConfigurationError,
      );
    platform.GoogleSignInPlatform.instance = fake;

    await expectLater(
      GoogleSignInService(
        serverClientId: '123-web.apps.googleusercontent.com',
        targetPlatform: TargetPlatform.android,
      ).restoreSignIn(),
      throwsA(
        isA<GoogleSignInException>().having(
          (error) => error.message,
          'message',
          contains('not configured correctly'),
        ),
      ),
    );
  });

  test('clears current user only after successful sign out', () async {
    final fake = FakeGoogleSignIn();
    platform.GoogleSignInPlatform.instance = fake;
    final service = GoogleSignInService(
      serverClientId: '123-web.apps.googleusercontent.com',
      targetPlatform: TargetPlatform.android,
    );
    final changes = <String>[];
    service.addPropertyListener(changes.add);
    final user = await service.signIn();
    expect(service.currentUser, same(user));
    fake.signOutError = const platform.GoogleSignInException(
      code: platform.GoogleSignInExceptionCode.clientConfigurationError,
    );
    await expectLater(service.signOut(), throwsA(isA<GoogleSignInException>()));
    expect(service.currentUser, same(user));
    fake.signOutError = null;
    await service.signOut();
    expect(service.currentUser, isNull);
    expect(fake.signOutCount, 2);
    expect(changes, ['currentUser', 'currentUser']);
  });
}
