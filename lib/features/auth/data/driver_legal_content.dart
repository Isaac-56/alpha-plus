enum DriverLegalDocument { overview, service, privacy, updates }

/// These are onboarding summaries, not the final published legal policies.
/// Change the version when the text changes. Full policies need their own
/// publication, versioning, acceptance flow, and backend enforcement at launch.
abstract final class DriverLegalContent {
  static const String summaryVersion = 'onboarding-summary-2026-08-27-v1';

  static const String summaryNotice =
      'These are onboarding summaries. Full driver terms and privacy notices '
      'will need to be published before public launch.';

  static const String serviceSummary =
      'Use accurate account and driver information, follow local laws and '
      'safety requirements, and use Alpha Plus only for authorised transport '
      'services. Accounts may be limited when information is false, unsafe, '
      'or misused.';

  static const String privacySummary =
      'Alpha Plus uses your phone number, profile, driver documents, vehicle '
      'details, and trip-related location to verify your account, operate '
      'rides, provide safety features, and support you. Access is limited '
      'to what is needed for the service.';

  static const String updatesSummary =
      'Product news and feature announcements are optional. Leaving this '
      'option off does not prevent registration or phone verification. '
      'Your choice is saved as a product-updates preference in your driver '
      'profile; this screen does not itself send messages.';

  static String title(DriverLegalDocument document) {
    switch (document) {
      case DriverLegalDocument.overview:
        return 'User Agreement & Privacy';
      case DriverLegalDocument.service:
        return 'Driver Service Agreement';
      case DriverLegalDocument.privacy:
        return 'Privacy summary';
      case DriverLegalDocument.updates:
        return 'Product updates';
    }
  }
}
