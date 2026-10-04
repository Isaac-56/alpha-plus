import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/alpha_components.dart';
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.sheetRadius),
                        bottom: Radius.circular(AppSpacing.cardRadius),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const AlphaSheetHandle(),
                            const SizedBox(height: 16),
                            AlphaFlowHeader(
                              title: 'New ride request',
                              subtitle:
                                  '${_distanceLabel(offer.distanceToPickupMeters)} to pickup',
                              compact: true,
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  color: AppColors.ink,
                                ),
                              ),
                              trailing: AlphaStatusPill(
                                label: _rideName(offer.rideOptionId),
                                icon: _rideIcon(offer.rideOptionId),
                              ),
                            ),
                            if (offer.isPhoneBooking) ...<Widget>[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  key: const Key('phoneBookingOfferBadge'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.phone_in_talk_rounded, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Phone booking',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                AlphaMetricChip(
                                  icon: Icons.route_rounded,
                                  label:
                                      '${_distanceLabel(offer.distanceToPickupMeters)} away',
                                  emphasized: true,
                                ),
                                AlphaMetricChip(
                                  icon: Icons.payments_outlined,
                                  label:
                                      '${offer.estimatedFare} ${offer.currencyCode}',
                                ),
                                AlphaMetricChip(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: offer.paymentMethod == 'cash'
                                      ? 'Cash'
                                      : offer.paymentMethod,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            AlphaRouteRow(
                              icon: Icons.my_location_rounded,
                              label: 'Pickup',
                              value: offer.pickupAddress,
                            ),
                            const SizedBox(height: 8),
                            AlphaRouteRow(
                              icon: Icons.flag_rounded,
                              label: 'Destination',
                              value: offer.destinationAddress,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${offer.estimatedFare} ${offer.currencyCode}',
                              key: const Key('rideOfferFare'),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 10),
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
                                        : const Text('Accept ride'),
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

  static IconData _rideIcon(String rideOptionId) => switch (rideOptionId) {
    'boda' => Icons.two_wheeler_rounded,
    'rickshaw' => Icons.electric_rickshaw_rounded,
    _ => Icons.local_taxi_rounded,
  };
}
