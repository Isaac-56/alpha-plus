import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/driver_registration.dart';
import 'device_setup_screen.dart';

class DocumentSubmissionScreen extends StatefulWidget {
  const DocumentSubmissionScreen({
    required this.driverName,
    required this.registration,
    super.key,
  });

  final String driverName;
  final DriverRegistration registration;

  @override
  State<DocumentSubmissionScreen> createState() =>
      _DocumentSubmissionScreenState();
}

class _DocumentSubmissionScreenState extends State<DocumentSubmissionScreen> {
  bool _frontAdded = false;
  bool _backAdded = false;

  Future<void> _capture(String side) async {
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Add $side side',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Place the licence on a flat surface. Make sure every corner and all text are visible.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Open camera'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from gallery'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        if (side == 'front') {
          _frontAdded = true;
        } else {
          _backAdded = true;
        }
      });
    }
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceSetupScreen(
          driverName: widget.driverName,
          registration: widget.registration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    IconButton.filledTonal(
                      onPressed: Navigator.of(context).pop,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(height: 34),
                    Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.badge_outlined,
                            size: 112,
                            color: AppColors.ink,
                          ),
                          Positioned(
                            right: 22,
                            top: 20,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Submit photos of your licence',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Clear photos help us verify your driver profile quickly and securely.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 26),
                    _DocumentTile(
                      title: 'Front of driver’s licence',
                      complete: _frontAdded,
                      onTap: () => _capture('front'),
                    ),
                    const SizedBox(height: 12),
                    _DocumentTile(
                      title: 'Back of driver’s licence',
                      complete: _backAdded,
                      onTap: () => _capture('back'),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: ElevatedButton(
                onPressed: _frontAdded && _backAdded ? _continue : null,
                child: const Text('Submit for verification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.title,
    required this.complete,
    required this.onTap,
  });

  final String title;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: complete
                      ? AppColors.primary
                      : Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  complete ? Icons.check_rounded : Icons.camera_alt_outlined,
                  color: complete ? AppColors.ink : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 3),
                    Text(
                      complete ? 'Added — tap to replace' : 'Required',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
