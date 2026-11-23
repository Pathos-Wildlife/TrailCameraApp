part of 'services.dart';

class GoogleSignInException implements Exception {
  const GoogleSignInException(this.message);

  final String message;
}

class GoogleSignInService extends BindableBase {
  GoogleSignInService({
    String? clientId,
    String? serverClientId,
    TargetPlatform? targetPlatform,
  }) : _clientId =
           clientId ??
           '974790949873-ej7so7ind0ohen5hcch6k235a4ptjgrh.apps.googleusercontent.com',
       _serverClientId =
           serverClientId ??
           "974790949873-jsj6tqdes8sns9fe22ddlchhr6aq5822.apps.googleusercontent.com",
       _targetPlatform = targetPlatform ?? defaultTargetPlatform;

  final String _clientId;
  final String _serverClientId;
  final TargetPlatform _targetPlatform;
  static final currentUserProperty = PropertyInfo('currentUser', User);

  User? get currentUser => getGenericValue<User?>(currentUserProperty);
  set _currentUser(User? value) =>
      setGenericValue<User?>(currentUserProperty, value);

  static Future<void>? _initialization;
  static const _configChannel = MethodChannel(
    'org.pathoswildlife.trail_camera_app/google_sign_in_config',
  );

  @visibleForTesting
  static void resetInitializationForTesting() => _initialization = null;

  Future<void> _initialize() async {
    switch (_targetPlatform) {
      case TargetPlatform.iOS:
        if (!_isClientId(_clientId)) {
          throw const GoogleSignInException(
            'Configure GOOGLE_IOS_CLIENT_ID before signing in. See the project README.',
          );
        }

        final expectedScheme = _clientId
            .split('.')
            .reversed
            .join('.')
            .toLowerCase();
        final schemes = await _configChannel.invokeListMethod<String>(
          'urlSchemes',
        );
        if (schemes == null ||
            !schemes.any((scheme) => scheme.toLowerCase() == expectedScheme)) {
          throw const GoogleSignInException(
            'The iOS URL scheme does not match GOOGLE_IOS_CLIENT_ID. See the project README.',
          );
        }
        break;
      case TargetPlatform.android:
        if (!_isClientId(_serverClientId)) {
          throw const GoogleSignInException(
            'Configure GOOGLE_SERVER_CLIENT_ID with your Web OAuth client ID before signing in. See the project README.',
          );
        }
        break;
      default:
        throw const GoogleSignInException(
          'Google sign-in is available only on iOS and Android.',
        );
    }

    try {
      final initialization = _initialization ??= google.GoogleSignIn.instance
          .initialize(
            clientId: _targetPlatform == TargetPlatform.iOS ? _clientId : null,
            serverClientId: _targetPlatform == TargetPlatform.android
                ? _serverClientId
                : null,
          );
      try {
        await initialization;
      } catch (_) {
        if (identical(_initialization, initialization)) _initialization = null;
        rethrow;
      }
    } on google.GoogleSignInException catch (error) {
      throw _translateError(error);
    }
  }

  Future<User?> restoreSignIn() async {
    await _initialize();
    try {
      final attempt = google.GoogleSignIn.instance
          .attemptLightweightAuthentication();
      final account = attempt == null ? null : await attempt;
      final user = account == null ? null : _toUser(account);
      _currentUser = user;
      return user;
    } on google.GoogleSignInException catch (error) {
      throw _translateError(error);
    }
  }

  Future<User> signIn() async {
    await _initialize();
    try {
      final user = _toUser(await google.GoogleSignIn.instance.authenticate());
      _currentUser = user;
      return user;
    } on google.GoogleSignInException catch (error) {
      throw _translateError(error);
    }
  }

  Future<void> signOut() async {
    await _initialize();
    try {
      await google.GoogleSignIn.instance.signOut();
      _currentUser = null;
    } on google.GoogleSignInException catch (error) {
      throw _translateError(error);
    }
  }

  User _toUser(google.GoogleSignInAccount account) => User(
    id: account.id,
    email: account.email,
    name: account.displayName ?? '',
    provider: Provider.Google,
  );

  GoogleSignInException _translateError(google.GoogleSignInException error) {
    if (error.code == google.GoogleSignInExceptionCode.canceled) {
      return const GoogleSignInException('Google sign-in was canceled.');
    }
    if (error.code ==
            google.GoogleSignInExceptionCode.clientConfigurationError ||
        error.code ==
            google.GoogleSignInExceptionCode.providerConfigurationError) {
      return const GoogleSignInException(
        'Google sign-in is not configured correctly. See the project README.',
      );
    }
    return GoogleSignInException(
      'Google sign-in failed (${error.code.name}). Please try again.',
    );
  }

  bool _isClientId(String clientId) => RegExp(
    r'^[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$',
  ).hasMatch(clientId);
}
