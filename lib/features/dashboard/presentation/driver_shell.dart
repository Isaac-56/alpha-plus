import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../onboarding/models/driver_registration.dart';
import '../../notifications/data/driver_push_notification_service.dart';
import '../../rides/presentation/driver_active_ride_layer.dart';
import '../../rides/presentation/driver_money_page.dart';
import '../../rides/presentation/driver_pool_page.dart';
import '../../rides/presentation/driver_ride_offer_layer.dart';
import '../../wallet/data/driver_wallet_service.dart';
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
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
    _syncRideNotifications();
  }

  @override
  void didUpdateWidget(covariant DriverShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverId != widget.driverId ||
        oldWidget.driverName != widget.driverName ||
        oldWidget.reviewStatus != widget.reviewStatus ||
        oldWidget.registration != widget.registration ||
        oldWidget.onSignOut != widget.onSignOut ||
        oldWidget.mapBuilder != widget.mapBuilder) {
      _pages = _buildPages();
      _syncRideNotifications();
    }
  }

  void _syncRideNotifications() {
    if (Firebase.apps.isNotEmpty &&
        widget.driverId.trim().isNotEmpty &&
        widget.reviewStatus.trim().toLowerCase() == 'approved') {
      unawaited(
        DriverPushNotificationService.instance.start(widget.driverId),
      );
    }
  }

  Future<void> _signOut() async {
    await DriverPresenceService.instance.goOffline();
    await DriverPushNotificationService.instance.stop(unregister: true);
    await widget.onSignOut?.call();
  }

  List<Widget> _buildPages() {
    return <Widget>[
      _RequestsPage(
        driverId: widget.driverId,
        driverName: widget.driverName,
        reviewStatus: widget.reviewStatus,
        vehicleType: widget.registration.effectiveVehicleClass,
        mapBuilder: widget.mapBuilder,
      ),
      _PoolPage(
        reviewStatus: widget.reviewStatus,
        registration: widget.registration,
      ),
      _MoneyPage(driverId: widget.driverId),
      const _ChatsPage(),
      _ProfilePage(
        driverName: widget.driverName,
        reviewStatus: widget.reviewStatus,
        registration: widget.registration,
        onSignOut: widget.onSignOut == null ? null : _signOut,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Widget shell = PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 16,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: NavigationBar(
              height: 72,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: _index,
              onDestinationSelected: (int value) =>
                  setState(() => _index = value),
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

  bool get _approved =>
      DriverAvailabilityPolicy.canGoOnline(widget.reviewStatus);

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
                                final double mapGap = _approved
                                    ? 0
                                    : (bounds.maxHeight * 0.35)
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
                                        child: _approved
                                            ? const SizedBox.shrink()
                                            : _buildProgressCard(context),
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
  static const Duration _availabilityChangeTimeout = Duration(seconds: 20);

  DriverPresenceService? _presence;
  bool _changing = false;
  bool? _requestedOnline;
  bool _forcingWalletOffline = false;
  Object? _availabilityAttempt;
  DateTime? _optimisticOnlineUntil;

  DriverPresenceService get _service =>
      _presence ??= DriverPresenceService.instance;

  bool get _approved =>
      DriverAvailabilityPolicy.canGoOnline(widget.reviewStatus);

  @override
  void initState() {
    super.initState();
    _warmOnlineDependencies();
  }

  @override
  void didUpdateWidget(covariant _DriverAvailabilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverId != widget.driverId ||
        oldWidget.reviewStatus != widget.reviewStatus) {
      _warmOnlineDependencies();
    }
  }

  void _warmOnlineDependencies() {
    // Widget and golden tests intentionally render this card without starting
    // Firebase. Production initializes Firebase before DriverShell is built.
    if (Firebase.apps.isEmpty) return;
    unawaited(
      _service
          .warmUp(
            driverId: widget.driverId,
            reviewStatus: widget.reviewStatus,
          )
          .catchError((Object _) {}),
    );
  }

  Future<void> _setOnline(bool online) async {
    if (_changing) {
      if (!online && _requestedOnline == true) {
        await _cancelPendingOnlineAttempt();
      }
      return;
    }

    final Object attempt = Object();
    _availabilityAttempt = attempt;
    setState(() {
      _changing = true;
      _requestedOnline = online;
    });
    try {
      if (online) {
        // The live wallet snapshot already gates this control and the backend
        // validates the wallet again before dispatch. Avoid a second callable
        // round trip here so Online becomes visible immediately.
        await _service
            .goOnline(
              driverId: widget.driverId,
              reviewStatus: widget.reviewStatus,
              vehicleType: widget.vehicleType,
            )
            .timeout(_availabilityChangeTimeout);
        _optimisticOnlineUntil = DateTime.now().add(
          const Duration(seconds: 12),
        );
      } else {
        _optimisticOnlineUntil = null;
        await _service.goOffline().timeout(_availabilityChangeTimeout);
      }
    } on TimeoutException {
      unawaited(_service.goOffline().catchError((Object _) {}));
      _showMessage(
        'Alpha Plus could not confirm your availability. Check your connection and try again.',
      );
    } on DriverWalletException catch (error) {
      unawaited(_service.goOffline().catchError((Object _) {}));
      _showMessage(error.message);
    } on DriverPresenceException catch (error) {
      _showMessage(error.message);
    } on Object {
      _showMessage(
        'Alpha Plus could not update your availability. Check your connection and try again.',
      );
    } finally {
      if (mounted && identical(_availabilityAttempt, attempt)) {
        setState(() {
          _changing = false;
          _requestedOnline = null;
        });
      }
    }
  }

  Future<void> _cancelPendingOnlineAttempt() async {
    final Object cancellation = Object();
    _availabilityAttempt = cancellation;
    setState(() {
      _changing = true;
      _requestedOnline = false;
    });

    try {
      await _service.goOffline().timeout(_availabilityChangeTimeout);
    } on Object {
      _showMessage(
        'Alpha Plus could not finish going offline. Check your connection and try again.',
      );
    } finally {
      if (mounted && identical(_availabilityAttempt, cancellation)) {
        setState(() {
          _changing = false;
          _requestedOnline = null;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _forceOfflineIfNeeded({
    required bool isOnline,
    required bool walletLoaded,
    required DriverWallet wallet,
  }) {
    if (!DriverAvailabilityPolicy.shouldForceWalletOffline(
          isOnline: isOnline,
          walletLoaded: walletLoaded,
          walletCanGoOnline: wallet.canGoOnline,
        ) ||
        _forcingWalletOffline) {
      return;
    }
    _forcingWalletOffline = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _service.goOffline().whenComplete(() {
          _forcingWalletOffline = false;
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (DriverActiveRideScope.isActive(context)) {
      return const SizedBox.shrink(
        key: Key('driverAvailabilityHiddenDuringActiveRide'),
      );
    }

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

    return StreamBuilder<DriverWallet>(
      stream: DriverWalletService.instance.watchWallet(widget.driverId),
      builder: (
        BuildContext context,
        AsyncSnapshot<DriverWallet> walletSnapshot,
      ) {
        final DriverWallet wallet =
            walletSnapshot.data ?? const DriverWallet.empty();
        final bool walletLoaded = walletSnapshot.hasData;

        return StreamBuilder<bool>(
          stream: _service.watchOnlineState(widget.driverId),
          initialData: false,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            final bool isOnline = snapshot.data ?? false;
            if (isOnline) _optimisticOnlineUntil = null;
            _forceOfflineIfNeeded(
              isOnline: isOnline,
              walletLoaded: walletLoaded,
              wallet: wallet,
            );
            final bool optimisticOnline = _optimisticOnlineUntil != null &&
                DateTime.now().isBefore(_optimisticOnlineUntil!);
            final bool displayOnline = isOnline || optimisticOnline ||
                (_changing && _requestedOnline == true);
            final String vehicleLabel = widget.vehicleType
                .trim()
                .split(RegExp(r'[_\s-]+'))
                .where((String word) => word.isNotEmpty)
                .map(
                  (String word) =>
                      '${word[0].toUpperCase()}${word.substring(1)}',
                )
                .join(' ');
            final String offlineMessage = !walletLoaded
                ? 'Checking your wallet balance…'
                : wallet.isSuspended
                ? 'Wallet suspended — contact the Alpha office'
                : wallet.balance <= 0
                ? 'Recharge your wallet at the Alpha office to work'
                : wallet.isLowBalance
                ? 'Low wallet balance — recharge soon'
                : 'Go online when you are ready to drive';

            return _AvailabilitySurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: displayOnline
                              ? AppColors.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          displayOnline
                              ? Icons.navigation_rounded
                              : Icons.power_settings_new_rounded,
                          color: displayOnline
                              ? AppColors.ink
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _changing
                                  ? _requestedOnline == true
                                      ? 'Going online…'
                                      : 'Going offline…'
                                  : displayOnline
                                  ? 'You are online'
                                  : 'You are offline',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayOnline
                                  ? 'Visible to nearby passengers now'
                                  : offlineMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        key: const Key('driverOnlineSwitch'),
                        value: displayOnline,
                        onChanged:
                            DriverAvailabilityPolicy.canChangeOnlineSwitch(
                              walletLoaded: walletLoaded,
                              walletCanGoOnline: wallet.canGoOnline,
                              changing: _changing,
                              requestedOnline: _requestedOnline,
                            )
                            ? _setOnline
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.directions_car_filled_rounded,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              vehicleLabel.isEmpty ? 'Vehicle' : vehicleLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: displayOnline
                              ? AppColors.primary
                              : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: displayOnline
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 9,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        displayOnline ? 'LIVE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: displayOnline
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
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

class _DriverMapState extends State<_DriverMap>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _supportsGoogleMap) {
      unawaited(_locateDriver(requestPermission: false));
    }
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
    return DriverPoolPage(
      reviewStatus: reviewStatus,
      registration: registration,
    );
  }
}

class _MoneyPage extends StatelessWidget {
  const _MoneyPage({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    return DriverMoneyPage(driverId: driverId);
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
