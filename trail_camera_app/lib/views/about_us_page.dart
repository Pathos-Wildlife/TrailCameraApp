part of 'views.dart';

class AboutUsPage extends FmvvmStatefulWidget<AboutUsViewModel> {
  const AboutUsPage(super.viewModel, {super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends FmvvmState<AboutUsPage, AboutUsViewModel> {
  _AboutUsPageState() : super(true);

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

class AboutUsViewModel extends ViewModel {
  AboutUsViewModel(this.navigationService);

  final NavigationService navigationService;

  AppDestination get destination => AppDestination.aboutUs;
}
