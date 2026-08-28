import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import 'stage_one_complete_screen.dart';

enum DriverService { rides, delivery }

class ServiceRegistrationScreen extends StatefulWidget {
  const ServiceRegistrationScreen({required this.driverName, super.key});

  final String driverName;

  @override
  State<ServiceRegistrationScreen> createState() =>
      _ServiceRegistrationScreenState();
}

class _ServiceRegistrationScreenState extends State<ServiceRegistrationScreen> {
  DriverService _selected = DriverService.rides;

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StageOneCompleteScreen(
          driverName: widget.driverName,
          selectedServiceLabel: 'Passenger rides',
          registrationCity: 'Juba, South Sudan',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      authStyle: true,
      title: 'Choose how you’ll earn',
      subtitle:
          'Start with passenger rides in Juba. More approved services will appear here when they are ready.',
      bottom: ElevatedButton(
        key: const Key('continueServiceRegistration'),
        onPressed: _continue,
        child: const Text('Continue'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _RegistrationCityCard(),
          const SizedBox(height: 28),
          Text(
            'Choose a service',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'You can add another service later after it becomes available.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _ServiceCard(
            key: const Key('passengerRidesService'),
            selected: _selected == DriverService.rides,
            icon: Icons.local_taxi_rounded,
            title: 'Passenger rides',
            description: 'Accept trip requests and drive with Alpha Plus.',
            badge: 'Available',
            onTap: () => setState(() => _selected = DriverService.rides),
          ),
          const SizedBox(height: 14),
          const _ServiceCard(
            key: Key('deliveryService'),
            selected: false,
            icon: Icons.delivery_dining_rounded,
            title: 'Delivery',
            description: 'Parcel delivery will be added in a future update.',
            badge: 'Coming soon',
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _RegistrationCityCard extends StatelessWidget {
  const _RegistrationCityCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool stackStatus =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(16) > 20;

    final Widget details = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(Icons.location_city_rounded, color: colors.onSurface),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Registration city',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text('Juba, South Sudan', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );

    const Widget status = _StatusBadge(
      label: 'Launch city',
      icon: Icons.lock_outline_rounded,
    );

    return Container(
      key: const Key('registrationCityCard'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: stackStatus
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                details,
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerRight, child: status),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: details),
                const SizedBox(width: 16),
                status,
              ],
            ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color foreground = enabled
        ? colors.onSurface
        : colors.onSurface.withValues(alpha: 0.58);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '$title, $badge',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.62,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary.withValues(alpha: 0.06)
                    : colors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? AppColors.primary : theme.dividerColor,
                  width: selected ? 2 : 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool stackStatus =
                      constraints.maxWidth < 360 ||
                      MediaQuery.textScalerOf(context).scale(16) > 20;
                  final Widget details = _ServiceDetails(
                    icon: icon,
                    title: title,
                    description: description,
                    selected: selected,
                    foreground: foreground,
                  );
                  final Widget status = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _StatusBadge(label: badge, emphasized: selected),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  );

                  if (stackStatus) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        details,
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerRight, child: status),
                      ],
                    );
                  }

                  return Row(
                    children: <Widget>[
                      Expanded(child: details),
                      const SizedBox(width: 16),
                      status,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceDetails extends StatelessWidget {
  const _ServiceDetails({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.foreground,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.18)
                : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, size: 29, color: foreground),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, this.icon, this.emphasized = false});

  final String label;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color foreground = emphasized
        ? colors.onSurface
        : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primary.withValues(alpha: 0.16)
            : colors.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
