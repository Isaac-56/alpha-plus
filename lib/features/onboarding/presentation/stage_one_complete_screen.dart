import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../models/driver_registration.dart';
import 'vehicle_setup_screen.dart';

class StageOneCompleteScreen extends StatelessWidget {
  const StageOneCompleteScreen({
    required this.driverName,
    this.registration,
    this.registrationCity = 'Juba, South Sudan',
    super.key,
  });

  final String driverName;
  final DriverRegistration? registration;
  final String registrationCity;

  String get _firstName {
    final String normalized = driverName.trim();

    if (normalized.isEmpty) {
      return 'Driver';
    }

    return normalized.split(RegExp(r'\s+')).first;
  }

  String get _serviceLabel {
    switch (registration?.serviceType) {
      case DriverRegistration.ridesService:
      case null:
        return 'Passenger rides';
      default:
        return 'Passenger rides';
    }
  }

  void _continue(BuildContext context) {
    // Normal onboarding already supplies the registration created on the
    // service-selection page. The fallback keeps direct previews/tests safe.
    final DriverRegistration activeRegistration =
        registration ?? DriverRegistration();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleSetupScreen(
          driverName: driverName,
          registration: activeRegistration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: OnboardingScaffold(
        authStyle: true,
        showBackButton: false,
        centerHeader: true,
        header: const _CompletionMark(),
        title: 'Welcome, $_firstName',
        subtitle:
            'Your Alpha Plus identity is ready. Review your first service, then continue with vehicle and document registration.',
        bottom: ElevatedButton(
          key: const Key('continueToVehicleSetup'),
          onPressed: () => _continue(context),
          child: const Text('Continue to vehicle setup'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SelectionSummaryCard(
              service: _serviceLabel,
              city: registrationCity,
            ),
            const SizedBox(height: 16),
            const _NextStageCard(),
          ],
        ),
      ),
    );
  }
}

class _CompletionMark extends StatelessWidget {
  const _CompletionMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 92,
        height: 92,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.ink, size: 50),
      ),
    );
  }
}

class _SelectionSummaryCard extends StatelessWidget {
  const _SelectionSummaryCard({required this.service, required this.city});

  final String service;
  final String city;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      key: const Key('stageOneSelectionSummary'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Your starting setup',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.local_taxi_rounded,
            label: 'Service',
            value: service,
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            icon: Icons.location_on_outlined,
            label: 'City',
            value: city,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 22, color: colors.onSurface),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ],
    );
  }
}

class _NextStageCard extends StatelessWidget {
  const _NextStageCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.directions_car_filled_rounded, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Next: Vehicle and documents',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Add your vehicle details and driver’s licence for review.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}
