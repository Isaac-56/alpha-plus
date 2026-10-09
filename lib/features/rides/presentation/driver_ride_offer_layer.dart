import 'package:flutter/material.dart';

import '../data/driver_active_ride_service.dart';
import '../data/driver_ride_offer_service.dart';
import 'driver_active_ride_layer.dart';
import 'driver_ride_offer_layer_base.dart' as offer_layer;

class DriverRideOfferLayer extends StatefulWidget {
  const DriverRideOfferLayer({
    required this.driverId,
    required this.child,
    this.service,
    this.activeRideService,
    super.key,
  });

  final String driverId;
  final Widget child;
  final DriverRideOfferService? service;
  final DriverActiveRideService? activeRideService;

  @override
  State<DriverRideOfferLayer> createState() => _DriverRideOfferLayerState();
}

class _DriverRideOfferLayerState extends State<DriverRideOfferLayer> {
  late Stream<String?> _activeRideIds;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _activeRideIds =
        (widget.activeRideService ?? DriverActiveRideService.instance)
            .watchActiveRideId(widget.driverId);
  }

  @override
  void didUpdateWidget(covariant DriverRideOfferLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverId != widget.driverId ||
        oldWidget.activeRideService != widget.activeRideService) _listen();
  }

  @override
  Widget build(BuildContext context) {
    return DriverActiveRideLayer(
      driverId: widget.driverId,
      service: widget.activeRideService,
      child: StreamBuilder<String?>(
        stream: _activeRideIds,
        builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
          if (snapshot.data != null)
            return DriverActiveRideScope(child: widget.child);
          return offer_layer.DriverRideOfferLayer(
            driverId: widget.driverId,
            service: widget.service,
            child: widget.child,
          );
        },
      ),
    );
  }
}
