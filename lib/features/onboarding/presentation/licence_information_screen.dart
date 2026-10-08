import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../models/driver_registration.dart';
import '../services/driver_document_uploader.dart';
import 'document_submission_screen.dart';
import 'registration_option_screen.dart';

class LicenceInformationScreen extends StatefulWidget {
  const LicenceInformationScreen({
    required this.driverName,
    required this.registration,
    this.documentUploader,
    super.key,
  });

  final String driverName;
  final DriverRegistration registration;
  final DriverDocumentUploader? documentUploader;

  @override
  State<LicenceInformationScreen> createState() =>
      _LicenceInformationScreenState();
}

class _LicenceInformationScreenState extends State<LicenceInformationScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final DriverRegistration registration = widget.registration;

    final bool hasSavedLicenceData =
        registration.licenceFirstName.trim().isNotEmpty ||
        registration.licenceLastName.trim().isNotEmpty ||
        registration.licenceNumber.trim().isNotEmpty ||
        registration.licenceIssueDate.trim().isNotEmpty;

    if (hasSavedLicenceData) {
      // Restore exactly what the driver already entered if this registration
      // object is returning to the licence step.
      _firstNameController.text = registration.licenceFirstName;
      _lastNameController.text = registration.licenceLastName;
      _numberController.text = registration.licenceNumber;
      _expiryDateController.text = registration.licenceExpiryDate;
    } else {
      // First visit: seed the driver's verified profile name to reduce typing.
      final List<String> names = widget.driverName
          .trim()
          .split(RegExp(r'\s+'))
          .where((String value) => value.isNotEmpty)
          .toList();

      _firstNameController.text = names.isEmpty ? '' : names.first;
      _lastNameController.text = names.length > 1
          ? names.sublist(1).join(' ')
          : '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _numberController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final String? country = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => RegistrationOptionScreen(
          title: 'Country of issue',
          selected: widget.registration.licenceCountry,
          options: const <String>[
            'South Sudan',
            'Uganda',
            'Kenya',
            'Ethiopia',
            'Sudan',
            'Other',
          ],
        ),
      ),
    );

    if (country != null && mounted) {
      setState(() {
        widget.registration.licenceCountry = country;
      });
    }
  }

  DateTime? _existingExpiryDate() {
    final String value = _expiryDateController.text.trim();

    if (value.isEmpty) {
      return null;
    }

    // Current Alpha Plus display format: DD/MM/YYYY.
    final List<String> displayParts = value.split('/');

    if (displayParts.length == 3) {
      final int? day = int.tryParse(displayParts[0]);
      final int? month = int.tryParse(displayParts[1]);
      final int? year = int.tryParse(displayParts[2]);

      if (day != null && month != null && year != null) {
        try {
          final DateTime date = DateTime(year, month, day);

          if (date.year == year && date.month == month && date.day == day) {
            return date;
          }
        } on Object {
          // Fall through to the legacy ISO parser below.
        }
      }
    }

    // Older/testing data may contain YYYY-MM-DD.
    return DateTime.tryParse(value);
  }

  Future<void> _pickExpiryDate() async {
    final DateTime now = DateTime.now();
    final DateTime? restoredDate = _existingExpiryDate();

    DateTime initialDate = restoredDate ?? DateTime(now.year + 2);

    if (initialDate.isBefore(DateTime(now.year, now.month, now.day))) {
      initialDate = DateTime(now.year, now.month, now.day);
    }

    final DateTime lastDate = DateTime(now.year + 15, 12, 31);
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: lastDate,
      initialDate: initialDate,
      helpText: 'Licence expiry date',
    );

    if (date == null || !mounted) {
      return;
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    setState(() {
      _expiryDateController.text = '$day/$month/${date.year}';
    });
  }

  void _continue() {
    widget.registration
      ..licenceFirstName = _firstNameController.text.trim()
      ..licenceLastName = _lastNameController.text.trim()
      ..licenceNumber = _numberController.text.trim().toUpperCase()
      ..licenceExpiryDate = _expiryDateController.text.trim();

    if (!widget.registration.licenceComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete every licence detail first.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentSubmissionScreen(
          driverName: widget.driverName,
          registration: widget.registration,
          documentUploader: widget.documentUploader,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Driver’s licence information',
      subtitle: 'Enter the details exactly as they appear on your licence.',
      bottom: ElevatedButton(
        key: const Key('continueLicenceInformation'),
        onPressed: _continue,
        child: const Text('Continue'),
      ),
      child: Column(
        children: <Widget>[
          Material(
            key: const Key('licenceCountrySelector'),
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 7,
              ),
              leading: const Icon(Icons.public_rounded),
              title: Text(
                'Country of issue',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                widget.registration.licenceCountry,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: _pickCountry,
            ),
          ),
          const SizedBox(height: 14),
          _LicenceField(
            key: const Key('licenceFirstNameField'),
            controller: _firstNameController,
            label: 'First name',
            prefixIcon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _LicenceField(
            key: const Key('licenceLastNameField'),
            controller: _lastNameController,
            label: 'Last name',
            prefixIcon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _LicenceField(
            key: const Key('licenceNumberField'),
            controller: _numberController,
            label: 'Driver’s licence number',
            prefixIcon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _FieldShell(
            label: 'Expiry date',
            child: TextField(
              key: const Key('licenceIssueDateField'),
              controller: _expiryDateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'DD/MM/YYYY',
                prefixIcon: const Icon(Icons.event_available_outlined),
                suffixIcon: _expiryDateController.text.isEmpty
                    ? const Icon(Icons.keyboard_arrow_right_rounded)
                    : const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      ),
              ),
              onTap: _pickExpiryDate,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.verified_user_outlined, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'We use this information only to verify that you are eligible to drive.',
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

class _LicenceField extends StatelessWidget {
  const _LicenceField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    required this.textCapitalization,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final TextCapitalization textCapitalization;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear $label',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.cancel_rounded),
                ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
