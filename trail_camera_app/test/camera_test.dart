import 'package:flutter_test/flutter_test.dart';
import 'package:trail_camera_app/models/models.dart';

void main() {
  test('camera properties have FMVVM defaults and notify when changed', () {
    final camera = Camera();
    final changes = <String>[];
    camera.addPropertyListener(changes.add);

    expect(camera.id, 0);
    expect(camera.cameraName, '');
    expect(camera.latitude, 0.0);
    expect(camera.longitude, 0.0);

    camera.id = 42;
    camera.cameraName = 'Trail camera';
    camera.latitude = 20.422;
    camera.longitude = -86.914;

    expect(camera.id, 42);
    expect(camera.cameraName, 'Trail camera');
    expect(camera.latitude, 20.422);
    expect(camera.longitude, -86.914);
    expect(changes, ['id', 'cameraName', 'latitude', 'longitude']);

    camera.id = 42;
    expect(changes, hasLength(4));
    camera.dispose();
  });
}
