import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trail_camera_app/main.dart';
import 'package:trail_camera_app/services/google_sign_in_service.dart';
import 'package:trail_camera_app/views/login.dart';
import 'package:trail_camera_app/views/main.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlayer extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => const Stream.empty();

  @override
  Future<void> dispose(int playerId) async {}
}

class FakeSignInService extends GoogleSignInService {
  FakeSignInService({this.restoredUser, this.restoreError});

  final GoogleUser? restoredUser;
  final GoogleSignInException? restoreError;

  @override
  Future<GoogleUser?> restoreSignIn() async {
    if (restoreError case final error?) throw error;
    return restoredUser;
  }

  @override
  Future<GoogleUser> signIn() async =>
      const GoogleUser(id: 'id', email: 'user@example.com', name: 'User');
}

void main() {
  setUp(() => VideoPlayerPlatform.instance = FakeVideoPlayer());
  const user = GoogleUser(id: 'id', email: 'user@example.com', name: 'User');
  const testMap = MainPage(tileLayer: SizedBox.shrink());

  testWidgets('restored user sees the map', (tester) async {
    await tester.pumpWidget(
      MyApp(
        googleSignInService: FakeSignInService(restoredUser: user),
        landingPage: testMap,
      ),
    );
    await tester.pump();
    expect(find.text('Camera Map'), findsOneWidget);
    expect(find.byType(Login), findsNothing);
  });

  testWidgets('signed out user sees login and enters map on sign-in', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      MyApp(googleSignInService: FakeSignInService(), landingPage: testMap),
    );
    await tester.pump();
    expect(find.byType(Login), findsOneWidget);
    await tester.tap(find.text('Google'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(MainPage), findsOneWidget);
    expect(find.byType(Login), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('restoration errors are shown on login', (tester) async {
    await tester.pumpWidget(
      MyApp(
        googleSignInService: FakeSignInService(
          restoreError: const GoogleSignInException('Configuration error'),
        ),
        landingPage: testMap,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(Login), findsOneWidget);
    expect(find.text('Configuration error'), findsOneWidget);
  });

  testWidgets('drawer lists destinations and displays unavailable message', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: testMap));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    for (final title in [
      'Camera Map',
      'Camera List',
      'Cozumel Foxes',
      'Leopard Seals',
      'Donate',
      'About US',
      'Contact',
      'Settings',
    ]) {
      expect(find.text(title), findsWidgets);
    }
    expect(find.byType(Divider), findsOneWidget);
    await tester.tap(find.text('Camera List'));
    await tester.pumpAndSettle();
    expect(find.text('Camera List is not available yet.'), findsOneWidget);
  });

  testWidgets('map constrains panning and zoom around Cozumel', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: testMap));
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final controller = map.mapController!;
    expect(controller.camera.center.latitude, closeTo(20.422, 0.001));
    expect(controller.camera.center.longitude, closeTo(-86.914, 0.001));
    expect(controller.camera.zoom, 11);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(controller.camera.zoom, 12);
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    expect(controller.camera.zoom, 11);

    controller.move(const LatLng(0, 0), 11);
    await tester.pump();
    expect(controller.camera.center.latitude, inInclusiveRange(20.18, 20.65));
    expect(
      controller.camera.center.longitude,
      inInclusiveRange(-87.10, -86.65),
    );
    controller.move(controller.camera.center, 2);
    await tester.pump();
    expect(controller.camera.zoom, greaterThanOrEqualTo(10));
    controller.move(controller.camera.center, 22);
    await tester.pump();
    expect(controller.camera.zoom, lessThanOrEqualTo(19));
  });
}
