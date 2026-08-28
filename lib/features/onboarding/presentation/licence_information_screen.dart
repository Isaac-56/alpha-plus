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
  final TextEditingController _issueDateController = TextEditingController();

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
      _issueDateController.text = registration.licenceIssueDate;
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
    _issueDateController.dispose();
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

  DateTime? _existingIssueDate() {
    final String value = _issueDateController.text.trim();

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

  Future<void> _pickIssueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? restoredDate = _existingIssueDate();

    DateTime initialDate = restoredDate ?? DateTime(now.year - 2);

    if (initialDate.isAfter(now)) {
      initialDate = now;
    }

    if (initialDate.isBefore(DateTime(1980))) {
      initialDate = DateTime(1980);
    }

    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(1980),
      lastDate: now,
      initialDate: initialDate,
      helpText: 'Licence issue date',
    );

    if (date == null || !mounted) {
      return;
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    setState(() {
      _issueDateController.text = '$day/$month/${date.year}';
    });
  }

  void _continue() {
    widget.registration
      ..licenceFirstName = _firstNameController.text.trim()
      ..licenceLastName = _lastNameController.text.trim()
      ..licenceNumber = _numberController.text.trim().toUpperCase()
      ..licenceIssueDate = _issueDateController.text.trim();

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
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _LicenceField(
            key: const Key('licenceLastNameField'),
            controller: _lastNameController,
            label: 'Last name',
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _LicenceField(
            key: const Key('licenceNumberField'),
            controller: _numberController,
            label: 'Driver’s licence number',
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('licenceIssueDateField'),
            controller: _issueDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Issue date',
              hintText: 'DD/MM/YYYY',
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              suffixIcon: _issueDateController.text.isEmpty
                  ? const Icon(Icons.keyboard_arrow_right_rounded)
                  : const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    ),
            ),
            onTap: _pickIssueDate,
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
    required this.textCapitalization,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final TextCapitalization textCapitalization;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.cancel_rounded),
              ),
      ),
      onChanged: onChanged,
    );
  }
}
