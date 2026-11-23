part of 'views.dart';

class MapPage extends FmvvmStatefulWidget<MapViewModel> {
  MapPage(super.viewModel, {super.key, this.tileLayer});

  @visibleForTesting
  final Widget? tileLayer;

  @override
  State<MapPage> createState() => _MapPageState(bindableBase);
}

class _MapPageState extends FmvvmState<MapPage, MapViewModel> {
  _MapPageState(MapViewModel viewModel) : super(viewModel, true);

  final MapController _mapController = MapController();
  bool _tileLoadFailed = false;
  int _tileLayerVersion = 0;
  static const _center = LatLng(20.422, -86.914);
  static final _bounds = LatLngBounds(
    const LatLng(20.18, -87.10),
    const LatLng(20.65, -86.65),
  );

  @override
  void initState() {
    super.initState();
    bindableBase.restoreSignIn();
  }

  void _zoom(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, camera.zoom + delta);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Map')),
      drawer: AppDrawer(
        currentDestination: AppDestination.cameraMap,
        navigationService: bindableBase._navigationService,
      ),
      body: BindingWidget<MapViewModel>(
        bindings: [
          Binding('camera', bindableBase, MapViewModel.camerasProperty),
          Binding(
            'selectedCameraId',
            bindableBase,
            MapViewModel.selectedCameraIdProperty,
          ),
        ],
        builder: (context) {
          final binding = BindingWidget.of<MapViewModel>(context);
          final cameras = binding.getGenericValue<NotificationList<Camera>>(
            'camera',
          );
          final selectedCameraId = binding.getGenericValue<int?>(
            'selectedCameraId',
          );
          return ListenableBuilder(
            listenable: Listenable.merge(List<Camera>.of(cameras)),
            builder: (context, _) {
              Camera? selectedCamera;
              for (final camera in cameras) {
                if (camera.id == selectedCameraId) {
                  selectedCamera = camera;
                  break;
                }
              }
              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 11,
                      minZoom: 10,
                      maxZoom: 19,
                      cameraConstraint: CameraConstraint.containCenter(
                        bounds: _bounds,
                      ),
                    ),
                    children: [
                      widget.tileLayer ??
                          TileLayer(
                            key: ValueKey(_tileLayerVersion),
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'org.pathoswildlife.trail_camera_app',
                            errorTileCallback: (_, error, stackTrace) {
                              debugPrint('Map tile failed to load: $error');
                              if (mounted && !_tileLoadFailed) {
                                setState(() => _tileLoadFailed = true);
                              }
                            },
                          ),
                      MarkerLayer(
                        markers: [
                          for (final camera in cameras)
                            Marker(
                              point: LatLng(camera.latitude, camera.longitude),
                              width: 48,
                              height: 48,
                              alignment: Alignment.topCenter,
                              child: IconButton(
                                tooltip: camera.cameraName,
                                onPressed: () =>
                                    bindableBase.selectedCameraId = camera.id,
                                icon: Icon(
                                  Icons.location_on,
                                  color: identical(camera, selectedCamera)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                  size: 36,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SimpleAttributionWidget(
                        source: const Text('OpenStreetMap contributors'),
                        onTap: () async {
                          final uri = Uri.parse(
                            'https://www.openstreetmap.org/copyright',
                          );
                          if (!await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              ) &&
                              context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not open map attribution.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  if (_tileLoadFailed)
                    Positioned(
                      left: 12,
                      right: 80,
                      top: 12,
                      child: Material(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Some map tiles could not be loaded.',
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _tileLoadFailed = false;
                                  _tileLayerVersion++;
                                }),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (selectedCamera != null)
                    Positioned(
                      left: 12,
                      right: 80,
                      bottom: 40,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(selectedCamera.cameraName),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'zoomIn',
                          tooltip: 'Zoom in',
                          onPressed: () => _zoom(1),
                          child: const Icon(Icons.add),
                        ),
                        FloatingActionButton.small(
                          heroTag: 'zoomOut',
                          tooltip: 'Zoom out',
                          onPressed: () => _zoom(-1),
                          child: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class MapViewModel extends ViewModel {
  MapViewModel(
    this._navigationService,
    this._signInService,
    this._dataService,
  ) {
    setGenericValue<NotificationList<Camera>>(
      camerasProperty,
      NotificationList<Camera>(),
    );
  }

  final NavigationService _navigationService;
  final ISignInService _signInService;
  final IDataService _dataService;

  @override
  void init(Object? parameter) {
    if (parameter != null && parameter is! int) {
      throw ArgumentError.value(parameter, 'parameter', 'Expected a camera ID');
    }
    selectedCameraId = parameter as int?;
    _dataService.getAll<Camera>().then((result) => cameras.addAll(result));
  }

  static final selectedCameraIdProperty = PropertyInfo(
    'selectedCameraId',
    Object,
  );
  int? get selectedCameraId => getGenericValue<int?>(selectedCameraIdProperty);
  set selectedCameraId(int? value) =>
      setGenericValue<int?>(selectedCameraIdProperty, value);

  static PropertyInfo signInErrorProperty = PropertyInfo('signInError', String);
  String get signInError => getGenericValue<String>(signInErrorProperty);
  set _signInError(String value) => {
    setGenericValue<String>(signInErrorProperty, value),
  };

  static PropertyInfo isSignedInProperty = PropertyInfo('isSignedIn', bool);
  bool? get isSignedIn => getGenericValue<bool?>(isSignedInProperty);
  set _isSignedIn(bool? value) => {
    setGenericValue<bool?>(isSignedInProperty, value),
    if (value != true && value != null)
      {_navigationService.navigate<LoginViewModel>()},
  };

  static PropertyInfo camerasProperty = PropertyInfo(
    'cameras',
    NotificationList<Camera>,
  );
  NotificationList<Camera> get cameras =>
      getGenericValue<NotificationList<Camera>>(camerasProperty);

  Future<void> restoreSignIn() async {
    try {
      final user =
          _signInService.currentUser ?? await _signInService.restoreSignIn();
      _isSignedIn = (user != null);
    } on Exception catch (error, stackTrace) {
      debugPrint('Sign-in restoration failed: $error\n$stackTrace');
      _isSignedIn = false;
      _signInError =
          'Could not restore sign-in. Please sign in again. ${error.toString()}';
    }
  }
}
