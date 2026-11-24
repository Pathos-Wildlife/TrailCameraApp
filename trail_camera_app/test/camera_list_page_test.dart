import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/main.dart';
import 'package:trail_camera_app/models/models.dart';
import 'package:trail_camera_app/services/services.dart';
import 'package:trail_camera_app/views/views.dart';

class _DataService extends DataService {
  final Completer<NotificationList<Camera>> result =
      Completer<NotificationList<Camera>>();

  @override
  Future<NotificationList<T>> getAll<T extends BindableBase>() async {
    if (T != Camera) throw UnsupportedError('Only cameras are supported');
    return await result.future as NotificationList<T>;
  }
}

class _NavigationService extends Fake implements NavigationService {
  Type? destination;
  Object? parameter;

  @override
  Future<void> navigate<V extends ViewModel>({Object? parameter}) async {
    destination = V;
    this.parameter = parameter;
  }
}

Camera _camera(String name, double latitude, double longitude) => Camera()
  ..cameraName = name
  ..latitude = latitude
  ..longitude = longitude;

void main() {
  setUpAll(() => MyApp());

  testWidgets('camera cards update when the bound list and cameras change', (
    tester,
  ) async {
    final navigation = Core.componentResolver.resolveType<NavigationService>()!;
    final data = _DataService();
    final model = CameraListViewModel(navigation, data);
    final otherModel = CameraListViewModel(navigation, data);
    expect(identical(model.cameras, otherModel.cameras), isFalse);
    model.init(null);
    await tester.pumpWidget(MaterialApp(home: CameraListPage(model)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final first = _camera('First camera', 20.39709, -87.000542);
    final second = _camera('Second camera', 20.390833, -86.995135);
    data.result.complete(NotificationList<Camera>.of([first, second]));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('First camera'), findsOneWidget);
    expect(find.text('Latitude: 20.39709'), findsOneWidget);
    expect(find.text('Longitude: -87.000542'), findsOneWidget);
    expect(find.text('Second camera'), findsOneWidget);

    second
      ..cameraName = 'Updated camera'
      ..latitude = 20.4
      ..longitude = -87.1;
    await tester.pump();
    expect(find.text('Updated camera'), findsOneWidget);
    expect(find.text('Latitude: 20.4'), findsOneWidget);
    expect(find.text('Longitude: -87.1'), findsOneWidget);

    model.cameras.remove(first);
    await tester.pump();
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('First camera'), findsNothing);
    second.cameraName = 'Still bound';
    await tester.pump();
    expect(find.text('Still bound'), findsOneWidget);

    model.cameras.remove(second);
    await tester.pump();
    expect(find.text('No cameras available.'), findsOneWidget);
    model.cameras.add(first);
    await tester.pump();
    expect(find.text('First camera'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    model.cameras.remove(first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an error when cameras cannot be loaded', (tester) async {
    final navigation = Core.componentResolver.resolveType<NavigationService>()!;
    final data = _DataService();
    final model = CameraListViewModel(navigation, data)..init(null);
    await tester.pumpWidget(MaterialApp(home: CameraListPage(model)));
    data.result.completeError(Exception('Data service failed'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load cameras.'), findsOneWidget);
    expect(find.text('No cameras available.'), findsNothing);
  });

  testWidgets('tapping a camera navigates to its map with its ID', (
    tester,
  ) async {
    final navigation = _NavigationService();
    final data = _DataService();
    final model = CameraListViewModel(navigation, data)..init(null);
    await tester.pumpWidget(MaterialApp(home: CameraListPage(model)));
    data.result.complete(
      NotificationList<Camera>.of([
        _camera('First camera', 20.39709, -87.000542)..id = 7,
        _camera('Second camera', 20.390833, -86.995135)..id = 12,
      ]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second camera'));
    await tester.pump();
    expect(navigation.destination, MapViewModel);
    expect(navigation.parameter, 12);
  });
}
