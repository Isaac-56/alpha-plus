import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/alpha_back_button.dart';
import '../../onboarding/models/driver_registration.dart';

class BalanceLimitScreen extends StatelessWidget {
  const BalanceLimitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Check your account\nbalance limit',
      bottom: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Got it'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Alpha Plus charges a service fee for each completed trip, but you do not have to pay it immediately.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          Text(
            'Your balance limit is the amount your driver account can owe. If the limit is exceeded, new trip requests will pause until your balance reaches the required level.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 44),
          Center(
            child: Container(
              width: 250,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(Icons.account_balance_wallet_rounded, size: 118),
                  Positioned(
                    right: 44,
                    bottom: 42,
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.schedule_rounded, size: 34),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverServicesScreen extends StatelessWidget {
  const DriverServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Services and options',
      child: Column(
        children: <Widget>[
          _InformationCard(
            icon: Icons.local_taxi_rounded,
            title: 'Passenger rides',
            subtitle: 'Active',
            trailing: _StatusPill(label: 'Enabled'),
          ),
          const SizedBox(height: 12),
          _InformationCard(
            icon: Icons.delivery_dining_rounded,
            title: 'Delivery',
            subtitle: 'Coming soon',
            enabled: false,
            trailing: _StatusPill(label: 'Soon', muted: true),
          ),
          const SizedBox(height: 24),
          _NoticeCard(
            icon: Icons.info_outline_rounded,
            text:
                'Your available services are assigned after your vehicle and documents have been approved.',
          ),
        ],
      ),
    );
  }
}

class DriverVehicleScreen extends StatelessWidget {
  const DriverVehicleScreen({required this.registration, super.key});

  final DriverRegistration registration;

  @override
  Widget build(BuildContext context) {
    final String vehicle = <String>[
      registration.make,
      registration.model,
    ].where((String value) => value.trim().isNotEmpty).join(' ');

    return _DetailScaffold(
      title: 'My vehicle',
      child: Column(
        children: <Widget>[
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Icon(Icons.directions_car_filled_rounded, size: 150),
          ),
          const SizedBox(height: 18),
          _DataRow(
            label: 'Vehicle',
            value: vehicle.isEmpty ? 'Not provided' : vehicle,
          ),
          _DataRow(
            label: 'Type',
            value: registration.vehicleType.isEmpty
                ? 'Not provided'
                : registration.vehicleType,
          ),
          _DataRow(
            label: 'Color',
            value: registration.color.isEmpty
                ? 'Not provided'
                : registration.color,
          ),
          _DataRow(
            label: 'Manufacture year',
            value: registration.manufactureYear.isEmpty
                ? 'Not provided'
                : registration.manufactureYear,
          ),
          _DataRow(
            label: 'Plate number',
            value: registration.plateNumber.isEmpty
                ? 'Not provided'
                : registration.plateNumber,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class PartnerScreen extends StatelessWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DetailScaffold(
      title: 'Service partner',
      child: Column(
        children: <Widget>[
          _InformationCard(
            icon: Icons.business_center_rounded,
            title: 'Alpha Plus South Sudan',
            subtitle: 'Manages driver payments and service access',
          ),
          SizedBox(height: 16),
          _NoticeCard(
            icon: Icons.verified_user_outlined,
            text:
                'Partner information is verified by Alpha Plus. Contact Support if these details are incorrect.',
          ),
        ],
      ),
    );
  }
}

class PaymentInformationScreen extends StatelessWidget {
  const PaymentInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DetailScaffold(
      title: 'Payment',
      child: Column(
        children: <Widget>[
          _InformationCard(
            icon: Icons.payments_rounded,
            title: 'Cash payments',
            subtitle: 'Available for passenger trips',
            trailing: _StatusPill(label: 'Active'),
          ),
          SizedBox(height: 12),
          _InformationCard(
            icon: Icons.credit_card_rounded,
            title: 'Card payments',
            subtitle: 'Coming soon',
            enabled: false,
            trailing: _StatusPill(label: 'Soon', muted: true),
          ),
          SizedBox(height: 12),
          _InformationCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Alpha Wallet',
            subtitle: 'Coming soon',
            enabled: false,
            trailing: _StatusPill(label: 'Soon', muted: true),
          ),
        ],
      ),
    );
  }
}

class TroubleshootingScreen extends StatelessWidget {
  const TroubleshootingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Troubleshooting',
      child: Column(
        children: <Widget>[
          _ActionTile(
            icon: Icons.gps_fixed_rounded,
            title: 'Location is not updating',
            subtitle: 'Check GPS and background access',
            onTap: () => _showHelp(
              context,
              'Location access',
              'Enable precise location and allow Alpha Plus to use location while you are online.',
            ),
          ),
          _ActionTile(
            icon: Icons.notifications_active_outlined,
            title: 'Trip alerts are missing',
            subtitle: 'Check notifications and battery settings',
            onTap: () => _showHelp(
              context,
              'Trip alerts',
              'Allow notifications and remove battery restrictions so new requests can arrive reliably.',
            ),
          ),
          _ActionTile(
            icon: Icons.signal_cellular_alt_rounded,
            title: 'Connection problems',
            subtitle: 'Refresh your network connection',
            onTap: () => _showHelp(
              context,
              'Connection problems',
              'Switch mobile data off and on, then reopen Alpha Plus. Contact Support if the problem continues.',
            ),
          ),
          _ActionTile(
            icon: Icons.support_agent_rounded,
            title: 'Contact Support',
            subtitle: 'Get help from the Alpha Plus team',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SupportConversationScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoCheckScreen extends StatelessWidget {
  const PhotoCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Photo check',
      bottom: ElevatedButton.icon(
        onPressed: () => _comingSoon(context, 'Camera verification'),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Start photo check'),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.face_retouching_natural_rounded, size: 128),
          ),
          const SizedBox(height: 26),
          Text(
            'Make sure your face is clearly visible and your vehicle is parked safely before starting.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          const _ChecklistRow(text: 'Use good, even lighting'),
          const _ChecklistRow(text: 'Remove hats and sunglasses'),
          const _ChecklistRow(text: 'Follow the on-screen instructions'),
        ],
      ),
    );
  }
}

class InviteDriverScreen extends StatelessWidget {
  const InviteDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Invite a friend',
      bottom: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Referral sharing will be connected in the backend stage.',
              ),
            ),
          );
        },
        icon: const Icon(Icons.ios_share_rounded),
        label: const Text('Share invitation'),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.group_add_rounded, size: 124),
          ),
          const SizedBox(height: 24),
          Text(
            'Share Alpha Plus with trusted drivers in your community.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Referral code'),
                      SizedBox(height: 4),
                      Text(
                        'AVAILABLE SOON',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.copy_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _tripAlerts = true;
  bool _sound = true;

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Settings',
      child: Column(
        children: <Widget>[
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Trip request alerts'),
            subtitle: const Text('Receive alerts while you are online'),
            value: _tripAlerts,
            activeTrackColor: AppColors.primary,
            onChanged: (bool value) => setState(() => _tripAlerts = value),
          ),
          Divider(color: Theme.of(context).dividerColor),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Alert sounds'),
            subtitle: const Text('Play a sound for new trip requests'),
            value: _sound,
            activeTrackColor: AppColors.primary,
            onChanged: (bool value) => setState(() => _sound = value),
          ),
          Divider(color: Theme.of(context).dividerColor),
          _ActionTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English',
            onTap: () => _comingSoon(context, 'Language selection'),
          ),
          _ActionTile(
            icon: Icons.shield_outlined,
            title: 'Privacy and security',
            subtitle: 'Permissions and account protection',
            onTap: () => _comingSoon(context, 'Privacy settings'),
          ),
          _ActionTile(
            icon: Icons.info_outline_rounded,
            title: 'About Alpha Plus',
            subtitle: 'Version 1.0.0',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Alpha Plus',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }
}

class SupportConversationScreen extends StatefulWidget {
  const SupportConversationScreen({this.title = 'Support', super.key});

  final String title;

  @override
  State<SupportConversationScreen> createState() =>
      _SupportConversationScreenState();
}

class _SupportConversationScreenState extends State<SupportConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _messages.add(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(6),
          child: AlphaBackButton(),
        ),
        title: Text(widget.title),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const CircleAvatar(
                              radius: 42,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.support_agent_rounded,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'How can we help?',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Send a message and the Alpha Plus support team will respond here.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10, left: 54),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              _messages[index],
                              style: const TextStyle(color: AppColors.ink),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                12 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message Support',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.send_rounded, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InformationMessageScreen extends StatelessWidget {
  const InformationMessageScreen({
    required this.title,
    required this.body,
    required this.icon,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: title,
      child: Column(
        children: <Widget>[
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 62),
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(body, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.title,
    required this.child,
    this.bottom,
  });

  final String title;
  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AlphaBackButton(),
                    const SizedBox(height: 34),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 32),
                    child,
                  ],
                ),
              ),
            ),
            if (bottom != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                  child: bottom!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color muted =
        Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.muted;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.52,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary.withValues(alpha: 0.18),
              child: Icon(icon, color: enabled ? null : muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: muted
            ? Theme.of(context).scaffoldBackgroundColor
            : AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
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
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 18),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 7),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).colorScheme.surface,
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
        ),
        Divider(height: 1, indent: 66, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.check_rounded, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

void _showHelp(BuildContext context, String title, String message) {
  showModalBottomSheet<void>(
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
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _comingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature will be connected in the next stage.')),
  );
}
