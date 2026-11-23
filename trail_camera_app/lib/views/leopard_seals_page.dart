part of 'views.dart';

class LeopardSealsPage extends FmvvmStatefulWidget<LeopardSealsViewModel> {
  LeopardSealsPage(super.viewModel, {super.key});

  @override
  State<LeopardSealsPage> createState() => _LeopardSealsPageState(bindableBase);
}

class _LeopardSealsPageState extends FmvvmState<LeopardSealsPage, LeopardSealsViewModel> {
  _LeopardSealsPageState(LeopardSealsViewModel viewModel) : super(viewModel, true);

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


class LeopardSealsViewModel extends ViewModel {
  LeopardSealsViewModel(this.navigationService);

  final NavigationService navigationService;

  AppDestination get destination => AppDestination.leopardSeals;
}
