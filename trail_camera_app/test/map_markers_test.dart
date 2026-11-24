import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:latlong2/latlong.dart';
import 'package:trail_camera_app/interfaces/interfaces.dart';
import 'package:trail_camera_app/main.dart';
import 'package:trail_camera_app/models/models.dart';
import 'package:trail_camera_app/services/services.dart';
import 'package:trail_camera_app/views/views.dart';

class _SignInService extends ISignInService {
  @override
  User? get currentUser => _user;

  final User _user = User(
    id: 'id',
    name: 'User',
    email: 'user@example.com',
    provider: Provider.google,
  );

  @override
  Future<User?> restoreSignIn() async => _user;

  @override
  Future<User> signIn(Provider provider) async => _user;

  @override
  Future<void> signOut() async {}
}

class _DataService extends DataService {
  final Completer<NotificationList<Camera>> result =
      Completer<NotificationList<Camera>>();

  @override
  Future<NotificationList<T>> getAll<T extends BindableBase>() async {
    if (T != Camera) throw UnsupportedError('Only cameras are supported');
    return await result.future as NotificationList<T>;
  }
}

Camera _camera(String name, double latitude, double longitude) => Camera()
  ..cameraName = name
  ..latitude = latitude
  ..longitude = longitude;

void main() {
  setUpAll(() => MyApp());

  testWidgets('camera pins follow the bound list and show the selected name', (
    tester,
  ) async {
    final navigation = Core.componentResolver.resolveType<NavigationService>()!;
    final data = _DataService();
    final viewModel = MapViewModel(navigation, _SignInService(), data);
    final otherViewModel = MapViewModel(navigation, _SignInService(), data);
    expect(identical(viewModel.cameras, otherViewModel.cameras), isFalse);
    viewModel.init(null);

    await tester.pumpWidget(
      MaterialApp(home: MapPage(viewModel, tileLayer: const SizedBox.shrink())),
    );
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
      isEmpty,
    );

    final first = _camera('North Camera', 20.422, -86.914)..id = 1;
    final second = _camera('South Camera', 20.382, -86.914)..id = 2;
    data.result.complete(NotificationList<Camera>.of([first, second]));
    await tester.pumpAndSettle();

    var markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;
    expect(markers.map((marker) => marker.point), [
      const LatLng(20.422, -86.914),
      const LatLng(20.382, -86.914),
    ]);
    await tester.tap(find.byTooltip('North Camera'));
    await tester.pump();
    expect(find.text('North Camera'), findsOneWidget);

    await tester.tap(find.byTooltip('South Camera'));
    await tester.pump();
    expect(find.text('South Camera'), findsOneWidget);
    expect(find.text('North Camera'), findsNothing);

    second
      ..cameraName = 'Updated Camera'
      ..latitude = 20.380;
    await tester.pump();
    markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;
    expect(markers.last.point, const LatLng(20.380, -86.914));
    expect(find.text('Updated Camera'), findsOneWidget);

    viewModel.cameras.remove(second);
    await tester.pump();
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
      hasLength(1),
    );
    expect(find.text('Updated Camera'), findsNothing);

    viewModel.cameras.add(second);
    await tester.pump();
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
      hasLength(2),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    viewModel.cameras.remove(first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects the camera passed to init after cameras load', (
    tester,
  ) async {
    final navigation = Core.componentResolver.resolveType<NavigationService>()!;
    final data = _DataService();
    final viewModel = MapViewModel(navigation, _SignInService(), data)..init(2);
    await tester.pumpWidget(
      MaterialApp(home: MapPage(viewModel, tileLayer: const SizedBox.shrink())),
    );
    expect(find.text('South Camera'), findsNothing);
    data.result.complete(
      NotificationList<Camera>.of([
        _camera('North Camera', 20.422, -86.914)..id = 1,
        _camera('South Camera', 20.382, -86.914)..id = 2,
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('South Camera'), findsOneWidget);
    expect(find.text('North Camera'), findsNothing);
    expect(viewModel.selectedCameraId, 2);

    await tester.tap(find.byTooltip('North Camera'));
    await tester.pump();
    expect(viewModel.selectedCameraId, 1);
    expect(find.text('North Camera'), findsOneWidget);
    expect(find.text('South Camera'), findsNothing);
  });

  testWidgets('does not select a camera for an unknown ID', (tester) async {
    final navigation = Core.componentResolver.resolveType<NavigationService>()!;
    final data = _DataService();
    final viewModel = MapViewModel(navigation, _SignInService(), data)
      ..init(99);
    await tester.pumpWidget(
      MaterialApp(home: MapPage(viewModel, tileLayer: const SizedBox.shrink())),
    );
    data.result.complete(
      NotificationList<Camera>.of([
        _camera('North Camera', 20.422, -86.914)..id = 1,
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('North Camera'), findsNothing);
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
      hasLength(1),
    );
  });
}
