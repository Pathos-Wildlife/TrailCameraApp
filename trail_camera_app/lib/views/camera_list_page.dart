import 'package:flutter/widgets.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/views/app_drawer.dart';
import 'package:flutter/material.dart';

class CameraListPage extends FmvvmStatefulWidget<CameraListViewModel> {
  CameraListPage(super.viewModel, {super.key});

  @override
  State<CameraListPage> createState() => _CameraListPageState(bindableBase);
}

class _CameraListPageState extends FmvvmState<CameraListPage, CameraListViewModel> {
  _CameraListPageState(CameraListViewModel viewModel) : super(viewModel, true);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final destination = bindableBase.destination;
    return Scaffold(
      appBar: AppBar(title: Text(destination.title)),
      drawer: AppDrawer(
        currentDestination: destination,
        navigationService: bindableBase.navigationService,
      ),
      body: Center(child: Text('${destination.title} is not available yet.')),
    );
  }
}


class CameraListViewModel extends ViewModel {
  CameraListViewModel(this.navigationService);

  final NavigationService navigationService;

  AppDestination get destination => AppDestination.cameraList;
}
