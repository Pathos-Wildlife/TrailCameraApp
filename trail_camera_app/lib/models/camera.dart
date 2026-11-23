part of 'models.dart';

class Camera extends BindableBase {
  static final idProperty = PropertyInfo('id', int);
  static final cameraNameProperty = PropertyInfo('cameraName', String);
  static final latitudeProperty = PropertyInfo('latitude', double);
  static final longitudeProperty = PropertyInfo('longitude', double);

  int get id => getGenericValue<int>(idProperty);
  set id(int value) => setGenericValue<int>(idProperty, value);

  String get cameraName => getGenericValue<String>(cameraNameProperty);
  set cameraName(String value) =>
      setGenericValue<String>(cameraNameProperty, value);

  double get latitude => getGenericValue<double>(latitudeProperty);
  set latitude(double value) =>
      setGenericValue<double>(latitudeProperty, value);

  double get longitude => getGenericValue<double>(longitudeProperty);
  set longitude(double value) =>
      setGenericValue<double>(longitudeProperty, value);
}
