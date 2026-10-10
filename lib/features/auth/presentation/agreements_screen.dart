import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../../onboarding/presentation/service_registration_screen.dart';
import '../data/driver_agreement_store.dart';
import '../data/driver_legal_content.dart';
import 'driver_legal_details_screen.dart';

class AgreementsScreen extends StatefulWidget {
  const AgreementsScreen({
    required this.driverName,
    this.agreementStore,
    super.key,
  });

  final String driverName;
  final DriverAgreementStore? agreementStore;

  @override
  State<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends State<AgreementsScreen> {
  final GlobalKey _errorAnchor = GlobalKey();
  bool _accepted = false;
  bool _updates = false;
  bool _submitting = false;
  String? _errorMessage;

  Future<void> _continue() async {
    if (!_accepted || _submitting) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final DriverAgreementStore store =
          widget.agreementStore ?? FirebaseDriverAgreementStore();
      await store.saveAcknowledgement(
        accepted: _accepted,
        productUpdates: _updates,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ServiceRegistrationScreen(driverName: widget.driverName),
        ),
      );
    } on DriverAgreementSessionExpired {
      _showSaveError('Your session expired. Please sign in again to continue.');
    } on Object {
      _showSaveError('We could not confirm your choices were saved. '
          'Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSaveError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? errorContext = _errorAnchor.currentContext;
      if (errorContext != null) {
        Scrollable.ensureVisible(
          errorContext,
          alignment: 1,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  void _openDetails(DriverLegalDocument document) {
    if (_submitting) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DriverLegalDetailsScreen(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: OnboardingScaffold(
        authStyle: true,
        centerHeader: true,
        showBackButton: Navigator.of(context).canPop(),
        header: const AuthHeaderIcon(icon: Icons.fact_check_outlined),
        title: 'Agreements',
        subtitle: 'Review the driver guidelines and choose your updates preference.',
        bottom: ElevatedButton(
          key: const Key('continueDriverAgreements'),
          onPressed: _accepted && !_submitting ? _continue : null,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Text('Continue'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _AgreementChoiceCard(
              title: 'Driver Service Agreement',
              requirement: 'Required acknowledgement',
              description: 'I have read the driver service and privacy summaries.',
              checkboxKey: const Key('driverAgreementCheckbox'),
              value: _accepted,
              onChanged: _submitting
                  ? null
                  : (bool? value) {
                      setState(() {
                        _accepted = value ?? false;
                        _errorMessage = null;
                      });
                    },
              actions: <Widget>[
                TextButton(
                  key: const Key('readDriverAgreement'),
                  onPressed: _submitting
                      ? null
                      : () => _openDetails(DriverLegalDocument.service),
                  child: const Text('Read agreement'),
                ),
                TextButton(
                  key: const Key('readDriverPrivacy'),
                  onPressed: _submitting
                      ? null
                      : () => _openDetails(DriverLegalDocument.privacy),
                  child: const Text('Privacy summary'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _AgreementChoiceCard(
              title: 'Product updates',
              requirement: 'Optional',
              description: 'I would like product news and feature announcements.',
              checkboxKey: const Key('driverUpdatesCheckbox'),
              value: _updates,
              onChanged: _submitting
                  ? null
                  : (bool? value) => setState(() => _updates = value ?? false),
              actions: <Widget>[
                TextButton(
                  key: const Key('readDriverUpdates'),
                  onPressed: _submitting
                      ? null
                      : () => _openDetails(DriverLegalDocument.updates),
                  child: const Text('About updates'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              DriverLegalContent.summaryNotice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 16),
              Semantics(
                key: _errorAnchor,
                liveRegion: true,
                child: Container(
                  key: const Key('driverAgreementError'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgreementChoiceCard extends StatelessWidget {
  const _AgreementChoiceCard({
    required this.title,
    required this.requirement,
    required this.description,
    required this.checkboxKey,
    required this.value,
    required this.onChanged,
    required this.actions,
  });

  final String title;
  final String requirement;
  final String description;
  final Key checkboxKey;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? AppColors.primary : colors.outlineVariant,
          width: value ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                key: checkboxKey,
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                checkColor: AppColors.ink,
                semanticLabel: '$title. $requirement. $description',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      requirement,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: actions),
        ],
      ),
    );
  }
}
