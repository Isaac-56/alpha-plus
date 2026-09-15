import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/driver_active_ride_service.dart';

class DriverActiveRideLayer extends StatefulWidget {
  const DriverActiveRideLayer({
    required this.driverId,
    required this.child,
    this.service,
    super.key,
  });

  final String driverId;
  final Widget child;
  final DriverActiveRideService? service;

  @override
  State<DriverActiveRideLayer> createState() => _DriverActiveRideLayerState();
}

class _DriverActiveRideLayerState extends State<DriverActiveRideLayer> {
  DriverActiveRideService? _service;
  String? _busyRideId;
  String? _errorMessage;

  DriverActiveRideService get _rides =>
      _service ??= widget.service ?? DriverActiveRideService.instance;

  Future<void> _advance(DriverActiveRide ride) async {
    final String? nextStatus = ride.nextStatus;
    if (nextStatus == null || _busyRideId != null) return;

    if (nextStatus == 'completed') {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Complete this trip?'),
            content: const Text(
              'Only complete the trip after the passenger has reached the destination.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not yet'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Complete trip'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _busyRideId = ride.rideId;
      _errorMessage = null;
    });

    try {
      await _rides.advanceRide(rideId: ride.rideId, status: nextStatus);
    } on DriverRideLifecycleException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _errorMessage =
              'The ride could not be updated. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busyRideId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _rides.watchActiveRideId(widget.driverId),
      builder: (BuildContext context, AsyncSnapshot<String?> activeSnapshot) {
        final String? rideId = activeSnapshot.data;
        if (activeSnapshot.hasError || rideId == null) return widget.child;

        return StreamBuilder<DriverActiveRide?>(
          stream: _rides.watchRide(rideId),
          builder: (
            BuildContext context,
            AsyncSnapshot<DriverActiveRide?> rideSnapshot,
          ) {
            final DriverActiveRide? ride = rideSnapshot.data;
            if (rideSnapshot.hasError || ride == null || !ride.isActive) {
              return widget.child;
            }

            final bool busy = _busyRideId == ride.rideId;
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                widget.child,
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    child: Material(
                      key: const Key('activeDriverRideCard'),
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 18,
                      shadowColor: Colors.black45,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        ride.statusLabel,
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        _rideName(ride.rideOptionId),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${ride.estimatedFare} ${ride.currencyCode}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _RideLocation(
                              icon: Icons.my_location_rounded,
                              label: 'Pickup',
                              value: ride.pickupAddress,
                            ),
                            const SizedBox(height: 10),
                            _RideLocation(
                              icon: Icons.flag_rounded,
                              label: 'Destination',
                              value: ride.destinationAddress,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ride.paymentMethod == 'cash'
                                      ? 'Cash payment'
                                      : ride.paymentMethod,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (_errorMessage != null) ...<Widget>[
                              const SizedBox(height: 10),
                              Text(
                                _errorMessage!,
                                key: const Key('activeDriverRideError'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                key: const Key('advanceDriverRide'),
                                onPressed: busy ? null : () => _advance(ride),
                                child: busy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                        ),
                                      )
                                    : Text(ride.actionLabel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _rideName(String rideOptionId) {
    return switch (rideOptionId) {
      'boda' => 'Boda',
      'rickshaw' => 'Rickshaw',
      'standard' => 'Alpha Standard',
      _ => rideOptionId,
    };
  }
}

class _RideLocation extends StatelessWidget {
  const _RideLocation({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
