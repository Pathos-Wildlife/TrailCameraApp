import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/main.dart';
import 'package:trail_camera_app/models/models.dart';
import 'package:trail_camera_app/services/services.dart';
import 'package:trail_camera_app/views/views.dart';
import 'package:trail_camera_app/interfaces/interfaces.dart';

class _SignedInService extends ISignInService {
  int restoreCount = 0;

  @override
  Future<void> signOut() async {}

  @override
  Future<User?> restoreSignIn() async {
    restoreCount++;
    return User(
      id: 'id',
      email: 'user@example.com',
      name: 'User',
      provider: Provider.Google,
    );
  }

  @override
  User? get currentUser => null;

  @override
  Future<User> signIn(Provider provider) {
    // TODO: implement signIn
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('drawer navigates between every page and returns to the map', (
    tester,
  ) async {
    final app = MyApp();
    final service = _SignedInService();
    final navigation = Core.componentResolver.resolveType<NavigationService>()!;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: 'MapView',
        onGenerateRoute: (settings) {
          if (settings.name == 'MapView') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => MapPage(
                MapViewModel(navigation, service, DataService()),
                tileLayer: const SizedBox.shrink(),
              ),
            );
          }
          return app.getRoutes(settings);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(service.restoreCount, 1);

    final pages = <(String, Type, AppDestination)>[
      ('Camera List', CameraListPage, AppDestination.cameraList),
      ('Cozumel Foxes', CozumelFoxesPage, AppDestination.cozumelFoxes),
      ('Leopard Seals', LeopardSealsPage, AppDestination.leopardSeals),
      ('Donate', DonatePage, AppDestination.donate),
      ('About US', AboutUsPage, AppDestination.aboutUs),
      ('Contact', ContactPage, AppDestination.contact),
      ('Settings', SettingsPage, AppDestination.settings),
    ];

    for (final (title, type, destination) in pages) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(find.byType(Divider), findsOneWidget);
      await tester.tap(find.text(title).last);
      await tester.pumpAndSettle();

      expect(find.byType(type), findsOneWidget);
      if (destination == AppDestination.settings) {
        expect(find.text('No user is signed in.'), findsOneWidget);
      } else if (destination == AppDestination.cameraList) {
        expect(find.text('CAM_02'), findsOneWidget);
        expect(find.text('CAM_03'), findsOneWidget);
      } else {
        expect(find.text('$title is not available yet.'), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AppDrawer>(find.byType(AppDrawer)).currentDestination,
        destination,
      );
      await tester.tap(find.text(title).last);
      await tester.pumpAndSettle();
      expect(find.byType(type), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Settings'))
          .selected,
      isTrue,
    );
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera Map').last);
    await tester.pumpAndSettle();
    expect(find.byType(MapPage), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
    expect(service.restoreCount, 1);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();
    expect(find.byType(ContactPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(MapPage), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Donate'));
    await tester.pumpAndSettle();
    expect(find.byType(DonatePage), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DonatePage), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera List'));
    await tester.pumpAndSettle();
    expect(find.byType(CameraListPage), findsOneWidget);
  });
}
