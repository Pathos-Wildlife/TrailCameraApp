import 'package:fmvvm/fmvvm.dart';

enum Provider {Google}

class User extends BindableBase {
  User({required this.id, required this.email, required this.name, required this.provider});

  final String id;
  final String email;
  final String name;
  final Provider provider;
}