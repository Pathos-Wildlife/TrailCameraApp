part of 'services.dart';

class SignInService extends BindableBase implements ISignInService {
  SignInService(this._googleSignInService);

  final GoogleSignInService _googleSignInService;
  static const _signedInKey = 'google_signed_in';
  Future<User?>? _startupRestore;

  @override
  User? get currentUser =>
      getGenericValue<User?>(ISignInService.currentUserProperty);

  set _currentUser(User? value) {
    setGenericValue<User?>(ISignInService.currentUserProperty, value);
  }

  @override
  Future<User?> restoreSignIn() async {
    if (currentUser case final user?) return user;
    return _startupRestore ??= _restorePreviousSignIn();
  }

  Future<User?> _restorePreviousSignIn() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_signedInKey) != true) return null;
    final user = await _googleSignInService.restoreSignIn();
    if (user == null) {
      await _setSignedIn(preferences, false);
    }
    _currentUser = user;
    return user;
  }

  @override
  Future<User> signIn(Provider provider) async {
    switch (provider) {
      case Provider.google:
        var returnValue = await _googleSignInService.signIn();
        final preferences = await SharedPreferences.getInstance();
        await _setSignedIn(preferences, true);
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
      case Provider.google:
        final preferences = await SharedPreferences.getInstance();
        await _setSignedIn(preferences, false);
        try {
          await _googleSignInService.signOut();
        } catch (error, stackTrace) {
          try {
            await _setSignedIn(preferences, true);
          } catch (restoreError, restoreStack) {
            debugPrint(
              'Could not restore sign-in preference: $restoreError\n$restoreStack',
            );
          }
          Error.throwWithStackTrace(error, stackTrace);
        }
    }
    _currentUser = null;
    _startupRestore = Future<User?>.value(null);
  }

  Future<void> _setSignedIn(SharedPreferences preferences, bool value) async {
    if (!await preferences.setBool(_signedInKey, value)) {
      throw StateError('Could not save sign-in state.');
    }
  }
}
