import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/driver_ride_offer_service.dart';

class DriverRideOfferLayer extends StatefulWidget {
  const DriverRideOfferLayer({
    required this.driverId,
    required this.child,
    this.service,
    super.key,
  });

  final String driverId;
  final Widget child;
  final DriverRideOfferService? service;

  @override
  State<DriverRideOfferLayer> createState() => _DriverRideOfferLayerState();
}

class _DriverRideOfferLayerState extends State<DriverRideOfferLayer> {
  DriverRideOfferService? _service;
  String? _busyRideId;
  String? _errorMessage;

  DriverRideOfferService get _offers =>
      _service ??= widget.service ?? DriverRideOfferService.instance;

  Future<void> _respond({
    required DriverRideOffer offer,
    required bool accept,
  }) async {
    if (_busyRideId != null) return;

    setState(() {
      _busyRideId = offer.rideId;
      _errorMessage = null;
    });

    try {
      if (accept) {
        await _offers.acceptRide(offer.rideId);
      } else {
        await _offers.rejectRide(offer.rideId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Ride accepted. Preparing your trip.'
                  : 'Ride request declined.',
            ),
          ),
        );
    } on DriverRideOfferException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } on Object {
      if (mounted) {
        setState(
          () => _errorMessage =
              'The ride request could not be updated. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyRideId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DriverRideOffer>>(
      stream: _offers.watchPendingOffers(widget.driverId),
      initialData: const <DriverRideOffer>[],
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<DriverRideOffer>> snapshot,
          ) {
            final List<DriverRideOffer> offers =
                snapshot.data ?? const <DriverRideOffer>[];
            if (offers.isEmpty) return widget.child;

            final DriverRideOffer offer = offers.first;
            final bool busy = _busyRideId == offer.rideId;

            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                widget.child,
                const ModalBarrier(
                  dismissible: false,
                  color: Color(0x66000000),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Material(
                      key: const Key('liveRideOfferCard'),
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 18,
                      shadowColor: Colors.black45,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
                                    Icons.local_taxi_rounded,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'New ride request',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${_rideName(offer.rideOptionId)} • ${_distanceLabel(offer.distanceToPickupMeters)} away',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${offer.estimatedFare} ${offer.currencyCode}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _LocationLine(
                              icon: Icons.my_location_rounded,
                              label: 'Pickup',
                              value: offer.pickupAddress,
                            ),
                            const SizedBox(height: 12),
                            _LocationLine(
                              icon: Icons.flag_rounded,
                              label: 'Destination',
                              value: offer.destinationAddress,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  offer.paymentMethod == 'cash'
                                      ? 'Cash payment'
                                      : offer.paymentMethod,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (_errorMessage != null) ...<Widget>[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                key: const Key('liveRideOfferError'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    key: const Key('rejectRideOffer'),
                                    onPressed: busy
                                        ? null
                                        : () => _respond(
                                            offer: offer,
                                            accept: false,
                                          ),
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    key: const Key('acceptRideOffer'),
                                    onPressed: busy
                                        ? null
                                        : () => _respond(
                                            offer: offer,
                                            accept: true,
                                          ),
                                    child: busy
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.3,
                                            ),
                                          )
                                        : const Text('Accept'),
                                  ),
                                ),
                              ],
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
  }

  static String _rideName(String rideOptionId) {
    return switch (rideOptionId) {
      'boda' => 'Boda',
      'rickshaw' => 'Rickshaw',
      'standard' => 'Alpha Standard',
      _ => rideOptionId,
    };
  }

  static String _distanceLabel(int meters) {
    if (meters < 1000) return '$meters m';
    final double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(kilometers < 10 ? 1 : 0)} km';
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({
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
