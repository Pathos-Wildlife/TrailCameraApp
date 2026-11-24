part of 'services.dart';

class DataService implements IDataService {
  @override
  Future<NotificationList<T>> getAll<T extends BindableBase>() async {
    final items = NotificationList<T>();
    if (T == Camera) {
      var camera = Camera();
      camera.id = 1;
      camera.cameraName = "CAM_02";
      camera.longitude = -87.000542;
      camera.latitude = 20.397090;

      items.add(camera as T);

      camera = Camera();
      camera.id = 2;
      camera.cameraName = "CAM_03";
      camera.longitude = -86.995135;
      camera.latitude = 20.390833;

      items.add(camera as T);

      camera = Camera();
      camera.id = 3;
      camera.cameraName = "CAM_04";
      camera.longitude = -86.997803;
      camera.latitude = 20.367215;

      items.add(camera as T);

      camera = Camera();
      camera.id = 4;
      camera.cameraName = "CAM_05";
      camera.longitude = -86.972783;
      camera.latitude = 20.368288;

      items.add(camera as T);

      camera = Camera();
      camera.id = 5;
      camera.cameraName = "CAM_06";
      camera.longitude = -86.970362;
      camera.latitude = 20.366832;

      items.add(camera as T);

      camera = Camera();
      camera.id = 6;
      camera.cameraName = "CAM_07";
      camera.longitude = -86.971095;
      camera.latitude = 20.363498;

      items.add(camera as T);

      camera = Camera();
      camera.id = 7;
      camera.cameraName = "CAM_08";
      camera.longitude = -86.972263;
      camera.latitude = 20.360717;

      items.add(camera as T);

      camera = Camera();
      camera.id = 8;
      camera.cameraName = "CAM_09";
      camera.longitude = -86.973303;
      camera.latitude = 20.354697;
      
      items.add(camera as T);
    }
    return items;
  }

  @override
  Future<T> get<T extends BindableBase>(int id) async =>
      throw UnimplementedError('DataService.get is not implemented.');

  @override
  Future<void> delete<T extends BindableBase>(int id) async =>
      throw UnimplementedError('DataService.delete is not implemented.');

  @override
  Future<T> update<T extends BindableBase>(T target) async =>
      throw UnimplementedError('DataService.update is not implemented.');

  @override
  Future<T> add<T extends BindableBase>(T target) async =>
      throw UnimplementedError('DataService.add is not implemented.');
}
