import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../onboarding/models/driver_registration.dart';
import '../../rides/presentation/driver_ride_offer_layer.dart';
import '../data/driver_presence_service.dart';
import 'driver_map_camera.dart';
import 'driver_ui_pages.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({
    this.driverId = '',
    required this.driverName,
    this.reviewStatus = 'pending',
    required this.registration,
    this.onSignOut,
    this.mapBuilder,
    super.key,
  });

  final String driverId;
  final String driverName;
  final String reviewStatus;
  final DriverRegistration registration;
  final Future<void> Function()? onSignOut;
  final WidgetBuilder? mapBuilder;

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _RequestsPage(
        driverId: widget.driverId,
        driverName: widget.driverName,
        reviewStatus: widget.reviewStatus,
        vehicleType: widget.registration.vehicleType,
        mapBuilder: widget.mapBuilder,
      ),
      _PoolPage(
        reviewStatus: widget.reviewStatus,
        registration: widget.registration,
      ),
      const _MoneyPage(),
      const _ChatsPage(),
      _ProfilePage(
        driverName: widget.driverName,
        reviewStatus: widget.reviewStatus,
        registration: widget.registration,
        onSignOut: widget.onSignOut,
      ),
    ];

    final Widget shell = PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int value) => setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.navigation_outlined),
              selectedIcon: Icon(Icons.navigation_rounded),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Pool',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Money',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Inbox',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );

    final bool liveOffersEnabled =
        widget.driverId.trim().isNotEmpty &&
        widget.reviewStatus.trim().toLowerCase() == 'approved';

    if (!liveOffersEnabled) return shell;

    return DriverRideOfferLayer(driverId: widget.driverId, child: shell);
  }
}

class _RequestsPage extends StatefulWidget {
  const _RequestsPage({
    required this.driverId,
    required this.driverName,
    required this.reviewStatus,
    required this.vehicleType,
    this.mapBuilder,
  });

  final String driverId;
  final String driverName;
  final String reviewStatus;
  final String vehicleType;
  final WidgetBuilder? mapBuilder;

  @override
  State<_RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<_RequestsPage> {
  final GlobalKey _mapBoundsKey = GlobalKey();
  final GlobalKey _availabilityKey = GlobalKey();
  final GlobalKey _progressKey = GlobalKey();
  EdgeInsets _cameraInsets = const EdgeInsets.only(top: 96, bottom: 340);
  double _attributionBottom = 8;
  bool _measurementScheduled = false;

  void _scheduleViewportMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;
      final RenderObject? mapObject = _mapBoundsKey.currentContext
          ?.findRenderObject();
      final RenderObject? availabilityObject = _availabilityKey.currentContext
          ?.findRenderObject();
      final RenderObject? progressObject = _progressKey.currentContext
          ?.findRenderObject();
      if (mapObject is! RenderBox ||
          availabilityObject is! RenderBox ||
          progressObject is! RenderBox ||
          !mapObject.hasSize ||
          !availabilityObject.hasSize ||
          !progressObject.hasSize) {
        return;
      }

      final double mapTop = mapObject.localToGlobal(Offset.zero).dy;
      final double headerBottom = availabilityObject
          .localToGlobal(Offset(0, availabilityObject.size.height))
          .dy;
      final double panelTop = progressObject.localToGlobal(Offset.zero).dy;
      final EdgeInsets cameraInsets = EdgeInsets.only(
        top: headerBottom - mapTop + 8,
        bottom: mapTop + mapObject.size.height - panelTop + 8,
      );
      final double attributionBottom = MediaQuery.paddingOf(context).bottom + 8;
      if (_cameraInsets != cameraInsets ||
          _attributionBottom != attributionBottom) {
        setState(() {
          _cameraInsets = cameraInsets;
          _attributionBottom = attributionBottom;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _scheduleViewportMeasurement();
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            SizedBox.expand(
              key: _mapBoundsKey,
              child:
                  widget.mapBuilder?.call(context) ??
                  _DriverMap(
                    cameraInsets: _cameraInsets,
                    attributionBottom: _attributionBottom,
                  ),
            ),
            NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                _scheduleViewportMeasurement();
                return true;
              },
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizeChangedLayoutNotifier(
                        child: SizedBox(
                          key: _availabilityKey,
                          child: _DriverAvailabilityCard(
                            driverId: widget.driverId,
                            reviewStatus: widget.reviewStatus,
                            vehicleType: widget.vehicleType,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (BuildContext context, BoxConstraints bounds) {
                                final double mapGap = (bounds.maxHeight * 0.35)
                                    .clamp(0.0, 112.0)
                                    .toDouble();
                                return Align(
                                  alignment: Alignment.bottomCenter,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: bounds.maxHeight - mapGap,
                                    ),
                                    child: SizeChangedLayoutNotifier(
                                      child: SizedBox(
                                        key: _progressKey,
                                        child: _buildProgressCard(context),
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                      const SizedBox(
                        key: Key('driverMapAttributionClearance'),
                        height: 56,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    return Container(
      key: const Key('driverProgressCard'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: SingleChildScrollView(
        key: const Key('driverProgressScroll'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome, ${widget.driverName.split(' ').first}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            const _ProgressRow(
              title: 'Registration',
              subtitle: 'Complete',
              complete: true,
            ),
            const _ProgressRow(
              title: 'Driver documents',
              subtitle: 'Submitted',
              complete: true,
            ),
            _ProgressRow(
              title: 'Account approval',
              subtitle: _reviewLabel(widget.reviewStatus),
              complete: DriverAvailabilityPolicy.canGoOnline(
                widget.reviewStatus,
              ),
            ),
            const _ProgressRow(
              title: 'Device setup',
              subtitle: 'Ready',
              complete: true,
              showLine: false,
            ),
          ],
        ),
      ),
    );
  }

  String _reviewLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Needs attention';
      default:
        return 'Under review';
    }
  }
}

class _DriverAvailabilityCard extends StatefulWidget {
  const _DriverAvailabilityCard({
    required this.driverId,
    required this.reviewStatus,
    required this.vehicleType,
  });

  final String driverId;
  final String reviewStatus;
  final String vehicleType;

  @override
  State<_DriverAvailabilityCard> createState() =>
      _DriverAvailabilityCardState();
}

class _DriverAvailabilityCardState extends State<_DriverAvailabilityCard> {
  DriverPresenceService? _presence;

  bool _changing = false;

  DriverPresenceService get _service =>
      _presence ??= DriverPresenceService.instance;

  bool get _approved =>
      DriverAvailabilityPolicy.canGoOnline(widget.reviewStatus);

  @override
  void dispose() {
    final DriverPresenceService? presence = _presence;
    if (presence != null) {
      unawaited(presence.goOffline());
    }
    super.dispose();
  }

  Future<void> _setOnline(bool online) async {
    if (_changing) return;

    setState(() => _changing = true);
    try {
      if (online) {
        await _service.goOnline(
          driverId: widget.driverId,
          reviewStatus: widget.reviewStatus,
          vehicleType: widget.vehicleType,
        );
      } else {
        await _service.goOffline();
      }
    } on DriverPresenceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Alpha Plus could not update your availability. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_approved || widget.driverId.isEmpty) {
      final bool rejected = widget.reviewStatus.toLowerCase() == 'rejected';
      return _AvailabilitySurface(
        child: Row(
          children: <Widget>[
            Icon(
              rejected ? Icons.error_outline_rounded : Icons.schedule_rounded,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rejected
                        ? 'Verification needs attention'
                        : 'Verification in progress',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    rejected
                        ? 'Open Profile to review the required steps'
                        : 'You can go online immediately after approval',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<bool>(
      stream: _service.watchOnlineState(widget.driverId),
      initialData: false,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        final bool isOnline = snapshot.data ?? false;

        return _AvailabilitySurface(
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.primary : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: isOnline
                      ? <BoxShadow>[
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isOnline ? 'You are online' : 'You are offline',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      isOnline
                          ? 'Your live location is visible for nearby requests'
                          : 'Go online when you are ready to drive',
                    ),
                  ],
                ),
              ),
              if (_changing)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                Switch.adaptive(value: isOnline, onChanged: _setOnline),
            ],
          ),
        );
      },
    );
  }
}

class _AvailabilitySurface extends StatelessWidget {
  const _AvailabilitySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DriverMap extends StatefulWidget {
  const _DriverMap({
    required this.cameraInsets,
    required this.attributionBottom,
  });

  final EdgeInsets cameraInsets;
  final double attributionBottom;

  @override
  State<_DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<_DriverMap> {
  static const LatLng _jubaCenter = LatLng(4.8517, 31.5825);
  static const double _overviewZoom = 16;
  static const double _focusedZoom = 17;

  GoogleMapController? _mapController;
  LatLng _driverLocation = _jubaCenter;
  bool _locationGranted = false;
  bool _findingLocation = true;

  EdgeInsets get _mapPadding => EdgeInsets.fromLTRB(
    8,
    widget.cameraInsets.top,
    8,
    widget.attributionBottom,
  );

  bool get _supportsGoogleMap =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (_supportsGoogleMap) {
      _locateDriver(requestPermission: false);
    }
  }

  @override
  void didUpdateWidget(covariant _DriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraInsets != widget.cameraInsets ||
        oldWidget.attributionBottom != widget.attributionBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_frameDriver(animate: false));
      });
    }
  }

  Future<void> _frameDriver({bool animate = true}) async {
    final GoogleMapController? controller = _mapController;
    if (controller == null || !mounted) return;
    final CameraUpdate update = CameraUpdate.newCameraPosition(
      driverMapCameraPosition(
        location: _driverLocation,
        zoom: _locationGranted ? _focusedZoom : _overviewZoom,
        viewportInsets: widget.cameraInsets,
        mapPadding: _mapPadding,
      ),
    );
    try {
      if (animate) {
        await controller.animateCamera(update);
      } else {
        await controller.moveCamera(update);
      }
    } on Object {
      // The native map can be disposed while a camera update is in flight.
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _locateDriver({required bool requestPermission}) async {
    if (mounted) {
      setState(() => _findingLocation = true);
    }

    try {
      PermissionStatus status = await Permission.locationWhenInUse.status;
      if (requestPermission && status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }

      if (!status.isGranted) {
        if (requestPermission && status.isPermanentlyDenied) {
          await openAppSettings();
        }
        if (mounted) {
          setState(() {
            _locationGranted = false;
            _findingLocation = false;
          });
        }
        return;
      }

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (requestPermission) {
          await Geolocator.openLocationSettings();
        }
        if (mounted) {
          setState(() {
            _locationGranted = true;
            _findingLocation = false;
          });
        }
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final LatLng location = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() {
        _driverLocation = location;
        _locationGranted = true;
        _findingLocation = false;
      });
      await _frameDriver();
    } on Object {
      if (mounted) {
        setState(() => _findingLocation = false);
        if (requestPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your location is unavailable. Check Location in device settings.',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsGoogleMap) {
      return const ColoredBox(
        color: Color(0xFFE9F7E7),
        child: Center(
          child: Icon(Icons.map_outlined, size: 74, color: AppColors.ink),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GoogleMap(
          initialCameraPosition: driverMapCameraPosition(
            location: _jubaCenter,
            zoom: _overviewZoom,
            viewportInsets: widget.cameraInsets,
            mapPadding: _mapPadding,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            unawaited(_frameDriver(animate: false));
          },
          padding: _mapPadding,
          myLocationEnabled: _locationGranted,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          minMaxZoomPreference: const MinMaxZoomPreference(12, 20),
          compassEnabled: true,
          mapToolbarEnabled: false,
          trafficEnabled: false,
          buildingsEnabled: true,
          indoorViewEnabled: false,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: true,
          mapType: MapType.normal,
          markers: const <Marker>{},
          polylines: const <Polyline>{},
        ),
        Positioned(
          top: widget.cameraInsets.top + 8,
          right: 16,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 5,
            shadowColor: Colors.black26,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Center on my location',
              onPressed: _findingLocation
                  ? null
                  : () => _locateDriver(requestPermission: true),
              icon: _findingLocation
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    )
                  : Icon(
                      _locationGranted
                          ? Icons.my_location_rounded
                          : Icons.location_disabled_rounded,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.title,
    required this.subtitle,
    required this.complete,
    this.showLine = true,
  });

  final String title;
  final String subtitle;
  final bool complete;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 38,
            child: Column(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: complete
                        ? AppColors.primary
                        : Theme.of(context).dividerColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.ink,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(width: 3, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolPage extends StatelessWidget {
  const _PoolPage({required this.reviewStatus, required this.registration});

  final String reviewStatus;
  final DriverRegistration registration;

  @override
  Widget build(BuildContext context) {
    return DriverPoolPageUi(
      reviewStatus: reviewStatus,
      registration: registration,
    );
  }
}

class _MoneyPage extends StatelessWidget {
  const _MoneyPage();

  @override
  Widget build(BuildContext context) {
    return const DriverMoneyPageUi();
  }
}

class _ChatsPage extends StatelessWidget {
  const _ChatsPage();

  @override
  Widget build(BuildContext context) {
    return const DriverInboxPageUi();
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.driverName,
    required this.reviewStatus,
    required this.registration,
    this.onSignOut,
  });

  final String driverName;
  final String reviewStatus;
  final DriverRegistration registration;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return DriverProfilePageUi(
      driverName: driverName,
      reviewStatus: reviewStatus,
      registration: registration,
      onSignOut: onSignOut,
    );
  }
}
