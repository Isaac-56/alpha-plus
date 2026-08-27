import 'package:flutter/material.dart';

import '../../../core/widgets/onboarding_scaffold.dart';
import '../data/driver_legal_content.dart';

class DriverLegalDetailsScreen extends StatelessWidget {
  const DriverLegalDetailsScreen({required this.document, super.key});

  final DriverLegalDocument document;

  @override
  Widget build(BuildContext context) {
    final bool showService = document == DriverLegalDocument.overview ||
        document == DriverLegalDocument.service;
    final bool showPrivacy = document == DriverLegalDocument.overview ||
        document == DriverLegalDocument.privacy;
    return OnboardingScaffold(
      authStyle: true,
      centerHeader: true,
      title: DriverLegalContent.title(document),
      subtitle: document == DriverLegalDocument.updates
          ? 'An optional preference for your driver account.'
          : 'Read the onboarding information at your own pace.',
      showBackButton: Navigator.of(context).canPop(),
      bottom: ElevatedButton(
        key: const Key('closeLegalDetails'),
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text('Done'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showService)
            const _LegalSummarySection(
              title: 'Driver service guidelines',
              body: DriverLegalContent.serviceSummary,
            ),
          if (showService && showPrivacy) const SizedBox(height: 24),
          if (showPrivacy)
            const _LegalSummarySection(
              title: 'Your information',
              body: DriverLegalContent.privacySummary,
            ),
          if (document == DriverLegalDocument.updates)
            const _LegalSummarySection(
              title: 'Your choice',
              body: DriverLegalContent.updatesSummary,
            ),
          const SizedBox(height: 28),
          Container(
            key: const Key('legalSummaryNotice'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              DriverLegalContent.summaryNotice,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSummarySection extends StatelessWidget {
  const _LegalSummarySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        SelectableText(
          body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}
