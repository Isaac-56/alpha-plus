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

  Future<void> _toggleWaiting(DriverActiveRide ride) async {
    if (ride.status != 'in_progress' || _busyRideId != null) return;

    if (!ride.isWaiting) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Start customer waiting?'),
            content: const Text(
              'Use this only when the passenger asks you to stop. Normal traffic and red lights must not be recorded as customer waiting. The first 2 minutes are free.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start waiting'),
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
      await _rides.setCustomerWaiting(
        rideId: ride.rideId,
        isWaiting: !ride.isWaiting,
      );
    } on DriverRideLifecycleException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Waiting could not be updated. Check your connection and try again.',
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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                        ),
                        child: SingleChildScrollView(
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
                                  '${_formatAmount(ride.fareAt(DateTime.now()))} ${ride.currencyCode}',
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
                            if (ride.status == 'in_progress') ...<Widget>[
                              const SizedBox(height: 12),
                              _DriverWaitingStatus(ride: ride),
                            ],
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
                            if (ride.status == 'in_progress') ...<Widget>[
                              SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  key: const Key('toggleCustomerWaiting'),
                                  onPressed:
                                      busy ? null : () => _toggleWaiting(ride),
                                  icon: Icon(
                                    ride.isWaiting
                                        ? Icons.play_arrow_rounded
                                        : Icons.timer_outlined,
                                  ),
                                  label: Text(
                                    ride.isWaiting
                                        ? 'End wait and resume'
                                        : 'Start customer wait',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
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

  static String _formatAmount(int amount) {
    final String digits = amount.abs().toString();
    final StringBuffer formatted = StringBuffer();
    for (int index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        formatted.write(',');
      }
      formatted.write(digits[index]);
    }
    return amount < 0 ? '-$formatted' : formatted.toString();
  }
}

class _DriverWaitingStatus extends StatelessWidget {
  const _DriverWaitingStatus({required this.ride});

  final DriverActiveRide ride;

  @override
  Widget build(BuildContext context) {
    if (!ride.isWaiting) {
      return Text(
        'Customer waiting: first 2 minutes free, then ${ride.waitingRatePerMinute} ${ride.currencyCode}/min.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return StreamBuilder<int>(
      stream: Stream<int>.periodic(
        const Duration(seconds: 1),
        (int tick) => tick,
      ),
      initialData: 0,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final DateTime now = DateTime.now();
        final int totalSeconds = ride.waitingSecondsAt(now);
        final int activeSeconds = ride.waitingStartedAt == null
            ? 0
            : now
                .difference(ride.waitingStartedAt!)
                .inSeconds
                .clamp(0, 4 * 60 * 60)
                .toInt();
        final int freeRemaining =
            (ride.waitingGraceSeconds - activeSeconds)
                .clamp(0, 999999)
                .toInt();
        final int charge = ride.waitingChargeAt(now);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Waiting ${_clock(totalSeconds)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                freeRemaining > 0
                    ? '${_clock(freeRemaining)} free waiting remains'
                    : '$charge ${ride.currencyCode} waiting added so far',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  static String _clock(int totalSeconds) {
    final int safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final int minutes = safeSeconds ~/ 60;
    final int seconds = safeSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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