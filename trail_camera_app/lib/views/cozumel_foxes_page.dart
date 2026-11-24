part of 'views.dart';

class CozumelFoxesPage extends FmvvmStatefulWidget<CozumelFoxesViewModel> {
  const CozumelFoxesPage(super.viewModel, {super.key});

  @override
  State<CozumelFoxesPage> createState() => _CozumelFoxesPageState();
}

class _CozumelFoxesPageState
    extends FmvvmState<CozumelFoxesPage, CozumelFoxesViewModel> {
  _CozumelFoxesPageState() : super(true);

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
