import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/interfaces/interfaces.dart';
import 'package:trail_camera_app/main.dart';
import 'package:trail_camera_app/models/models.dart';
import 'package:trail_camera_app/services/services.dart';
import 'package:trail_camera_app/views/views.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _VideoPlayer extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => const Stream.empty();

  @override
  Future<void> dispose(int playerId) async {}
}

class _SignInService extends ISignInService {
  Completer<void>? signOutCompleter;
  int signOutCount = 0;

  void updateUser(User? value) {
    setGenericValue<User?>(ISignInService.currentUserProperty, value);
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    await signOutCompleter!.future;
    updateUser(null);
  }

  @override
  Future<User?> restoreSignIn() async {
    updateUser(_user);
    return _user;
  }

  @override
  Future<User> signIn(Provider provider) async {
    updateUser(_user);
    return _user;
  }

  @override
  User? get currentUser =>
      getGenericValue<User?>(ISignInService.currentUserProperty);
}

final _user = User(
  id: 'id',
  email: 'user@example.com',
  name: 'User',
  provider: Provider.Google,
);

void main() {
  testWidgets('logout waits, reports failures and opens login on success', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    VideoPlayerPlatform.instance = _VideoPlayer();
    final app = MyApp();
    final service = _SignInService();
    final navigation = Core.componentResolver.resolveType<NavigationService>()!;

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: 'MapView',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case 'MapView':
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => MapPage(
                  MapViewModel(navigation, service, DataService()),
                  tileLayer: const SizedBox.shrink(),
                ),
              );
            case 'SettingsView':
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) =>
                    SettingsPage(SettingsViewModel(navigation, service)),
              );
            case 'LoginView':
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => LoginPage(LoginViewModel(navigation, service)),
              );
            default:
              return app.getRoutes(settings);
          }
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('User'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    service.updateUser(
      User(
        id: 'other-id',
        email: 'other@example.com',
        name: 'Another User',
        provider: Provider.Google,
      ),
    );
    await tester.pump();
    expect(find.text('Another User'), findsOneWidget);
    expect(find.text('other@example.com'), findsOneWidget);
    expect(find.text('user@example.com'), findsNothing);

    service.signOutCompleter = Completer<void>();
    await tester.tap(find.text('Log out'));
    await tester.pump();
    expect(service.signOutCount, 1);
    expect(find.text('Signing out...'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Signing out...'),
          )
          .onPressed,
      isNull,
    );
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(SettingsPage), findsOneWidget);
    service.signOutCompleter!.completeError(Exception('Sign-out failed.'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not log out. Please try again. Exception: Sign-out failed.'),
      findsOneWidget,
    );
    expect(find.byType(SettingsPage), findsOneWidget);

    service.signOutCompleter = Completer<void>();
    await tester.tap(find.text('Log out'));
    await tester.pump();
    expect(
      find.text('Could not log out. Please try again. Exception: Sign-out failed.'),
      findsNothing,
    );
    service.signOutCompleter!.complete();
    await tester.pumpAndSettle();
    expect(service.signOutCount, 2);
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.text('Google'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
