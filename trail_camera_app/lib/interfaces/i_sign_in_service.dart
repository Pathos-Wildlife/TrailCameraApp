part of 'interfaces.dart';

abstract class ISignInService extends BindableBase {
  static PropertyInfo currentUserProperty = PropertyInfo('currentUser', User);
  User? get currentUser;

  Future<User?> restoreSignIn();

  Future<User> signIn(Provider provider);

  Future<void> signOut();
}
