import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/main.dart';
import 'package:trail_camera_app/models/user.dart';
import 'package:trail_camera_app/services/google_sign_in_service.dart';
import 'package:trail_camera_app/views/about_us_page.dart';
import 'package:trail_camera_app/views/app_drawer.dart';
import 'package:trail_camera_app/views/camera_list_page.dart';
import 'package:trail_camera_app/views/contact_page.dart';
import 'package:trail_camera_app/views/cozumel_foxes_page.dart';
import 'package:trail_camera_app/views/donate_page.dart';
import 'package:trail_camera_app/views/leopard_seals_page.dart';
import 'package:trail_camera_app/views/map_page.dart';
import 'package:trail_camera_app/views/settings_page.dart';

class _SignedInService extends GoogleSignInService {
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
                MapViewModel(navigation, service),
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
