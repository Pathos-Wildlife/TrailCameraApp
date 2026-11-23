part of 'views.dart';

class SettingsPage extends FmvvmStatefulWidget<SettingsViewModel> {
  SettingsPage(super.viewModel, {super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState(bindableBase);
}

class _SettingsPageState extends FmvvmState<SettingsPage, SettingsViewModel> {
  _SettingsPageState(SettingsViewModel viewModel) : super(viewModel, true);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final destination = bindableBase.destination;
    return BindingWidget<SettingsViewModel>(
      bindings: [
        Binding(
          'signingOut',
          bindableBase,
          SettingsViewModel.signingOutProperty,
        ),
        Binding(
          'signOutError',
          bindableBase,
          SettingsViewModel.signOutErrorProperty,
        ),
        Binding(
          'currentUser',
          bindableBase.signInService,
          ISignInService.currentUserProperty,
        ),
      ],
      builder: (context) {
        final binding = BindingWidget.of<SettingsViewModel>(context);
        final signingOut = binding.getGenericValue<bool>('signingOut');
        final error = binding.getGenericValue<String>('signOutError');
        final user = binding.getGenericValue<User?>('currentUser');
        return PopScope(
          canPop: !signingOut,
          child: Scaffold(
            appBar: AppBar(title: Text(destination.title)),
            drawer: signingOut
                ? null
                : AppDrawer(
                    currentDestination: destination,
                    navigationService: bindableBase.navigationService,
                  ),
            body: user == null
                ? const Center(child: Text('No user is signed in.'))
                : ListView(
                    children: [
                      ListTile(
                        title: const Text('Name'),
                        subtitle: Text(user.name),
                      ),
                      ListTile(
                        title: const Text('Email'),
                        subtitle: Text(user.email),
                      ),
                      ListTile(
                        title: const Text('Provider'),
                        subtitle: Text(user.provider.name),
                      ),
                    ],
                  ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: signingOut
                          ? null
                          : bindableBase.signOut.execute,
                      child: Text(signingOut ? 'Signing out...' : 'Log out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SettingsViewModel extends ViewModel {
  SettingsViewModel(this.navigationService, this.signInService);

  final NavigationService navigationService;
  final ISignInService signInService;

  AppDestination get destination => AppDestination.settings;

  static final signingOutProperty = PropertyInfo('signingOut', bool);
  static final signOutErrorProperty = PropertyInfo('signOutError', String);

  bool get signingOut => getGenericValue<bool>(signingOutProperty);
  set _signingOut(bool value) =>
      setGenericValue<bool>(signingOutProperty, value);

  set _signOutError(String value) =>
      setGenericValue<String>(signOutErrorProperty, value);

  Command? _signOut;
  Command get signOut => _signOut ??= Command(_doSignOut);

  Future<void> _doSignOut() async {
    if (signingOut) return;
    _signOutError = '';
    _signingOut = true;
    try {
      await signInService.signOut();
      await navigationService.navigate<LoginViewModel>();
    } on Exception catch (error, stackTrace) {
      debugPrint('Sign-out failed: $error\n$stackTrace');
      _signOutError = 'Could not log out. Please try again. $error';
    } finally {
      _signingOut = false;
    }
  }
}
