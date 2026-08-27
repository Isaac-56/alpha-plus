import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../onboarding/models/driver_registration.dart';
import '../data/driver_presence_service.dart';
import 'driver_detail_screens.dart';
import 'driver_map_camera.dart';

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
      const _PoolPage(),
      const _MoneyPage(),
      const _ChatsPage(),
      _ProfilePage(
        driverName: widget.driverName,
        registration: widget.registration,
        onSignOut: widget.onSignOut,
      ),
    ];

    return PopScope(
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
              icon: Badge(
                label: Text('1'),
                child: Icon(Icons.chat_bubble_outline_rounded),
              ),
              selectedIcon: Badge(
                label: Text('1'),
                child: Icon(Icons.chat_bubble_rounded),
              ),
              label: 'Chats',
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
                                // Preserve some map above the scrollable card.
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
                      // Transparent space for the SDK's own logo and copyright.
                      // NavigationBar sits outside the map body, below this.
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
      // Let the GoogleMap child send its updated native padding first.
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
      // A map can be disposed while a viewport update is in flight.
      // The location button can retry when the map is available again.
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
  const _PoolPage();

  @override
  Widget build(BuildContext context) {
    return _EmptyStatePage(
      title: 'Order pool',
      icon: Icons.inbox_rounded,
      headline: 'No trip requests right now',
      description: 'New requests will appear here as soon as you are approved.',
      buttonLabel: 'Update',
      onPressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order pool refreshed.')));
      },
    );
  }
}

class _MoneyPage extends StatelessWidget {
  const _MoneyPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Money',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () =>
                    _openScreen(context, const SupportConversationScreen()),
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Support'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'SSP 0',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 52),
          ),
          const Text(
            'Today',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          _DashboardCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "View other drivers' stats",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Complete trips to see your own'),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () => _showComingSoon(context, 'Driver statistics'),
            ),
          ),
          const SizedBox(height: 26),
          _DashboardCard(
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Balance limit'),
                  subtitle: const Text('Everything looks good'),
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '-SSP 0',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_right_rounded),
                    ],
                  ),
                  onTap: () => _openScreen(context, const BalanceLimitScreen()),
                ),
                Divider(color: Theme.of(context).dividerColor),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Balance'),
                  trailing: Text(
                    'SSP 0',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Service partner'),
                      SizedBox(height: 4),
                      Text(
                        'Alpha Plus South Sudan',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatsPage extends StatelessWidget {
  const _ChatsPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text('Messages', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 142,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _MessageStory(
                  icon: Icons.route_rounded,
                  title: 'Earn on your way',
                  onTap: () => _openScreen(
                    context,
                    const InformationMessageScreen(
                      title: 'Earn on your way',
                      body:
                          'When requests go live, Alpha Plus can show trips that move you toward your chosen area.',
                      icon: Icons.route_rounded,
                    ),
                  ),
                ),
                _MessageStory(
                  icon: Icons.health_and_safety_rounded,
                  title: 'About safety',
                  onTap: () => _openScreen(
                    context,
                    const InformationMessageScreen(
                      title: 'Safety first',
                      body:
                          'Keep your vehicle roadworthy, follow local traffic rules, and use in-app Support whenever a trip feels unsafe.',
                      icon: Icons.health_and_safety_rounded,
                    ),
                  ),
                ),
                _MessageStory(
                  icon: Icons.support_agent_rounded,
                  title: 'Driver help',
                  onTap: () =>
                      _openScreen(context, const SupportConversationScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _MessageTile(
            icon: Icons.support_agent_rounded,
            title: 'Support',
            color: AppColors.primary,
            onTap: () =>
                _openScreen(context, const SupportConversationScreen()),
          ),
          _MessageTile(
            icon: Icons.newspaper_rounded,
            title: 'Alpha Plus news',
            subtitle: 'Welcome to the driver community',
            onTap: () => _openScreen(
              context,
              const InformationMessageScreen(
                title: 'Welcome to Alpha Plus',
                body:
                    'Your driver account is being prepared. Service updates and approval messages will appear here.',
                icon: Icons.newspaper_rounded,
              ),
            ),
          ),
          _MessageTile(
            icon: Icons.notifications_active_rounded,
            title: 'Service notifications',
            onTap: () => _showComingSoon(context, 'Service notifications'),
          ),
          _MessageTile(
            icon: Icons.warning_amber_rounded,
            title: 'Safety alerts',
            onTap: () => _openScreen(
              context,
              const InformationMessageScreen(
                title: 'Safety alerts',
                body:
                    'Important safety notices for Juba and your active service area will appear here.',
                icon: Icons.warning_amber_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.driverName,
    required this.registration,
    this.onSignOut,
  });

  final String driverName;
  final DriverRegistration registration;
  final Future<void> Function()? onSignOut;

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              icon: const Icon(Icons.logout_rounded),
              title: const Text('Log out of Alpha Plus?'),
              content: const Text(
                'You will stop receiving driver updates on this device until you sign in again.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Log out'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmed) {
      await onSignOut?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.person_rounded, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  driverName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () =>
                    _openScreen(context, const InviteDriverScreen()),
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DashboardCard(
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.local_taxi_rounded),
                  ),
                  title: const Text(
                    'Driver',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text('Account under review'),
                  trailing: FilledButton.tonal(
                    onPressed: () =>
                        _openScreen(context, const DriverServicesScreen()),
                    child: const Text('My services'),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        value: '+100',
                        label: 'Priority',
                        icon: Icons.bolt_rounded,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        value: '5.0',
                        label: 'Rating',
                        icon: Icons.star_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DashboardCard(
            child: Column(
              children: <Widget>[
                _ProfileAction(
                  icon: Icons.business_center_outlined,
                  title: 'Partner',
                  value: 'Alpha Plus South Sudan',
                  onTap: () => _openScreen(context, const PartnerScreen()),
                ),
                _ProfileAction(
                  icon: Icons.apps_rounded,
                  title: 'Services and options',
                  value: '1 active',
                  onTap: () =>
                      _openScreen(context, const DriverServicesScreen()),
                ),
                _ProfileAction(
                  icon: Icons.payments_outlined,
                  title: 'Payment',
                  value: 'Cash',
                  showDivider: false,
                  onTap: () =>
                      _openScreen(context, const PaymentInformationScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('My vehicle', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _openScreen(
              context,
              DriverVehicleScreen(registration: registration),
            ),
            child: _DashboardCard(
              child: SizedBox(
                height: 130,
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        _vehicleName(registration),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        size: 116,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          registration.plateNumber.isEmpty
                              ? 'PLATE PENDING'
                              : registration.plateNumber,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DashboardCard(
            child: Column(
              children: <Widget>[
                _ProfileAction(
                  icon: Icons.build_circle_outlined,
                  title: 'Troubleshooting',
                  onTap: () =>
                      _openScreen(context, const TroubleshootingScreen()),
                ),
                _ProfileAction(
                  icon: Icons.camera_alt_outlined,
                  title: 'Photo check',
                  showDivider: false,
                  onTap: () => _openScreen(context, const PhotoCheckScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DashboardCard(
            child: Column(
              children: <Widget>[
                _ProfileAction(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Invite a friend',
                  onTap: () => _openScreen(context, const InviteDriverScreen()),
                ),
                _ProfileAction(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  showDivider: false,
                  onTap: () =>
                      _openScreen(context, const DriverSettingsScreen()),
                ),
              ],
            ),
          ),
          if (onSignOut != null) ...<Widget>[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyStatePage extends StatelessWidget {
  const _EmptyStatePage({
    required this.title,
    required this.icon,
    required this.headline,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final String headline;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const Spacer(),
            Center(
              child: Column(
                children: <Widget>[
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 58),
                  ),
                  const SizedBox(height: 24),
                  Text(headline, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(buttonLabel),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 7),
      leading: CircleAvatar(
        radius: 27,
        backgroundColor: color ?? AppColors.primary.withValues(alpha: 0.2),
        child: Icon(icon, color: AppColors.ink),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.keyboard_arrow_right_rounded),
      onTap: onTap,
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    value!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_right_rounded),
            ],
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(label),
              ],
            ),
          ),
          Icon(icon, color: AppColors.ink),
        ],
      ),
    );
  }
}

class _MessageStory extends StatelessWidget {
  const _MessageStory({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 126,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Align(alignment: Alignment.topRight, child: _NewPill()),
              const Spacer(),
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPill extends StatelessWidget {
  const _NewPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'New',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _vehicleName(DriverRegistration registration) {
  final String name = <String>[
    registration.make,
    registration.model,
  ].where((String part) => part.trim().isNotEmpty).join(' ');
  return name.isEmpty ? 'Vehicle under review' : name;
}

void _openScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature will be connected in the backend stage.')),
  );
}
