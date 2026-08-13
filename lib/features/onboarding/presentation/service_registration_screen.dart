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
        builder: (_) => StageOneCompleteScreen(driverName: widget.driverName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Choose how you’ll earn',
      subtitle: 'Start in Juba. You can add more approved services later.',
      bottom: ElevatedButton(
        onPressed: _continue,
        child: const Text('Continue'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: const Icon(Icons.location_city_rounded),
              title: const Text('Registration city'),
              subtitle: const Text('Juba, South Sudan'),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Choose a service',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _ServiceCard(
            selected: _selected == DriverService.rides,
            icon: Icons.local_taxi_rounded,
            title: 'Driver',
            description: 'Accept passenger trips and drive with AlphaRide.',
            badge: 'Available',
            onTap: () => setState(() => _selected = DriverService.rides),
          ),
          const SizedBox(height: 14),
          _ServiceCard(
            selected: _selected == DriverService.delivery,
            icon: Icons.delivery_dining_rounded,
            title: 'Delivery',
            description: 'Deliver parcels using a car, boda or rickshaw.',
            badge: 'Coming soon',
            enabled: false,
            onTap: () {},
          ),
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
    required this.onTap,
    this.enabled = true,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color foreground = enabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).textTheme.bodyMedium!.color!;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.62,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).dividerColor,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 30, color: foreground),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: foreground),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.18)
                                  : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (selected) ...<Widget>[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
