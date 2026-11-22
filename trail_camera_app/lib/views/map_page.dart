import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trail_camera_app/views/app_drawer.dart';
import 'package:trail_camera_app/views/login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fmvvm/fmvvm.dart';
import 'package:trail_camera_app/services/google_sign_in_service.dart';

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
      drawer: AppDrawer(currentDestination: AppDestination.cameraMap, navigationService: bindableBase._navigationService,),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 11,
              minZoom: 10,
              maxZoom: 19,
              cameraConstraint: CameraConstraint.containCenter(bounds: _bounds),
            ),
            children: [
              widget.tileLayer ??
                  TileLayer(
                    key: ValueKey(_tileLayerVersion),
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'org.pathoswildlife.trail_camera_app',
                    errorTileCallback: (_, error, stackTrace) {
                      debugPrint('Map tile failed to load: $error');
                      if (mounted && !_tileLoadFailed) {
                        setState(() => _tileLoadFailed = true);
                      }
                    },
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
                        content: Text('Could not open map attribution.'),
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
                        child: Text('Some map tiles could not be loaded.'),
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
      ),
    );
  }
}


class MapViewModel extends ViewModel {
  MapViewModel(this._navigationService, this._signInService);
  
  final NavigationService _navigationService;
  final GoogleSignInService _signInService;

  static PropertyInfo signInErrorProperty = PropertyInfo('signInError', String);
  String get signInError => getGenericValue<String>(signInErrorProperty);
  set _signInError(String value) => {
    setGenericValue<String>(signInErrorProperty, value),
  };

  static PropertyInfo isSignedInProperty = PropertyInfo('isSignedIn', bool);
  bool? get isSignedIn => getGenericValue<bool?>(isSignedInProperty);
  set _isSignedIn(bool? value) => {
    setGenericValue<bool?>(isSignedInProperty, value),
    if (value != true && value != null) {
      _navigationService.navigate<LoginViewModel>(),
    }
  };
  
  Future<void> restoreSignIn() async {
    try {
      final user = await _signInService.restoreSignIn();
      _isSignedIn = (user != null);
    } on GoogleSignInException catch (error) {
      _isSignedIn = false;
      _signInError = error.message;
    } on Exception catch (error, stackTrace) {
      debugPrint('Google sign-in restoration failed: $error\n$stackTrace');
      _isSignedIn = false;
      _signInError = 'Could not restore Google sign-in. Please sign in again.';
    }
  }
}