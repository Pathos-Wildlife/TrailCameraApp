part of 'views.dart';

class ContactPage extends FmvvmStatefulWidget<ContactViewModel> {
  const ContactPage(super.viewModel, {super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends FmvvmState<ContactPage, ContactViewModel> {
  _ContactPageState() : super(true);

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

class ContactViewModel extends ViewModel {
  ContactViewModel(this.navigationService);

  final NavigationService navigationService;

  AppDestination get destination => AppDestination.contact;
}
