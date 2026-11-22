import 'package:flutter/widgets.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/views/app_drawer.dart';
import 'package:flutter/material.dart';

class CozumelFoxesPage extends FmvvmStatefulWidget<CozumelFoxesViewModel> {
  CozumelFoxesPage(super.viewModel, {super.key});

  @override
  State<CozumelFoxesPage> createState() => _CozumelFoxesPageState(bindableBase);
}

class _CozumelFoxesPageState extends FmvvmState<CozumelFoxesPage, CozumelFoxesViewModel> {
  _CozumelFoxesPageState(CozumelFoxesViewModel viewModel) : super(viewModel, true);

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


class CozumelFoxesViewModel extends ViewModel {
  CozumelFoxesViewModel(this.navigationService);

  final NavigationService navigationService;

  AppDestination get destination => AppDestination.cozumelFoxes;
}
