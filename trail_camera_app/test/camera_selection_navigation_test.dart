import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/interfaces/interfaces.dart';
import 'package:trail_camera_app/main.dart';
import 'package:trail_camera_app/models/models.dart';
import 'package:trail_camera_app/services/services.dart';
import 'package:trail_camera_app/views/views.dart';

final _mapCameras = Completer<NotificationList<Camera>>();

class _DataService extends DataService {
  int calls = 0;

  @override
  Future<NotificationList<T>> getAll<T extends BindableBase>() async {
    if (T != Camera) throw UnsupportedError('Only cameras are supported');
    final cameras = calls++ == 0
        ? NotificationList<Camera>.of([_camera()])
        : await _mapCameras.future;
    return cameras as NotificationList<T>;
  }
}

Camera _camera() => Camera()
  ..id = 42
  ..cameraName = 'Selected camera'
  ..latitude = 20.422
  ..longitude = -86.914;

class _SignInService extends ISignInService {
  int restores = 0;
  final user = User(
    id: 'id',
    name: 'User',
    email: 'user@example.com',
    provider: Provider.Google,
  );

  @override
  User? get currentUser => user;

  @override
  Future<User?> restoreSignIn() async {
    restores++;
    return user;
  }

  @override
  Future<User> signIn(Provider provider) async => user;

  @override
  Future<void> signOut() async {}
}

class _TestApp extends MyApp {
  static late _SignInService signIn;

  @override
  void registerComponents(ComponentResolver resolver) {
    final data = _DataService();
    signIn = _SignInService();
    final navigation = resolver.resolveType<NavigationService>()!;
    resolver.registerType<CameraListViewModel>(
      () => CameraListViewModel(navigation, data),
    );
    resolver.registerType<MapViewModel>(
      () => MapViewModel(navigation, signIn, data),
    );
  }
}

void main() {
  testWidgets('camera card opens map and selects matching loaded marker', (
    tester,
  ) async {
    final app = _TestApp();
    final navigation = Core.componentResolver.resolveType<NavigationService>()!;
    final listModel =
        navigation.createViewModel<CameraListViewModel>(null)
            as CameraListViewModel;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: 'CameraListView',
        onGenerateRoute: (settings) {
          if (settings.name == 'CameraListView') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => CameraListPage(listModel),
            );
          }
          if (settings.name == 'MapView') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => MapPage(
                settings.arguments as MapViewModel,
                tileLayer: const SizedBox.shrink(),
              ),
            );
          }
          return app.getRoutes(settings);
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selected camera'));
    await tester.pumpAndSettle();
    final map = tester.widget<MapPage>(find.byType(MapPage));
    expect(_TestApp.signIn.restores, 0);
    expect(map.bindableBase.selectedCameraId, 42);
    expect(find.text('Selected camera'), findsNothing);
    _mapCameras.complete(NotificationList<Camera>.of([_camera()]));
    await tester.pumpAndSettle();
    expect(find.text('Selected camera'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CameraListPage), findsOneWidget);
  });
}
