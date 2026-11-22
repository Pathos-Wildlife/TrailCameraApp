import 'package:flutter/material.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/views/about_us_page.dart';
import 'package:trail_camera_app/views/camera_list_page.dart';
import 'package:trail_camera_app/views/contact_page.dart';
import 'package:trail_camera_app/views/cozumel_foxes_page.dart';
import 'package:trail_camera_app/views/donate_page.dart';
import 'package:trail_camera_app/views/leopard_seals_page.dart';
import 'package:trail_camera_app/views/map_page.dart';
import 'package:trail_camera_app/views/settings_page.dart';

enum AppDestination {
  cameraMap('Camera Map', Icons.map_outlined),
  cameraList('Camera List', Icons.list),
  cozumelFoxes('Cozumel Foxes', Icons.pets_outlined),
  leopardSeals('Leopard Seals', Icons.water_outlined),
  donate('Donate', Icons.volunteer_activism_outlined),
  aboutUs('About US', Icons.info_outline),
  contact('Contact', Icons.mail_outline),
  settings('Settings', Icons.settings_outlined);

  const AppDestination(this.title, this.icon);

  final String title;
  final IconData icon;
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentDestination,
    required this.navigationService,
    this.onDestinationSelected,
  });

  final AppDestination currentDestination;
  final NavigationService navigationService;
  final ValueChanged<AppDestination>? onDestinationSelected;

  void _selectDestination(BuildContext context, AppDestination destination) {
    Scaffold.of(context).closeDrawer();
    if (destination == currentDestination) return;

    final onSelected = onDestinationSelected;
    if (onSelected != null) {
      onSelected(destination);
      return;
    }

    switch (destination) {
      case AppDestination.cameraMap:
        var foundMap = false;
        Navigator.of(context).popUntil((route) {
          foundMap = route.settings.name == 'MapView';
          return foundMap || route.isFirst;
        });
        if (!foundMap) navigationService.navigate<MapViewModel>();
      case AppDestination.cameraList:
        navigationService.navigate<CameraListViewModel>();
      case AppDestination.cozumelFoxes:
        navigationService.navigate<CozumelFoxesViewModel>();
      case AppDestination.leopardSeals:
        navigationService.navigate<LeopardSealsViewModel>();
      case AppDestination.donate:
        navigationService.navigate<DonateViewModel>();
      case AppDestination.aboutUs:
        navigationService.navigate<AboutUsViewModel>();
      case AppDestination.contact:
        navigationService.navigate<ContactViewModel>();
      case AppDestination.settings:
        navigationService.navigate<SettingsViewModel>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            for (final destination in AppDestination.values) ...[
              if (destination == AppDestination.settings) const Divider(),
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.title),
                selected: destination == currentDestination,
                onTap: () => _selectDestination(context, destination),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
