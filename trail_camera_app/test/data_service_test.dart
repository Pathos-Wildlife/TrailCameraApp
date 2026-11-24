import 'package:flutter_test/flutter_test.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/interfaces/interfaces.dart';
import 'package:trail_camera_app/models/models.dart';
import 'package:trail_camera_app/services/services.dart';

void main() {
  final IDataService service = DataService();

  test('getAll returns independent lists of cameras each time', () async {
    final first = await service.getAll<Camera>();
    final second = await service.getAll<Camera>();

    expect(first, isA<NotificationList<Camera>>());
    expect(first, hasLength(7));
    expect(second, hasLength(7));
    expect(
      first.map((camera) => camera.id),
      orderedEquals([1, 2, 3, 4, 5, 6, 7]),
    );
    expect(
      second.map((camera) => camera.id),
      orderedEquals([1, 2, 3, 4, 5, 6, 7]),
    );
    expect(identical(first, second), isFalse);
    for (var i = 0; i < first.length; i++) {
      expect(identical(first[i], second[i]), isFalse);
    }
  });

  test('getAll returns a new empty list for other types', () async {
    final first = await service.getAll<User>();
    final second = await service.getAll<User>();
    expect(first, isA<NotificationList<User>>());
    expect(first, isEmpty);
    expect(second, isEmpty);
    expect(identical(first, second), isFalse);
  });

  test('unimplemented operations fail explicitly', () async {
    await expectLater(service.get<Camera>(1), throwsUnimplementedError);
    await expectLater(service.delete<Camera>(1), throwsUnimplementedError);
    await expectLater(
      service.update<Camera>(Camera()),
      throwsUnimplementedError,
    );
    await expectLater(service.add<Camera>(Camera()), throwsUnimplementedError);
  });
}
