import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:trail_camera_app/services/services.dart';
import 'package:trail_camera_app/views/views.dart';
import 'package:fmvvm/fmvvm.dart';

import 'package:trail_camera_app/interfaces/interfaces.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(MyApp());
}

class MyApp extends FmvvmApp {
  MyApp({super.key});

  @override
  void registerComponents(ComponentResolver componentResolver) {
    componentResolver.registerInstance<GoogleSignInService>(
      GoogleSignInService(),
    );
    componentResolver.registerInstance<ISignInService>(
      SignInService(componentResolver.resolveType<GoogleSignInService>()!),
    );
    componentResolver.registerInstance<IDataService>(DataService());
    componentResolver.registerType<LoginViewModel>(() {
      return LoginViewModel(
        componentResolver.resolveType<NavigationService>() as NavigationService,
        componentResolver.resolveType<ISignInService>() as ISignInService,
      );
    });
    componentResolver.registerType<MapViewModel>(() {
      return MapViewModel(
        componentResolver.resolveType<NavigationService>() as NavigationService,
        componentResolver.resolveType<ISignInService>() as ISignInService,
        componentResolver.resolveType<IDataService>()!,
      );
    });
    final navigation = componentResolver.resolveType<NavigationService>()!;
    componentResolver.registerType<CameraListViewModel>(
      () => CameraListViewModel(
        navigation,
        componentResolver.resolveType<IDataService>()!,
      ),
    );
    componentResolver.registerType<CozumelFoxesViewModel>(
      () => CozumelFoxesViewModel(navigation),
    );
    componentResolver.registerType<LeopardSealsViewModel>(
      () => LeopardSealsViewModel(navigation),
    );
    componentResolver.registerType<DonateViewModel>(
      () => DonateViewModel(navigation),
    );
    componentResolver.registerType<AboutUsViewModel>(
      () => AboutUsViewModel(navigation),
    );
    componentResolver.registerType<ContactViewModel>(
      () => ContactViewModel(navigation),
    );
    componentResolver.registerType<SettingsViewModel>(
      () => SettingsViewModel(
        navigation,
        componentResolver.resolveType<ISignInService>()!,
      ),
    );
  }

  @override
  String getInitialRoute() {
    return 'MapView';
  }

  @override
  String getTitle() {
    return 'Cozumel Foxes';
  }

  @override
  Route getRoutes(RouteSettings settings) {
    if (settings.name == 'MapView') {
      var arguments =
          settings.arguments ??
          Core.componentResolver
              .resolveType<NavigationService>()!
              .createViewModel<MapViewModel>(null);
      return buildRoute(settings, MapPage(arguments as MapViewModel));
    } else if (settings.name == 'LoginView') {
      return buildRoute<int>(
        settings,
        LoginPage(settings.arguments as LoginViewModel),
      );
    } else if (settings.name == 'CameraListView') {
      return buildRoute(
        settings,
        CameraListPage(settings.arguments as CameraListViewModel),
      );
    } else if (settings.name == 'CozumelFoxesView') {
      return buildRoute(
        settings,
        CozumelFoxesPage(settings.arguments as CozumelFoxesViewModel),
      );
    } else if (settings.name == 'LeopardSealsView') {
      return buildRoute(
        settings,
        LeopardSealsPage(settings.arguments as LeopardSealsViewModel),
      );
    } else if (settings.name == 'DonateView') {
      return buildRoute(
        settings,
        DonatePage(settings.arguments as DonateViewModel),
      );
    } else if (settings.name == 'AboutUsView') {
      return buildRoute(
        settings,
        AboutUsPage(settings.arguments as AboutUsViewModel),
      );
    } else if (settings.name == 'ContactView') {
      return buildRoute(
        settings,
        ContactPage(settings.arguments as ContactViewModel),
      );
    } else if (settings.name == 'SettingsView') {
      return buildRoute(
        settings,
        SettingsPage(settings.arguments as SettingsViewModel),
      );
    }
    throw Exception('No route defined for ${settings.name}');
  }
}
