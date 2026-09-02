import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/alpha_back_button.dart';
import '../../auth/data/driver_legal_content.dart';
import '../../auth/presentation/driver_biometric_settings_screen.dart';
import '../../auth/presentation/driver_legal_details_screen.dart';
import '../../onboarding/models/driver_registration.dart';
import 'driver_appearance_screen.dart';
import 'driver_detail_screens.dart';

class DriverPoolPageUi extends StatelessWidget {
  const DriverPoolPageUi({
    required this.reviewStatus,
    required this.registration,
    super.key,
  });

  final String reviewStatus;
  final DriverRegistration registration;

  bool get _approved => reviewStatus.trim().toLowerCase() == 'approved';

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Order pool',
      subtitle:
          'Incoming ride requests will appear here when live dispatch is connected.',
      children: <Widget>[
        _HeroStatusCard(
          icon: _approved ? Icons.check_circle_rounded : Icons.schedule_rounded,
          title: _approved
              ? 'Ready for requests'
              : 'Account review in progress',
          body: _approved
              ? 'Your driver profile is approved. This page is ready for live ride offers once dispatch is enabled.'
              : 'You can review your setup now. Ride offers stay unavailable until the account is approved.',
          status: _approved ? 'Approved' : 'Under review',
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Request readiness',
          children: <Widget>[
            _StatusLine(
              icon: Icons.person_outline_rounded,
              title: 'Driver account',
              value: _approved ? 'Approved' : 'Pending review',
              complete: _approved,
            ),
            _StatusLine(
              icon: Icons.local_taxi_outlined,
              title: 'Service',
              value: registration.serviceComplete
                  ? 'Passenger rides'
                  : 'Needs attention',
              complete: registration.serviceComplete,
            ),
            _StatusLine(
              icon: Icons.directions_car_outlined,
              title: 'Vehicle',
              value: registration.vehicleComplete
                  ? _vehicleName(registration)
                  : 'Needs attention',
              complete: registration.vehicleComplete,
            ),
            _StatusLine(
              icon: Icons.badge_outlined,
              title: 'Driver licence',
              value: registration.licenceComplete
                  ? 'Submitted'
                  : 'Needs attention',
              complete: registration.licenceComplete,
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'How a request will work',
          children: const <Widget>[
            _StepLine(
              number: '1',
              title: 'A nearby request appears',
              body:
                  'Pickup, destination, service type and fare information will be shown before acceptance.',
            ),
            _StepLine(
              number: '2',
              title: 'Review before accepting',
              body:
                  'The request stays clearly separated from your current availability and profile information.',
            ),
            _StepLine(
              number: '3',
              title: 'Trip controls replace the pool',
              body:
                  'After acceptance, the page can transition to pickup, arrival, start and completion controls.',
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _InfoBanner(
          icon: Icons.shield_outlined,
          text:
              'No sample passengers, fake trips or placeholder fares are shown. Live requests will appear only after a trusted dispatch source is connected.',
        ),
      ],
    );
  }
}

class DriverMoneyPageUi extends StatelessWidget {
  const DriverMoneyPageUi({super.key});

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Money',
      subtitle:
          'Earnings, cash handling and settlement information in one place.',
      trailing: FilledButton.tonalIcon(
        onPressed: () => _push(context, const DriverHelpCenterScreen()),
        icon: const Icon(Icons.support_agent_rounded),
        label: const Text('Help'),
      ),
      children: <Widget>[
        const _HeroStatusCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Earnings not available yet',
          body:
              'Verified trip earnings and live balances will appear when completed-trip and settlement data is connected.',
          status: 'Waiting for trip data',
        ),
        const SizedBox(height: 14),

        _SectionCard(
          title: 'Payment setup',
          children: <Widget>[
            _ActionRow(
              icon: Icons.lock_outline_rounded,
              title: 'Balance limit',
              subtitle: 'Account balance and service-fee information',
              onTap: () => _push(context, const BalanceLimitScreen()),
            ),
            _ActionRow(
              icon: Icons.payments_outlined,
              title: 'Payment methods',
              subtitle: 'Cash is the launch payment method',
              onTap: () => _push(context, const PaymentInformationScreen()),
            ),
            _ActionRow(
              icon: Icons.receipt_long_outlined,
              title: 'Trip activity',
              subtitle: 'Completed-trip history',
              showDivider: false,
              onTap: () => _push(context, const DriverActivityScreen()),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _SectionCard(
          title: 'Earnings overview',
          children: <Widget>[
            Row(
              children: const <Widget>[
                Expanded(
                  child: _MetricTile(
                    label: 'Today',
                    value: '— SSP',
                    icon: Icons.today_outlined,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    label: 'This week',
                    value: '— SSP',
                    icon: Icons.calendar_view_week_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _InfoBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'Verified trip earnings are intentionally blank until a trusted completed-trip source is connected.',
            ),
          ],
        ),

        const SizedBox(height: 14),

        _SectionCard(
          title: 'Cash trip guidance',
          children: const <Widget>[
            _GuidanceRow(
              icon: Icons.price_check_outlined,
              title: 'Confirm the fare shown in the app',
              body:
                  'Do not invent a fare or replace a verified trip amount with a manual estimate.',
            ),
            _GuidanceRow(
              icon: Icons.payments_rounded,
              title: 'Collect cash only when the trip is complete',
              body:
                  'Digital payment methods remain unavailable until they are actually connected.',
            ),
            _GuidanceRow(
              icon: Icons.receipt_outlined,
              title: 'Keep verified trip records',
              body:
                  'Earnings and fees should come from completed trip records, not placeholder balances.',
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}

class DriverInboxPageUi extends StatelessWidget {
  const DriverInboxPageUi({super.key});

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Inbox',
      subtitle:
          'Service information, safety guidance and support are grouped here.',
      children: <Widget>[
        const _HeroStatusCard(
          icon: Icons.mark_email_read_outlined,
          title: 'No unread service alerts',
          body:
              'A live message feed is not connected in this UI-only phase, so Alpha Plus does not create fake unread messages.',
          status: 'All clear',
        ),
        const SizedBox(height: 18),
        Text('Quick access', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              _QuickCard(
                icon: Icons.health_and_safety_outlined,
                title: 'Safety center',
                onTap: () => _push(context, const DriverSafetyCenterScreen()),
              ),
              _QuickCard(
                icon: Icons.support_agent_outlined,
                title: 'Help center',
                onTap: () => _push(context, const DriverHelpCenterScreen()),
              ),
              _QuickCard(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => _push(context, const DriverNotificationsScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Driver information',
          children: <Widget>[
            _ActionRow(
              icon: Icons.route_outlined,
              title: 'Request readiness',
              subtitle: 'How ride requests will appear and progress',
              onTap: () => _push(
                context,
                const InformationMessageScreen(
                  title: 'Request readiness',
                  body:
                      'Ride offers should show verified pickup, destination, service and fare information before a driver accepts. No fake requests are generated in this build.',
                  icon: Icons.route_outlined,
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.car_repair_outlined,
              title: 'Vehicle readiness',
              subtitle: 'Basic checks before going online',
              onTap: () => _push(
                context,
                const InformationMessageScreen(
                  title: 'Vehicle readiness',
                  body:
                      'Before driving, confirm tyres, lights, brakes, fuel or charge level, required documents and passenger areas are ready for service.',
                  icon: Icons.car_repair_outlined,
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.newspaper_outlined,
              title: 'Product information',
              subtitle: 'Current Alpha Plus app guidance',
              showDivider: false,
              onTap: () => _push(
                context,
                const InformationMessageScreen(
                  title: 'Alpha Plus information',
                  body:
                      'This interface is prepared for driver operations. Live news, campaigns and service alerts will be shown only after a trusted source is connected.',
                  icon: Icons.newspaper_outlined,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DriverProfilePageUi extends StatelessWidget {
  const DriverProfilePageUi({
    required this.driverName,
    required this.reviewStatus,
    required this.registration,
    this.onSignOut,
    super.key,
  });

  final String driverName;
  final String reviewStatus;
  final DriverRegistration registration;
  final Future<void> Function()? onSignOut;

  String get _reviewLabel {
    return switch (reviewStatus.trim().toLowerCase()) {
      'approved' => 'Approved',
      'rejected' => 'Needs attention',
      _ => 'Under review',
    };
  }

  Future<void> _signOut(BuildContext context) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            icon: const Icon(Icons.logout_rounded),
            title: const Text('Log out of Alpha Plus?'),
            content: const Text(
              'You will need to sign in again before using your driver account on this device.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Log out'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await onSignOut?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      title: 'Profile',
      children: <Widget>[
        _ProfileHeader(
          driverName: driverName,
          reviewStatus: _reviewLabel,
          vehicle: _vehicleName(registration),
        ),
        const SizedBox(height: 14),
        _DriverServicesSummaryCard(
          reviewLabel: _reviewLabel,
          onServicesTap: () => _push(context, const DriverServicesScreen()),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Partner & payments',
          children: <Widget>[
            _ActionRow(
              icon: Icons.business_center_outlined,
              title: 'Partner',
              subtitle: 'Alpha Plus South Sudan',
              onTap: () => _push(context, const PartnerScreen()),
            ),
            _ActionRow(
              icon: Icons.apps_rounded,
              title: 'Services and options',
              subtitle: 'Passenger rides',
              onTap: () => _push(context, const DriverServicesScreen()),
            ),
            _ActionRow(
              icon: Icons.payments_outlined,
              title: 'Payment',
              subtitle: 'Cash',
              showDivider: false,
              onTap: () => _push(context, const PaymentInformationScreen()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Account',
          children: <Widget>[
            _ActionRow(
              icon: Icons.verified_user_outlined,
              title: 'Account status',
              subtitle: _reviewLabel,
              onTap: () => _push(
                context,
                DriverAccountStatusScreen(
                  reviewStatus: reviewStatus,
                  registration: registration,
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.description_outlined,
              title: 'Documents',
              subtitle: 'Licence and verification',
              onTap: () => _push(
                context,
                DriverDocumentsOverviewScreen(registration: registration),
              ),
            ),
            _ActionRow(
              icon: Icons.badge_outlined,
              title: 'Licence information',
              subtitle: registration.licenceNumber.isEmpty
                  ? 'Not provided'
                  : registration.licenceNumber,
              showDivider: false,
              onTap: () => _push(
                context,
                DriverLicenceDetailsScreen(registration: registration),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Driving',
          children: <Widget>[
            _ActionRow(
              icon: Icons.directions_car_outlined,
              title: 'My vehicle',
              subtitle: _vehicleName(registration),
              onTap: () => _push(
                context,
                DriverVehicleScreen(registration: registration),
              ),
            ),
            _ActionRow(
              icon: Icons.apps_rounded,
              title: 'Services and options',
              subtitle: 'Passenger rides',
              onTap: () => _push(context, const DriverServicesScreen()),
            ),
            _ActionRow(
              icon: Icons.receipt_long_outlined,
              title: 'Trip activity',
              subtitle: 'Ride history and trip states',
              showDivider: false,
              onTap: () => _push(context, const DriverActivityScreen()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Safety & support',
          children: <Widget>[
            _ActionRow(
              icon: Icons.health_and_safety_outlined,
              title: 'Safety center',
              subtitle: 'Driver and passenger safety guidance',
              onTap: () => _push(context, const DriverSafetyCenterScreen()),
            ),
            _ActionRow(
              icon: Icons.camera_alt_outlined,
              title: 'Photo check',
              subtitle: 'Identity photo status and retake',
              onTap: () => _push(context, const PhotoCheckScreen()),
            ),
            _ActionRow(
              icon: Icons.support_agent_outlined,
              title: 'Help center',
              subtitle: 'Troubleshooting and support guidance',
              showDivider: false,
              onTap: () => _push(context, const DriverHelpCenterScreen()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'App',
          children: <Widget>[
            _ActionRow(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Appearance, security, permissions and app information',
              onTap: () => _push(context, const DriverCompleteSettingsScreen()),
            ),
            _ActionRow(
              icon: Icons.gavel_outlined,
              title: 'Legal information',
              subtitle: 'Driver agreement and privacy summaries',
              onTap: () => _push(context, const DriverLegalHubScreen()),
            ),
            _ActionRow(
              icon: Icons.card_giftcard_outlined,
              title: 'Invite a friend',
              subtitle: 'Referral program status',
              showDivider: false,
              onTap: () => _push(context, const InviteDriverScreen()),
            ),
          ],
        ),
        if (onSignOut != null) ...<Widget>[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }
}

class DriverAccountStatusScreen extends StatelessWidget {
  const DriverAccountStatusScreen({
    required this.reviewStatus,
    required this.registration,
    super.key,
  });

  final String reviewStatus;
  final DriverRegistration registration;

  @override
  Widget build(BuildContext context) {
    final String normalized = reviewStatus.trim().toLowerCase();
    final bool approved = normalized == 'approved';
    final bool rejected = normalized == 'rejected';

    return _DetailPage(
      title: 'Account status',
      children: <Widget>[
        _HeroStatusCard(
          icon: approved
              ? Icons.verified_rounded
              : rejected
              ? Icons.error_outline_rounded
              : Icons.schedule_rounded,
          title: approved
              ? 'Driver account approved'
              : rejected
              ? 'Verification needs attention'
              : 'Verification in progress',
          body: approved
              ? 'Your profile is approved for driver service.'
              : rejected
              ? 'Review your registration details and follow any verified review instructions provided to your account.'
              : 'Your submitted registration is waiting for account review.',
          status: approved
              ? 'Approved'
              : rejected
              ? 'Action needed'
              : 'Pending',
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Registration checklist',
          children: <Widget>[
            _StatusLine(
              icon: Icons.apps_rounded,
              title: 'Service',
              value: registration.serviceComplete
                  ? 'Complete'
                  : 'Needs attention',
              complete: registration.serviceComplete,
            ),
            _StatusLine(
              icon: Icons.directions_car_outlined,
              title: 'Vehicle details',
              value: registration.vehicleComplete
                  ? 'Complete'
                  : 'Needs attention',
              complete: registration.vehicleComplete,
            ),
            _StatusLine(
              icon: Icons.badge_outlined,
              title: 'Licence information',
              value: registration.licenceComplete
                  ? 'Complete'
                  : 'Needs attention',
              complete: registration.licenceComplete,
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _InfoBanner(
          icon: Icons.info_outline_rounded,
          text:
              'This page reports the current profile state already available to the app. It does not approve or reject accounts locally.',
        ),
      ],
    );
  }
}

class DriverDocumentsOverviewScreen extends StatelessWidget {
  const DriverDocumentsOverviewScreen({required this.registration, super.key});

  final DriverRegistration registration;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Documents',
      children: <Widget>[
        const _HeroStatusCard(
          icon: Icons.folder_copy_outlined,
          title: 'Driver verification documents',
          body:
              'Licence images are submitted during onboarding and remain part of the driver review process.',
          status: 'Submitted',
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Driver licence',
          children: <Widget>[
            _DocumentLine(
              title: 'Licence front',
              subtitle: 'Submitted during registration',
              icon: Icons.credit_card_outlined,
            ),
            _DocumentLine(
              title: 'Licence back',
              subtitle: 'Submitted during registration',
              icon: Icons.credit_card_outlined,
            ),
            _ActionRow(
              icon: Icons.badge_outlined,
              title: 'Licence details',
              subtitle: registration.licenceNumber.isEmpty
                  ? 'Review registration information'
                  : registration.licenceNumber,
              showDivider: false,
              onTap: () => _push(
                context,
                DriverLicenceDetailsScreen(registration: registration),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Identity check',
          children: <Widget>[
            _ActionRow(
              icon: Icons.face_retouching_natural_outlined,
              title: 'Photo check',
              subtitle:
                  'View status, capture or retake your verification photo',
              showDivider: false,
              onTap: () => _push(context, const PhotoCheckScreen()),
            ),
          ],
        ),
      ],
    );
  }
}

class DriverLicenceDetailsScreen extends StatelessWidget {
  const DriverLicenceDetailsScreen({required this.registration, super.key});

  final DriverRegistration registration;

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Licence information',
      children: <Widget>[
        _SectionCard(
          title: 'Driver licence',
          children: <Widget>[
            _DataLine(
              label: 'Country',
              value: _safe(registration.licenceCountry),
            ),
            _DataLine(
              label: 'First name',
              value: _safe(registration.licenceFirstName),
            ),
            _DataLine(
              label: 'Last name',
              value: _safe(registration.licenceLastName),
            ),
            _DataLine(
              label: 'Licence number',
              value: _safe(registration.licenceNumber),
            ),
            _DataLine(
              label: 'Issue date',
              value: _safe(registration.licenceIssueDate),
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _InfoBanner(
          icon: Icons.lock_outline_rounded,
          text:
              'Licence details shown here are read-only in the dashboard. Registration changes should go through a verified account review process.',
        ),
      ],
    );
  }
}

class DriverActivityScreen extends StatelessWidget {
  const DriverActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DetailPage(
      title: 'Trip activity',
      children: <Widget>[
        _HeroStatusCard(
          icon: Icons.route_outlined,
          title: 'No verified trip history yet',
          body:
              'Completed, cancelled and declined ride activity will appear here when live trip records are connected.',
          status: 'Empty',
        ),
        SizedBox(height: 14),
        _SectionCard(
          title: 'Activity categories',
          children: <Widget>[
            _ReadOnlyLine(
              icon: Icons.check_circle_outline_rounded,
              title: 'Completed trips',
              value: '—',
            ),
            _ReadOnlyLine(
              icon: Icons.cancel_outlined,
              title: 'Cancelled trips',
              value: '—',
            ),
            _ReadOnlyLine(
              icon: Icons.history_rounded,
              title: 'Recent requests',
              value: '—',
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}

class DriverSafetyCenterScreen extends StatelessWidget {
  const DriverSafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Safety center',
      children: <Widget>[
        const _HeroStatusCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Drive only when conditions are safe',
          body:
              'Vehicle condition, road conditions, driver readiness and passenger safety all take priority over completing a request.',
          status: 'Safety first',
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Before going online',
          children: const <Widget>[
            _GuidanceRow(
              icon: Icons.car_repair_outlined,
              title: 'Check your vehicle',
              body:
                  'Confirm tyres, brakes, lights, fuel or charge level and required documents.',
            ),
            _GuidanceRow(
              icon: Icons.phone_android_outlined,
              title: 'Mount and charge your phone',
              body:
                  'Keep the phone secure and avoid handling it while the vehicle is moving.',
            ),
            _GuidanceRow(
              icon: Icons.location_on_outlined,
              title: 'Check location access',
              body:
                  'Location must be available for positioning while driver service is active.',
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'During a trip',
          children: const <Widget>[
            _GuidanceRow(
              icon: Icons.verified_user_outlined,
              title: 'Confirm the correct passenger and trip',
              body:
                  'Use only the verified request information shown by Alpha Plus.',
            ),
            _GuidanceRow(
              icon: Icons.speed_outlined,
              title: 'Follow road rules',
              body:
                  'Never let an app notification or trip target override local traffic laws.',
            ),
            _GuidanceRow(
              icon: Icons.warning_amber_rounded,
              title: 'Stop if conditions become unsafe',
              body:
                  'Prioritise immediate safety and use approved emergency or support channels when necessary.',
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }
}

class DriverHelpCenterScreen extends StatelessWidget {
  const DriverHelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Help center',
      children: <Widget>[
        const _HeroStatusCard(
          icon: Icons.support_agent_outlined,
          title: 'Driver help',
          body:
              'Use the guides below for common app problems. In-app live support messaging remains disabled until a real support channel is connected.',
          status: 'Self-service',
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Common problems',
          children: <Widget>[
            _ActionRow(
              icon: Icons.gps_fixed_rounded,
              title: 'Location problems',
              subtitle: 'GPS, permission and location-service checks',
              onTap: () => _push(context, const TroubleshootingScreen()),
            ),
            _ActionRow(
              icon: Icons.notifications_active_outlined,
              title: 'Missing alerts',
              subtitle: 'Notification and battery guidance',
              onTap: () => _push(context, const DriverNotificationsScreen()),
            ),
            _ActionRow(
              icon: Icons.camera_alt_outlined,
              title: 'Photo check problems',
              subtitle: 'Camera, lighting and verification guidance',
              showDivider: false,
              onTap: () => _push(context, const PhotoCheckScreen()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _InfoBanner(
          icon: Icons.security_rounded,
          text:
              'Never share an OTP, password, unrestricted API key or device unlock code with anyone claiming to be support.',
        ),
      ],
    );
  }
}

class DriverNotificationsScreen extends StatelessWidget {
  const DriverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Notifications',
      children: <Widget>[
        const _HeroStatusCard(
          icon: Icons.notifications_none_rounded,
          title: 'Notification center ready',
          body:
              'Live trip and service notification delivery is not connected in this UI-only phase.',
          status: 'No alerts',
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Device setup',
          children: <Widget>[
            FutureBuilder<PermissionStatus>(
              future: Permission.notification.status,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<PermissionStatus> snapshot,
                  ) {
                    final PermissionStatus? status = snapshot.data;
                    return _ReadOnlyLine(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notification permission',
                      value: status == null
                          ? 'Checking…'
                          : status.isGranted
                          ? 'Allowed'
                          : 'Not allowed',
                    );
                  },
            ),
            _ActionRow(
              icon: Icons.settings_outlined,
              title: 'Open app settings',
              subtitle: 'Review notification permission on this device',
              showDivider: false,
              onTap: () => unawaited(openAppSettings()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _InfoBanner(
          icon: Icons.info_outline_rounded,
          text:
              'The app will not pretend an alert was delivered until notification delivery is connected and verified.',
        ),
      ],
    );
  }
}

class DriverCompleteSettingsScreen extends StatelessWidget {
  const DriverCompleteSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Settings',
      children: <Widget>[
        _SectionCard(
          title: 'Appearance',
          children: <Widget>[
            _ActionRow(
              icon: Icons.brightness_6_outlined,
              title: 'App appearance',
              subtitle: 'Use device settings, light or dark mode',
              showDivider: false,
              onTap: () => _push(context, const DriverAppearanceScreen()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _SectionCard(
          title: 'Security',
          children: <Widget>[DriverBiometricSettingsTile()],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Device',
          children: <Widget>[
            _ActionRow(
              icon: Icons.phonelink_lock_outlined,
              title: 'App permissions',
              subtitle: 'Location, camera and notifications',
              onTap: () => _push(context, const DriverPermissionsScreen()),
            ),
            _ActionRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Permission and delivery status',
              showDivider: false,
              onTap: () => _push(context, const DriverNotificationsScreen()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Account & information',
          children: <Widget>[
            _ActionRow(
              icon: Icons.shield_outlined,
              title: 'Privacy and security',
              subtitle: 'Sessions, biometrics, location and documents',
              onTap: () => _push(context, const PrivacySecurityScreen()),
            ),
            _ActionRow(
              icon: Icons.gavel_outlined,
              title: 'Legal information',
              subtitle: 'Driver agreement and privacy summaries',
              onTap: () => _push(context, const DriverLegalHubScreen()),
            ),
            _ActionRow(
              icon: Icons.info_outline_rounded,
              title: 'About Alpha Plus',
              subtitle: 'Version and product information',
              showDivider: false,
              onTap: () => _push(context, const DriverAboutScreen()),
            ),
          ],
        ),
      ],
    );
  }
}

class DriverPermissionsScreen extends StatelessWidget {
  const DriverPermissionsScreen({super.key});

  Future<(PermissionStatus, PermissionStatus, PermissionStatus)> _read() async {
    final List<PermissionStatus> statuses =
        await Future.wait(<Future<PermissionStatus>>[
          Permission.locationWhenInUse.status,
          Permission.camera.status,
          Permission.notification.status,
        ]);
    return (statuses[0], statuses[1], statuses[2]);
  }

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'App permissions',
      children: <Widget>[
        FutureBuilder<(PermissionStatus, PermissionStatus, PermissionStatus)>(
          future: _read(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<
                  (PermissionStatus, PermissionStatus, PermissionStatus)
                >
                snapshot,
              ) {
                final data = snapshot.data;
                return _SectionCard(
                  title: 'This device',
                  children: <Widget>[
                    _PermissionLine(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      status: data?.$1,
                    ),
                    _PermissionLine(
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera',
                      status: data?.$2,
                    ),
                    _PermissionLine(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      status: data?.$3,
                      showDivider: false,
                    ),
                  ],
                );
              },
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed: () => unawaited(openAppSettings()),
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Open app settings'),
        ),
        const SizedBox(height: 14),
        const _InfoBanner(
          icon: Icons.info_outline_rounded,
          text:
              'Changing a permission in system settings may require reopening Alpha Plus before every screen reflects the new state.',
        ),
      ],
    );
  }
}

class DriverLegalHubScreen extends StatelessWidget {
  const DriverLegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailPage(
      title: 'Legal information',
      children: <Widget>[
        const _InfoBanner(
          icon: Icons.info_outline_rounded,
          text: DriverLegalContent.summaryNotice,
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Onboarding summaries',
          children: <Widget>[
            _ActionRow(
              icon: Icons.description_outlined,
              title: 'Driver service agreement',
              subtitle: 'Current onboarding summary',
              onTap: () => _push(
                context,
                const DriverLegalDetailsScreen(
                  document: DriverLegalDocument.service,
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy summary',
              subtitle: 'How driver information is used',
              onTap: () => _push(
                context,
                const DriverLegalDetailsScreen(
                  document: DriverLegalDocument.privacy,
                ),
              ),
            ),
            _ActionRow(
              icon: Icons.campaign_outlined,
              title: 'Product updates',
              subtitle: 'Optional communications summary',
              showDivider: false,
              onTap: () => _push(
                context,
                const DriverLegalDetailsScreen(
                  document: DriverLegalDocument.updates,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DriverAboutScreen extends StatelessWidget {
  const DriverAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DetailPage(
      title: 'About Alpha Plus',
      children: <Widget>[
        _BrandPanel(),
        SizedBox(height: 18),
        _SectionCard(
          title: 'App information',
          children: <Widget>[
            _ReadOnlyLine(
              icon: Icons.apps_outlined,
              title: 'Product',
              value: 'Alpha Plus',
            ),
            _ReadOnlyLine(
              icon: Icons.numbers_outlined,
              title: 'Version',
              value: '1.0.0',
            ),
            _ReadOnlyLine(
              icon: Icons.place_outlined,
              title: 'Launch market',
              value: 'South Sudan',
              showDivider: false,
            ),
          ],
        ),
        SizedBox(height: 14),
        _InfoBanner(
          icon: Icons.verified_user_outlined,
          text:
              'Alpha Plus is the driver application. Passenger-facing functions belong to AlphaRide and are intentionally kept separate.',
        ),
      ],
    );
  }
}

class _TabScaffold extends StatelessWidget {
  const _TabScaffold({
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        if (subtitle != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 22),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
          children: <Widget>[
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: AlphaBackButton(),
            ),
            const SizedBox(height: 32),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 28),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String body;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 340;
          final Widget iconWidget = CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Icon(icon, color: AppColors.ink),
          );
          final Widget text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(body, style: Theme.of(context).textTheme.bodyLarge),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[iconWidget, const SizedBox(height: 14), text],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              iconWidget,
              const SizedBox(width: 16),
              Expanded(child: text),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.driverName,
    required this.reviewStatus,
    required this.vehicle,
  });

  final String driverName;
  final String reviewStatus;
  final String vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person_rounded, color: AppColors.ink, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  driverName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(reviewStatus),
                if (vehicle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(vehicle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverServicesSummaryCard extends StatelessWidget {
  const _DriverServicesSummaryCard({
    required this.reviewLabel,
    required this.onServicesTap,
  });

  final String reviewLabel;
  final VoidCallback onServicesTap;

  @override
  Widget build(BuildContext context) {
    final String reviewText = reviewLabel == 'Under review'
        ? 'Account under review'
        : reviewLabel == 'Approved'
        ? 'Account approved'
        : 'Account needs attention';

    return Container(
      key: const Key('driverServicesSummary'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stackButton =
              constraints.maxWidth < 380 ||
              MediaQuery.textScalerOf(context).scale(16) > 20;

          final Widget details = Row(
            key: const Key('driverServicesDetails'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.local_taxi_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Passenger rides',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reviewText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );

          final Widget button = FilledButton.tonal(
            key: const Key('driverMyServicesButton'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: onServicesTap,
            child: const Text('My services', textAlign: TextAlign.center),
          );

          final Widget metrics = const Row(
            children: <Widget>[
              Expanded(
                child: _MetricTile(
                  label: 'Trips',
                  value: '—',
                  icon: Icons.route_outlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Rating',
                  value: '—',
                  icon: Icons.star_outline_rounded,
                ),
              ),
            ],
          );

          if (stackButton) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                details,
                const SizedBox(height: 12),
                button,
                const SizedBox(height: 14),
                metrics,
              ],
            );
          }

          return Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  button,
                ],
              ),
              const SizedBox(height: 14),
              metrics,
            ],
          );
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.complete,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool complete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _ReadOnlyLine(
      icon: icon,
      title: title,
      value: value,
      showDivider: showDivider,
      trailing: Icon(
        complete ? Icons.check_circle_rounded : Icons.schedule_rounded,
        color: complete ? const Color(0xFF0E9F6E) : Colors.orange,
      ),
    );
  }
}

class _ReadOnlyLine extends StatelessWidget {
  const _ReadOnlyLine({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _PermissionLine extends StatelessWidget {
  const _PermissionLine({
    required this.icon,
    required this.title,
    required this.status,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final PermissionStatus? status;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final String label = status == null
        ? 'Checking…'
        : status!.isGranted
        ? 'Allowed'
        : status!.isPermanentlyDenied
        ? 'Blocked'
        : 'Not allowed';

    return _ReadOnlyLine(
      icon: icon,
      title: title,
      value: label,
      showDivider: showDivider,
      trailing: status == null
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              status!.isGranted
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: status!.isGranted
                  ? const Color(0xFF0E9F6E)
                  : Colors.orange,
            ),
    );
  }
}

class _DataLine extends StatelessWidget {
  const _DataLine({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Text(label)),
              const SizedBox(width: 20),
              Flexible(
                child: SelectableText(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _DocumentLine extends StatelessWidget {
  const _DocumentLine({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF0E9F6E)),
            ],
          ),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({
    required this.icon,
    required this.title,
    required this.body,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: Icon(icon, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.number,
    required this.title,
    required this.body,
    this.showDivider = true,
  });

  final String number;
  final String title;
  final String body;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(label),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 11),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 132,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(icon),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.local_taxi_rounded, size: 72, color: AppColors.ink),
            SizedBox(height: 10),
            Text(
              'ALPHA PLUS',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _safe(String value) =>
    value.trim().isEmpty ? 'Not provided' : value.trim();

String _vehicleName(DriverRegistration registration) {
  final String name = <String>[
    registration.make,
    registration.model,
  ].where((String part) => part.trim().isNotEmpty).join(' ');
  return name.isEmpty ? 'Vehicle under review' : name;
}

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
