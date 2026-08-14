import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import 'agreements_screen.dart';

class BiometricOptInScreen extends StatelessWidget {
  const BiometricOptInScreen({required this.driverName, super.key});

  final String driverName;

  void _continue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgreementsScreen(driverName: driverName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Sign in faster',
      subtitle:
          'Use your fingerprint or face unlock for quick access to Alpha +.',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ElevatedButton.icon(
            onPressed: () => _continue(context),
            icon: const Icon(Icons.fingerprint_rounded),
            label: const Text('Enable quick login'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _continue(context),
            child: const Text('Not now'),
          ),
        ],
      ),
      child: Column(
        children: const <Widget>[
          _BenefitTile(
            icon: Icons.bolt_rounded,
            title: 'Quick and easy',
            subtitle: 'Open your driver account without entering another code.',
          ),
          _BenefitTile(
            icon: Icons.shield_outlined,
            title: 'Protected on your device',
            subtitle: 'Alpha + never receives your fingerprint or face data.',
          ),
          _BenefitTile(
            icon: Icons.lock_person_outlined,
            title: 'You stay in control',
            subtitle: 'You can disable quick login from Settings at any time.',
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
