part of 'interfaces.dart';

abstract class IDataService {
  Future<T> get<T extends BindableBase>(int id);

  Future<NotificationList<T>> getAll<T extends BindableBase>();

  Future<void> delete<T extends BindableBase>(int id);

  Future<T> update<T extends BindableBase>(T target);

  Future<T> add<T extends BindableBase>(T target);
}
