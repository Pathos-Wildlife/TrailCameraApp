part of 'services.dart';

class SignInService extends BindableBase implements ISignInService {
  SignInService(this._googleSignInService);

  final GoogleSignInService _googleSignInService;
  
  @override
  User? get currentUser => getGenericValue<User?>(ISignInService.currentUserProperty);
  
  set _currentUser(User? value) {
    setGenericValue<User?>(ISignInService.currentUserProperty, value);
  }


  @override
  Future<User?> restoreSignIn() async {
    var returnValue = await _googleSignInService.restoreSignIn();
    _currentUser = returnValue;
    return returnValue;
  }

  @override
  Future<User> signIn(Provider provider) async {
    switch (provider) {
      case Provider.Google:
        var returnValue =  await _googleSignInService.signIn();
        _currentUser = returnValue;
        return returnValue;
    }
  }

  @override
  Future<void> signOut() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Cannot sign out: no user is signed in.');
    }
    switch (user.provider) {
      case Provider.Google:
        await _googleSignInService.signOut();
    }
    _currentUser = null;
  }
}
