import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../models/driver_registration.dart';
import '../services/document_quality_analyzer.dart';
import '../services/driver_document_uploader.dart';
import 'device_setup_screen.dart';

enum _DocumentSide { front, back }

extension on _DocumentSide {
  String get label => this == _DocumentSide.front ? 'front' : 'back';

  String get title => this == _DocumentSide.front
      ? 'Front of driver’s licence'
      : 'Back of driver’s licence';
}

class DocumentSubmissionScreen extends StatefulWidget {
  const DocumentSubmissionScreen({
    required this.driverName,
    required this.registration,
    this.qualityAnalyzer,
    this.documentUploader,
    this.driverId,
    super.key,
  });

  final String driverName;
  final DriverRegistration registration;
  final DocumentQualityAnalyzer? qualityAnalyzer;
  final DriverDocumentUploader? documentUploader;
  final String? driverId;

  @override
  State<DocumentSubmissionScreen> createState() =>
      _DocumentSubmissionScreenState();
}

class _DocumentSubmissionScreenState extends State<DocumentSubmissionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late final DocumentQualityAnalyzer _qualityAnalyzer;
  late final DriverDocumentUploader _documentUploader;

  XFile? _frontImage;
  XFile? _backImage;
  DocumentQualityResult? _frontQuality;
  DocumentQualityResult? _backQuality;
  _DocumentSide? _checkingSide;
  bool _isPicking = false;
  bool _isUploading = false;

  bool get _isBusy => _isPicking || _checkingSide != null || _isUploading;

  bool get _readyToSubmit =>
      _frontImage != null &&
      _backImage != null &&
      _frontQuality?.accepted == true &&
      _backQuality?.accepted == true &&
      !_isBusy;

  @override
  void initState() {
    super.initState();
    _qualityAnalyzer =
        widget.qualityAnalyzer ?? const LocalDocumentQualityAnalyzer();
    _documentUploader =
        widget.documentUploader ?? FirebaseDriverDocumentUploader();
  }

  Future<void> _capture(_DocumentSide side) async {
    if (_isBusy) {
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
                  'Add ${side.label} side',
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
    XFile? selectedImage;

    try {
      selectedImage = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 2600,
        maxHeight: 2600,
        requestFullMetadata: false,
      );
    } on PlatformException catch (error) {
      if (mounted) {
        _showPickerError(error);
      }
    } on Object {
      if (mounted) {
        _showMessage('The image could not be opened. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }

    if (selectedImage == null || !mounted) {
      return;
    }

    setState(() => _checkingSide = side);
    final DocumentQualityResult result = await _qualityAnalyzer.analyze(
      selectedImage.path,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _checkingSide = null;
      if (result.accepted) {
        if (side == _DocumentSide.front) {
          _frontImage = selectedImage;
          _frontQuality = result;
        } else {
          _backImage = selectedImage;
          _backQuality = result;
        }
      }
    });

    if (result.accepted) {
      HapticFeedback.mediumImpact();
      _showMessage('${side.title} passed the automatic quality check.');
    } else {
      await _showQualityIssues(side, result.issues);
    }
  }

  void _showPickerError(PlatformException error) {
    final String message = switch (error.code) {
      'camera_access_denied' =>
        'Camera access is disabled. Allow it in device settings and try again.',
      'photo_access_denied' =>
        'Photo access is disabled. Allow it in device settings and try again.',
      _ => 'The image could not be opened. Please try again.',
    };
    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showQualityIssues(_DocumentSide side, List<String> issues) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Retake the ${side.label} photo',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...issues.map(
                  (String issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: CircleAvatar(
                            radius: 3,
                            backgroundColor: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            issue,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_readyToSubmit) {
      return;
    }

    final String? driverId =
        widget.driverId ?? FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null || driverId.isEmpty) {
      _showMessage('Your session expired. Sign in again before uploading.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _documentUploader.uploadLicence(
        driverId: driverId,
        frontImagePath: _frontImage!.path,
        backImagePath: _backImage!.path,
      );

      if (!mounted) {
        return;
      }

      HapticFeedback.mediumImpact();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DeviceSetupScreen(
            driverName: widget.driverName,
            registration: widget.registration,
            userId: driverId,
          ),
        ),
      );
    } on Object {
      if (mounted) {
        _showMessage(
          'The verified photos could not be uploaded. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
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
                      onPressed: _isBusy ? null : Navigator.of(context).pop,
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
                              Icons.document_scanner_outlined,
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
                    const SizedBox(height: 20),
                    const _AutomaticCheckCard(),
                    const SizedBox(height: 18),
                    _DocumentTile(
                      title: _DocumentSide.front.title,
                      imagePath: _frontImage?.path,
                      qualityPassed: _frontQuality?.accepted == true,
                      isChecking: _checkingSide == _DocumentSide.front,
                      enabled: !_isBusy,
                      onTap: () => _capture(_DocumentSide.front),
                    ),
                    const SizedBox(height: 12),
                    _DocumentTile(
                      title: _DocumentSide.back.title,
                      imagePath: _backImage?.path,
                      qualityPassed: _backQuality?.accepted == true,
                      isChecking: _checkingSide == _DocumentSide.back,
                      enabled: !_isBusy,
                      onTap: () => _capture(_DocumentSide.back),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: ElevatedButton(
                onPressed: _readyToSubmit ? _submit : null,
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox.square(
                            dimension: 21,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading securely…'),
                        ],
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

class _AutomaticCheckCard extends StatelessWidget {
  const _AutomaticCheckCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.auto_awesome_rounded, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Automatic photo check',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Before upload, Alpha Plus checks resolution, lighting, contrast, and blur. Final document approval remains under review.',
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

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.title,
    required this.imagePath,
    required this.qualityPassed,
    required this.isChecking,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String? imagePath;
  final bool qualityPassed;
  final bool isChecking;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool complete = imagePath != null && qualityPassed;
    final String status = isChecking
        ? 'Checking lighting and sharpness…'
        : complete
        ? 'Quality passed — tap to replace'
        : 'Required';

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
                child: isChecking
                    ? const _CheckingIcon(key: ValueKey<String>('checking'))
                    : complete
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
                              errorBuilder: (_, _, _) =>
                                  const _DocumentIcon(complete: true),
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
                    Text(status, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (!isChecking) const Icon(Icons.keyboard_arrow_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckingIcon extends StatelessWidget {
  const _CheckingIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const SizedBox.square(
        dimension: 23,
        child: CircularProgressIndicator(strokeWidth: 2.6),
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
