part of 'views.dart';

class CameraListPage extends FmvvmStatefulWidget<CameraListViewModel> {
  CameraListPage(super.viewModel, {super.key});

  @override
  State<CameraListPage> createState() => _CameraListPageState(bindableBase);
}

class _CameraListPageState
    extends FmvvmState<CameraListPage, CameraListViewModel> {
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
      body: BindingWidget<CameraListViewModel>(
        bindings: [
          Binding('cameras', bindableBase, CameraListViewModel.camerasProperty),
          Binding(
            'loadError',
            bindableBase,
            CameraListViewModel.loadErrorProperty,
          ),
          Binding(
            'isLoading',
            bindableBase,
            CameraListViewModel.isLoadingProperty,
          ),
        ],
        builder: (context) {
          final binding = BindingWidget.of<CameraListViewModel>(context);
          final cameras = binding.getGenericValue<NotificationList<Camera>>(
            'cameras',
          );
          final loadError = binding.getGenericValue<String>('loadError');
          if (binding.getGenericValue<bool>('isLoading')) {
            return const Center(child: CircularProgressIndicator());
          }
          if (loadError.isNotEmpty) {
            return Center(child: Text(loadError));
          }
          if (cameras.isEmpty) {
            return const Center(child: Text('No cameras available.'));
          }
          return ListView.builder(
            itemCount: cameras.length,
            itemBuilder: (context, index) {
              final camera = cameras[index];
              return KeyedSubtree(
                key: ObjectKey(camera),
                child: BindingWidget<Camera>(
                  bindings: [
                    Binding('name', camera, Camera.cameraNameProperty),
                    Binding('latitude', camera, Camera.latitudeProperty),
                    Binding('longitude', camera, Camera.longitudeProperty),
                  ],
                  builder: (context) {
                    final cameraBinding = BindingWidget.of<Camera>(context);
                    return Card(
                      child: ListTile(
                        onTap: () => bindableBase.selectCamera(camera.id),
                        title: Text(
                          cameraBinding.getGenericValue<String>('name'),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latitude: ${cameraBinding.getGenericValue<double>('latitude')}',
                            ),
                            Text(
                              'Longitude: ${cameraBinding.getGenericValue<double>('longitude')}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CameraListViewModel extends ViewModel {
  CameraListViewModel(this._navigationService, this._dataService) {
    setGenericValue<NotificationList<Camera>>(
      camerasProperty,
      NotificationList<Camera>(),
    );
  }

  final NavigationService _navigationService;
  final IDataService _dataService;

  NavigationService get navigationService => _navigationService;
  AppDestination get destination => AppDestination.cameraList;

  int? _selectedCameraId;
  Command? _cameraSelected;
  Command get cameraSelected => _cameraSelected ??= Command(_navigateToCamera);

  void selectCamera(int cameraId) {
    _selectedCameraId = cameraId;
    cameraSelected.execute();
  }

  Future<void> _navigateToCamera() async {
    final cameraId = _selectedCameraId;
    if (cameraId == null) {
      throw StateError('A camera must be selected before navigating.');
    }
    await _navigationService.navigate<MapViewModel>(parameter: cameraId);
  }

  @override
  void init(Object? parameter) {
    setGenericValue<bool>(isLoadingProperty, true);
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      final result = await _dataService.getAll<Camera>();
      cameras.addAll(result);
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not load cameras: $error\n$stackTrace');
      setGenericValue<String>(loadErrorProperty, 'Could not load cameras.');
    } finally {
      setGenericValue<bool>(isLoadingProperty, false);
    }
  }

  static final loadErrorProperty = PropertyInfo('loadError', String);
  static final isLoadingProperty = PropertyInfo('isLoading', bool);
  static PropertyInfo camerasProperty = PropertyInfo(
    'cameras',
    NotificationList<Camera>,
  );
  NotificationList<Camera> get cameras =>
      getGenericValue<NotificationList<Camera>>(camerasProperty);
}
