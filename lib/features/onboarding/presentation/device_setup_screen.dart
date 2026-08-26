import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/data/driver_profile_repository.dart';
import '../models/driver_registration.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({
    required this.driverName,
    required this.registration,
    this.userId,
    this.profileStore,
    super.key,
  });

  final String driverName;
  final DriverRegistration registration;
  final String? userId;
  final DriverProfileStore? profileStore;

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen>
    with WidgetsBindingObserver {
  bool _overlayReady = false;
  bool _backgroundLocationReady = false;
  bool _openingSettings = false;
  late final DriverProfileStore _profileStore;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileStore = widget.profileStore ?? FirebaseDriverProfileStore();
    _refreshPermissionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionState();
    }
  }

  Future<void> _refreshPermissionState() async {
    try {
      final PermissionStatus overlayStatus =
          await Permission.systemAlertWindow.status;
      final PermissionStatus backgroundStatus =
          await Permission.locationAlways.status;

      if (!mounted) {
        return;
      }

      setState(() {
        _overlayReady = overlayStatus.isGranted;
        _backgroundLocationReady = backgroundStatus.isGranted;
      });
    } on Object {
      // Permission plugins are unavailable in widget tests and unsupported
      // desktop previews. Android devices continue through the native flow.
    }
  }

  Future<void> _explainPermission({required bool overlay}) async {
    if (_openingSettings) {
      return;
    }

    final bool? openSettings = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  overlay
                      ? Icons.picture_in_picture_alt_outlined
                      : Icons.location_on_outlined,
                  size: 42,
                ),
                const SizedBox(height: 18),
                Text(
                  overlay
                      ? 'Allow screen overlay'
                      : 'Allow background location',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  overlay
                      ? 'This lets Alpha Plus show a compact trip request while another app is open.'
                      : 'This lets Alpha Plus receive trip requests and update your position while you are online.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue to settings'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (openSettings != true || !mounted) {
      return;
    }

    setState(() => _openingSettings = true);

    try {
      if (overlay) {
        await Permission.systemAlertWindow.request();
      } else {
        PermissionStatus foregroundStatus =
            await Permission.locationWhenInUse.status;
        if (!foregroundStatus.isGranted) {
          foregroundStatus = await Permission.locationWhenInUse.request();
        }

        if (foregroundStatus.isGranted) {
          final PermissionStatus backgroundStatus = await Permission
              .locationAlways
              .request();
          if (!backgroundStatus.isGranted) {
            await openAppSettings();
          }
        } else {
          await openAppSettings();
        }
      }

      await _refreshPermissionState();

      if (!mounted) {
        return;
      }

      final bool granted = overlay ? _overlayReady : _backgroundLocationReady;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              overlay
                  ? 'Enable “Display over other apps”, then return to Alpha Plus.'
                  : 'Choose “Allow all the time” for location, then return to Alpha Plus.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                await openAppSettings();
              },
            ),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device settings could not be opened. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingSettings = false);
      }
    }
  }

  Future<void> _finish() async {
    if (_saving) {
      return;
    }

    final String? userId =
        widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = 'Your sign-in session expired. Please sign in again.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _profileStore.completeOnboarding(
        uid: userId,
        registration: widget.registration,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage =
              'We could not finish setup. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _overlayReady && _backgroundLocationReady;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _DriverBackdrop(),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filled(
                      onPressed: Navigator.of(context).pop,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.ink,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        ready ? 'Your device is ready' : 'Set up your device',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ready
                            ? 'You can now receive trip requests reliably.'
                            : 'Activate these settings so trip requests reach you while you’re online.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 22),
                      _PermissionTile(
                        title: 'Screen overlay',
                        subtitle: 'Show new trip requests over other apps',
                        complete: _overlayReady,
                        onTap: _openingSettings
                            ? null
                            : () => _explainPermission(overlay: true),
                      ),
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                      _PermissionTile(
                        title: 'Background location access',
                        subtitle:
                            'Keep your availability and position accurate',
                        complete: _backgroundLocationReady,
                        onTap: _openingSettings
                            ? null
                            : () => _explainPermission(overlay: false),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null) ...<Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      ElevatedButton(
                        onPressed: ready && !_saving ? _finish : null,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                ready ? 'Open Alpha Plus' : 'Complete setup',
                              ),
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

class _DriverBackdrop extends StatelessWidget {
  const _DriverBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFBFFFB1), AppColors.primary],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -70,
            top: 90,
            child: Icon(
              Icons.directions_car_filled_rounded,
              size: 330,
              color: AppColors.ink.withValues(alpha: 0.92),
            ),
          ),
          Positioned(
            left: 26,
            top: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'ALPHA PLUS',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'DRIVER',
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
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

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.complete,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool complete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: complete
              ? AppColors.primary
              : Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          complete ? Icons.check_rounded : Icons.circle_outlined,
          color: complete ? AppColors.ink : null,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: complete
          ? const Icon(Icons.verified_rounded, color: AppColors.primary)
          : const Icon(Icons.keyboard_arrow_right_rounded),
      onTap: onTap,
    );
  }
}
