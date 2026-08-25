import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _frontImage;
  XFile? _backImage;
  bool _isPicking = false;

  Future<void> _capture(String side) async {
    if (_isPicking) {
      return;
    }

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
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
                  onPressed: () =>
                      Navigator.of(context).pop(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Open camera'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from gallery'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    setState(() => _isPicking = true);

    try {
      final XFile? selectedImage = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 88,
        maxWidth: 2400,
        maxHeight: 2400,
        requestFullMetadata: false,
      );

      if (selectedImage == null || !mounted) {
        return;
      }

      setState(() {
        if (side == 'front') {
          _frontImage = selectedImage;
        } else {
          _backImage = selectedImage;
        }
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      final String message = switch (error.code) {
        'camera_access_denied' =>
          'Camera access is disabled. Allow it in device settings and try again.',
        'photo_access_denied' =>
          'Photo access is disabled. Allow it in device settings and try again.',
        _ => 'The image could not be opened. Please try again.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The image could not be opened. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
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
                      imagePath: _frontImage?.path,
                      enabled: !_isPicking,
                      onTap: () => _capture('front'),
                    ),
                    const SizedBox(height: 12),
                    _DocumentTile(
                      title: 'Back of driver’s licence',
                      imagePath: _backImage?.path,
                      enabled: !_isPicking,
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
                onPressed:
                    _frontImage != null && _backImage != null && !_isPicking
                    ? _continue
                    : null,
                child: _isPicking
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Submit for verification'),
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
    required this.imagePath,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String? imagePath;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool complete = imagePath != null;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: complete
                    ? Stack(
                        key: ValueKey<String>(imagePath!),
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(imagePath!),
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const _DocumentIcon(
                                complete: true,
                              ),
                            ),
                          ),
                          const Positioned(
                            right: -5,
                            bottom: -5,
                            child: CircleAvatar(
                              radius: 11,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const _DocumentIcon(
                        key: ValueKey<String>('empty'),
                        complete: false,
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

class _DocumentIcon extends StatelessWidget {
  const _DocumentIcon({required this.complete, super.key});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: complete
            ? AppColors.primary
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        complete ? Icons.check_rounded : Icons.camera_alt_outlined,
        color: complete ? AppColors.ink : null,
      ),
    );
  }
}
