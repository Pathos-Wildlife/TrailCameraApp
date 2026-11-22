import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/models/user.dart';
import 'package:trail_camera_app/services/google_sign_in_service.dart';
import 'package:trail_camera_app/views/app_drawer.dart';
import 'package:trail_camera_app/views/login_page.dart';
import 'package:flutter/material.dart';

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
          GoogleSignInService.currentUserProperty,
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
  final GoogleSignInService signInService;

  AppDestination get destination => AppDestination.settings;

  static final signingOutProperty = PropertyInfo('signingOut', bool);
  static final signOutErrorProperty = PropertyInfo('signOutError', String);

  bool get signingOut => getGenericValue<bool>(signingOutProperty);
  set _signingOut(bool value) =>
      setGenericValue<bool>(signingOutProperty, value);

  set _signOutError(String value) =>
      setGenericValue<String>(signOutErrorProperty, value);

  Command? _signOut;
  Command get signOut => _signOut ??= Command(_signOutWithGoogle);

  Future<void> _signOutWithGoogle() async {
    if (signingOut) return;
    _signOutError = '';
    _signingOut = true;
    try {
      await signInService.signOut();
      await navigationService.navigate<LoginViewModel>();
    } on GoogleSignInException catch (error) {
      _signOutError = 'Could not log out: ${error.message}';
    } on Exception catch (error, stackTrace) {
      debugPrint('Google sign-out failed: $error\n$stackTrace');
      _signOutError = 'Could not log out. Please try again.';
    } finally {
      _signingOut = false;
    }
  }
}
