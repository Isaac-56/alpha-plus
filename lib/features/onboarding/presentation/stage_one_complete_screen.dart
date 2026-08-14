import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'vehicle_setup_screen.dart';

class StageOneCompleteScreen extends StatelessWidget {
  const StageOneCompleteScreen({required this.driverName, super.key});

  final String driverName;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                Container(
                  width: 128,
                  height: 128,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.ink,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome, ${driverName.split(' ').first}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 14),
                Text(
                  'Your Alpha + identity is ready. Next, we’ll add your vehicle and driver’s licence.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const Spacer(flex: 3),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.directions_car_filled_rounded),
                      SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          'Stage 2: Vehicle and document registration',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            VehicleSetupScreen(driverName: driverName),
                      ),
                    );
                  },
                  child: const Text('Continue to vehicle setup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
