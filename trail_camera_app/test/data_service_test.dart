import 'package:flutter_test/flutter_test.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/interfaces/i_data_service.dart';
import 'package:trail_camera_app/models/camera.dart';
import 'package:trail_camera_app/models/user.dart';
import 'package:trail_camera_app/services/data_service.dart';

void main() {
  final IDataService service = DataService();

  test('getAll returns a new list with one camera each time', () async {
    final first = await service.getAll<Camera>();
    final second = await service.getAll<Camera>();

    expect(first, isA<NotificationList<Camera>>());
    expect(first, hasLength(1));
    expect(first.single, isA<Camera>());
    expect(second, hasLength(1));
    expect(identical(first, second), isFalse);
    expect(identical(first.single, second.single), isFalse);
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
