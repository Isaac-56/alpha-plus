import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../onboarding/models/driver_registration.dart';

class DriverPoolPage extends StatelessWidget {
  const DriverPoolPage({
    required this.reviewStatus,
    required this.registration,
    super.key,
  });

  final String reviewStatus;
  final DriverRegistration registration;

  bool get _approved => reviewStatus.trim().toLowerCase() == 'approved';

  @override
  Widget build(BuildContext context) {
    final bool setupReady =
        registration.serviceComplete &&
        registration.vehicleComplete &&
        registration.licenceComplete;
    final bool ready = _approved && setupReady;

    return SafeArea(
      child: ListView(
        key: const Key('driverPoolPage'),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: <Widget>[
          Text(
            'Order pool',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Live ride-request readiness and dispatch status.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _PoolStatusCard(ready: ready, approved: _approved),
          const SizedBox(height: 14),
          _Section(
            title: 'Request readiness',
            children: <Widget>[
              _ReadinessRow(
                icon: Icons.verified_user_outlined,
                title: 'Driver account',
                value: _approved ? 'Approved' : 'Pending review',
                complete: _approved,
              ),
              _ReadinessRow(
                icon: Icons.local_taxi_outlined,
                title: 'Passenger rides',
                value: registration.serviceComplete ? 'Enabled' : 'Incomplete',
                complete: registration.serviceComplete,
              ),
              _ReadinessRow(
                icon: Icons.directions_car_outlined,
                title: 'Vehicle',
                value: registration.vehicleComplete
                    ? _vehicleLabel(registration)
                    : 'Incomplete',
                complete: registration.vehicleComplete,
              ),
              _ReadinessRow(
                icon: Icons.badge_outlined,
                title: 'Driver licence',
                value: registration.licenceComplete ? 'Submitted' : 'Incomplete',
                complete: registration.licenceComplete,
                divider: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _Section(
            title: 'How live requests work',
            children: <Widget>[
              _PoolStep(
                number: '1',
                title: 'Go online from Requests',
                body:
                    'Alpha Plus publishes your short-lived driver location only while you are online.',
              ),
              _PoolStep(
                number: '2',
                title: 'Nearby matching requests appear',
                body:
                    'Pickup, destination, vehicle category, cash fare and distance to pickup are shown before acceptance.',
              ),
              _PoolStep(
                number: '3',
                title: 'Accept one request securely',
                body:
                    'The first valid acceptance assigns the trip. Competing offers close automatically.',
              ),
              _PoolStep(
                number: '4',
                title: 'Complete the live trip stages',
                body:
                    'Start pickup, mark arrival, start the trip and complete it in order.',
                divider: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.shield_outlined, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This screen never creates sample demand. Real ride cards are shown only when the backend dispatches a genuine passenger request to this driver.',
                    style: TextStyle(height: 1.4, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _vehicleLabel(DriverRegistration registration) {
    final List<String> parts = <String>[
      registration.color.trim(),
      registration.make.trim(),
      registration.model.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.isEmpty ? registration.vehicleType : parts.join(' ');
  }
}

class _PoolStatusCard extends StatelessWidget {
  const _PoolStatusCard({required this.ready, required this.approved});

  final bool ready;
  final bool approved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ready
            ? AppColors.primary.withValues(alpha: 0.14)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ready ? AppColors.primary : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ready ? AppColors.primary : Theme.of(context).dividerColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ready ? Icons.radar_rounded : Icons.schedule_rounded,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ready
                      ? 'Ready for live requests'
                      : approved
                          ? 'Finish driver setup'
                          : 'Approval required',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ready
                      ? 'Go to Requests and switch Online to become eligible for nearby ride offers.'
                      : approved
                          ? 'Complete the remaining vehicle or licence details before taking requests.'
                          : 'Ride offers remain locked until your driver profile is approved.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.complete,
    this.divider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool complete;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 21, color: AppColors.primary),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 8),
              Icon(
                complete ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 19,
                color: complete ? AppColors.primary : Colors.grey,
              ),
            ],
          ),
        ),
        if (divider) const Divider(height: 1),
      ],
    );
  }
}

class _PoolStep extends StatelessWidget {
  const _PoolStep({
    required this.number,
    required this.title,
    required this.body,
    this.divider = true,
  });

  final String number;
  final String title;
  final String body;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.ink,
                child: Text(
                  number,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(body, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (divider) const Divider(height: 1),
      ],
    );
  }
}
