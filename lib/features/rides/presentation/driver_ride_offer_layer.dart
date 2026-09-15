import 'package:flutter/material.dart';

import '../data/driver_active_ride_service.dart';
import '../data/driver_ride_offer_service.dart';
import 'driver_active_ride_layer.dart';
import 'driver_ride_offer_layer_base.dart' as offer_layer;

class DriverRideOfferLayer extends StatelessWidget {
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

  DriverActiveRideService get _activeRides =>
      activeRideService ?? DriverActiveRideService.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _activeRides.watchActiveRideId(driverId),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        if (!snapshot.hasError && snapshot.data != null) {
          return DriverActiveRideLayer(
            driverId: driverId,
            service: activeRideService,
            child: child,
          );
        }

        return offer_layer.DriverRideOfferLayer(
          driverId: driverId,
          service: service,
          child: child,
        );
      },
    );
  }
}
