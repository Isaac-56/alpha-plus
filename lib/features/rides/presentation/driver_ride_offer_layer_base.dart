import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/notification_alerts.dart';
import '../../../core/widgets/alpha_components.dart';
import '../data/driver_ride_offer_service.dart';

class DriverRideOfferLayer extends StatefulWidget {
  const DriverRideOfferLayer({
    required this.driverId,
    required this.child,
    this.service,
    this.enabled = true,
    super.key,
  });

  final String driverId;
  final Widget child;
  final bool enabled;
  final DriverRideOfferService? service;

  @override
  State<DriverRideOfferLayer> createState() => _DriverRideOfferLayerState();
}

class _DriverRideOfferLayerState extends State<DriverRideOfferLayer> {
  DriverRideOfferService? _service;
  String? _busyRideId;
  String? _errorMessage;
  late Stream<List<DriverRideOffer>> _pendingOffers;
  Timer? _expiryTimer;
  String? _scheduledExpiry;
  final Set<String> _expiredVersions = <String>{};

  String _offerVersion(DriverRideOffer offer) =>
      '${offer.rideId}:${offer.expiresAt.millisecondsSinceEpoch}';

  void _scheduleExpiry(DriverRideOffer? offer) {
    final String? version = offer == null ? null : _offerVersion(offer);
    if (_scheduledExpiry == version) return;
    _expiryTimer?.cancel();
    _scheduledExpiry = version;
    if (offer == null) return;
    _expiryTimer = Timer(offer.expiresAt.difference(DateTime.now()), () {
      if (!mounted) return;
      setState(() {
        _expiredVersions.add(version!);
        _scheduledExpiry = null;
        _errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pendingOffers = _offers.watchPendingOffers(widget.driverId);
  }

  @override
  void didUpdateWidget(covariant DriverRideOfferLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _busyRideId = null;
      _errorMessage = null;
    }
    if (oldWidget.driverId != widget.driverId ||
        oldWidget.service != widget.service) {
      _service = widget.service;
      _pendingOffers = _offers.watchPendingOffers(widget.driverId);
    }
  }

  DriverRideOfferService get _offers =>
      _service ??= widget.service ?? DriverRideOfferService.instance;

  Future<void> _respond({
    required DriverRideOffer offer,
    required bool accept,
  }) async {
    if (_busyRideId == offer.rideId) return;
    if (!offer.isPendingAt(DateTime.now())) {
      setState(() => _expiredVersions.add(_offerVersion(offer)));
      return;
    }

    setState(() {
      _busyRideId = offer.rideId;
      _errorMessage = null;
    });

    try {
      if (accept) {
        await _offers.acceptRide(
          offer.rideId,
          dispatchRound: offer.dispatchRound,
        );
      } else {
        await _offers.rejectRide(
          offer.rideId,
          dispatchRound: offer.dispatchRound,
        );
      }

      if (!mounted || _busyRideId != offer.rideId) return;
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
      if (mounted && _busyRideId == offer.rideId) {
        setState(() => _errorMessage = error.message);
      }
    } on Object {
      if (mounted && _busyRideId == offer.rideId) {
        setState(
          () => _errorMessage = 'The ride request could not be updated. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted && _busyRideId == offer.rideId) {
        setState(() => _busyRideId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DriverRideOffer>>(
      stream: _pendingOffers,
      initialData: const <DriverRideOffer>[],
      builder: (BuildContext context, AsyncSnapshot<List<DriverRideOffer>> snapshot) {
        final List<DriverRideOffer> received =
            snapshot.data ?? const <DriverRideOffer>[];
        final Set<String> versions = received.map(_offerVersion).toSet();
        _expiredVersions.removeWhere(
          (String version) => !versions.contains(version),
        );
        final List<DriverRideOffer> offers = received
            .where(
              (DriverRideOffer offer) =>
                  widget.enabled &&
                  offer.isPendingAt(DateTime.now()) &&
                  !_expiredVersions.contains(_offerVersion(offer)),
            )
            .toList();
        _scheduleExpiry(offers.isEmpty ? null : offers.first);
        if (offers.isEmpty) {
          return Stack(fit: StackFit.expand, children: <Widget>[widget.child]);
        }

        final DriverRideOffer offer = offers.first;
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          unawaited(
            NotificationAlerts.show(
              eventId: offer.notificationEventId,
              title: 'Ride request',
              body:
                  '${offer.pickupAddress} · ${offer.estimatedFare} ${offer.currencyCode}',
              urgent: true,
            ),
          );
        }
        final bool busy = _busyRideId == offer.rideId;

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            widget.child,
            const ModalBarrier(dismissible: false, color: Color(0x66000000)),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Material(
                    key: const Key('liveRideOfferCard'),
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 18,
                    shadowColor: Colors.black45,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.sheetRadius),
                      bottom: Radius.circular(AppSpacing.cardRadius),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const AlphaSheetHandle(),
                          const SizedBox(height: 16),
                          Text(
                            'Ride request',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: <Widget>[
                              AlphaMetricChip(
                                icon: _rideIcon(offer.rideOptionId),
                                label: _rideName(offer.rideOptionId),
                              ),
                              AlphaMetricChip(
                                icon: Icons.route_rounded,
                                label:
                                    '${_distanceLabel(offer.distanceToPickupMeters)} to pickup',
                              ),
                              if (offer.isPhoneBooking)
                                const KeyedSubtree(
                                  key: Key('phoneBookingOfferBadge'),
                                  child: AlphaMetricChip(
                                    icon: Icons.phone_in_talk_rounded,
                                    label: 'Phone booking',
                                  ),
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
                              Flexible(
                                child: Text(
                                  offer.paymentMethod == 'cash'
                                      ? 'Cash payment'
                                      : offer.paymentMethod,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                  child: const Text(
                                    'Decline',
                                    textAlign: TextAlign.center,
                                  ),
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
                                      : const Text(
                                          'Accept',
                                          textAlign: TextAlign.center,
                                        ),
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
