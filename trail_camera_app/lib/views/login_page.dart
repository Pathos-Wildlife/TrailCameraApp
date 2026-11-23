part of 'views.dart';

class LoginPage extends FmvvmStatefulWidget<LoginViewModel> {
  LoginPage(super.viewModel, {super.key});

  @override
  State<LoginPage> createState() => _LoginPageState(bindableBase);
}

class _LoginPageState extends FmvvmState<LoginPage, LoginViewModel> {
  _LoginPageState(LoginViewModel viewModel) : super(viewModel, true);

  @override
  void initState() {
    super.initState();
  }

  Widget _buildSponsorButton(
    String label,
    String logoPath,
    Color backgroundColor, {
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(logoPath, height: 20, width: 20, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget showSnackbar(String message) {
    if (message != "") {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      child:
      AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Background(
          path: 'assets/video/mainscreentestvideo.mp4',
          child: SafeArea(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/photos/PathosLogo.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Camera trap sponsorship program',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSponsorButton(
                          'Facebook',
                          'assets/photos/facebook-logo.png',
                          const Color(0xFF0165E1),
                          onPressed: () {},
                        ),
                        const SizedBox(height: 16),
                        _buildSponsorButton(
                          'Google',
                          'assets/photos/google-logo.png',
                          const Color(0xFFDB4437),
                          onPressed: () => {
                            bindableBase.signInInProgress
                                ? null
                                : bindableBase.signInWithGoogle.execute(),
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSponsorButton(
                          'Apple ID',
                          'assets/photos/apple-logo.png',
                          const Color(0xFF000000),
                          onPressed: () {},
                        ),
                        const SizedBox(height: 16),
                        _buildSponsorButton(
                          'Microsoft',
                          'assets/photos/microsoft-logo.png',
                          const Color(0xFF00A4EF),
                          onPressed: () {},
                        ),
                        BindingWidget<LoginViewModel>(
                           bindings: <Binding>[
                             Binding('signInError', bindableBase,
                                 LoginViewModel.snackbarMessageProperty)
                           ],
                           builder: (bc) => showSnackbar(BindingWidget.of<LoginViewModel>(bc)
                               .getGenericValue<String>('signInError')),
                         ),
                      ],
                    ),
                  ),
                ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class LoginViewModel extends ViewModel {
  LoginViewModel(this._navigationService, this.signInService);

  final ISignInService signInService;

  final NavigationService _navigationService;

  static PropertyInfo snackbarMessageProperty = PropertyInfo('snackbarMessage', String);
  String get snackbarMessage => getGenericValue<String>(snackbarMessageProperty);
  set _snackbarMessage(String value) => {
    setGenericValue<String>(snackbarMessageProperty, value),
  };

  static PropertyInfo signInInProgressProperty = PropertyInfo(
    'signInInProgress',
    bool,
  );
  bool get signInInProgress => getGenericValue<bool>(signInInProgressProperty);
  set _signInInProgress(bool value) => {
    setGenericValue<bool>(signInInProgressProperty, value),
  };

  Command? _signInWithGoogle;

  Command get signInWithGoogle {
    _signInWithGoogle ??= Command(() async {
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.iOS &&
              defaultTargetPlatform != TargetPlatform.android)) {
        _snackbarMessage = "Google sign-in is available only on iOS and Android.";
        return;
      }
      _signInInProgress = true;
      try {
        final user = await signInService.signIn(Provider.Google);
        
        _navigationService.navigateBack();
      } on Exception catch (error) {
        debugPrint('Google sign-in failed: ${error.runtimeType}');
        _snackbarMessage = "Google sign-in failed. Please try again.";
      } finally {
        _signInInProgress = false;
      }
    });
    return _signInWithGoogle as Command;
  }
}
