import 'package:flutter/widgets.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/views/app_drawer.dart';
import 'package:flutter/material.dart';

class DonatePage extends FmvvmStatefulWidget<DonateViewModel> {
  DonatePage(super.viewModel, {super.key});

  @override
  State<DonatePage> createState() => _DonatePageState(bindableBase);
}

class _DonatePageState extends FmvvmState<DonatePage, DonateViewModel> {
  _DonatePageState(DonateViewModel viewModel) : super(viewModel, true);

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


class DonateViewModel extends ViewModel {
  DonateViewModel(this.navigationService);

  final NavigationService navigationService;

  AppDestination get destination => AppDestination.donate;
}
