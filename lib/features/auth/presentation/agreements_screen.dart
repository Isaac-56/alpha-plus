import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../onboarding/presentation/service_registration_screen.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({required this.driverName, super.key});

  final String driverName;

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  bool _accepted = false;
  bool _updates = true;

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ServiceRegistrationScreen(driverName: widget.driverName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Agreements',
      subtitle: 'Review how Alpha+ works before creating your driver profile.',
      bottom: ElevatedButton(
        onPressed: _accepted ? _continue : null,
        child: const Text('Accept and continue'),
      ),
      child: Column(
        children: <Widget>[
          _AgreementCard(
            icon: Icons.description_outlined,
            title: 'Driver Service Agreement',
            description:
                'The terms for receiving trip requests, completing rides, safety and account conduct.',
            value: _accepted,
            required: true,
            onChanged: (bool? value) {
              setState(() => _accepted = value ?? false);
            },
          ),
          const SizedBox(height: 14),
          _AgreementCard(
            icon: Icons.notifications_none_rounded,
            title: 'Product updates',
            description:
                'Receive useful service, safety and earning updates. You can turn these off later.',
            value: _updates,
            required: false,
            onChanged: (bool? value) {
              setState(() => _updates = value ?? false);
            },
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.lock_outline_rounded, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Your personal information is processed according to the Alpha+ Privacy Policy.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgreementCard extends StatelessWidget {
  const _AgreementCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.required,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final bool required;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: value
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (required)
                          Text(
                            'Required',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Read details'),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                checkColor: AppColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
