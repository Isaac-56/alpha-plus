import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../onboarding/models/driver_registration.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({
    required this.driverName,
    required this.registration,
    super.key,
  });

  final String driverName;
  final DriverRegistration registration;

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _RequestsPage(driverName: widget.driverName),
      const _PoolPage(),
      const _MoneyPage(),
      const _ChatsPage(),
      _ProfilePage(
        driverName: widget.driverName,
        registration: widget.registration,
      ),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int value) => setState(() => _index = value),
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.navigation_outlined),
              selectedIcon: Icon(Icons.navigation_rounded),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Pool',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Money',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('1'),
                child: Icon(Icons.chat_bubble_outline_rounded),
              ),
              selectedIcon: Badge(
                label: Text('1'),
                child: Icon(Icons.chat_bubble_rounded),
              ),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsPage extends StatelessWidget {
  const _RequestsPage({required this.driverName});

  final String driverName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const _MapCanvas(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.schedule_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Verification in progress',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text('Usually completed within a few minutes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Welcome, ${driverName.split(' ').first}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      const _ProgressRow(
                        title: 'Registration',
                        subtitle: 'Complete',
                        complete: true,
                      ),
                      const _ProgressRow(
                        title: 'Driver documents',
                        subtitle: 'Under review',
                        complete: true,
                      ),
                      const _ProgressRow(
                        title: 'Device setup',
                        subtitle: 'Ready',
                        complete: true,
                        showLine: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapPainter());
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint background = Paint()..color = const Color(0xFFE9F7E7);
    final Paint secondary = Paint()
      ..color = const Color(0xFFCAE8C5)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    final Paint road = Paint()
      ..color = Colors.white
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, background);
    for (int i = -1; i < 7; i++) {
      final double y = i * 140.0;
      canvas.drawLine(Offset(-30, y), Offset(size.width + 60, y + 190), road);
      canvas.drawLine(
        Offset(size.width - (i * 62), -30),
        Offset(size.width - 160 - (i * 40), size.height + 40),
        secondary,
      );
    }
    final Paint pin = Paint()..color = AppColors.ink;
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.42), 12, pin);
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.42),
      5,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.title,
    required this.subtitle,
    required this.complete,
    this.showLine = true,
  });

  final String title;
  final String subtitle;
  final bool complete;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 38,
            child: Column(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: complete
                        ? AppColors.primary
                        : Theme.of(context).dividerColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.ink,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(width: 3, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolPage extends StatelessWidget {
  const _PoolPage();

  @override
  Widget build(BuildContext context) {
    return const _EmptyStatePage(
      title: 'Order pool',
      icon: Icons.inbox_rounded,
      headline: 'No trip requests right now',
      description: 'New requests will appear here as soon as you are approved.',
      buttonLabel: 'Update',
    );
  }
}

class _MoneyPage extends StatelessWidget {
  const _MoneyPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text('Money', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 28),
          Text(
            'SSP 0',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontSize: 52),
          ),
          const Text(
            'Today',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 26),
          _DashboardCard(
            child: Column(
              children: <Widget>[
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline_rounded),
                  title: Text('Balance limit'),
                  subtitle: Text('Everything looks good'),
                  trailing: Text(
                    '-SSP 0',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Divider(color: Theme.of(context).dividerColor),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Balance'),
                  trailing: Text(
                    'SSP 0',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatsPage extends StatelessWidget {
  const _ChatsPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text('Messages', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          const _MessageTile(
            icon: Icons.support_agent_rounded,
            title: 'Support',
            color: AppColors.primary,
          ),
          const _MessageTile(
            icon: Icons.newspaper_rounded,
            title: 'ALPHA + news',
            subtitle: 'Welcome to the driver community',
          ),
          const _MessageTile(
            icon: Icons.notifications_active_rounded,
            title: 'Service notifications',
          ),
          const _MessageTile(
            icon: Icons.warning_amber_rounded,
            title: 'Safety alerts',
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.driverName, required this.registration});

  final String driverName;
  final DriverRegistration registration;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.person_rounded, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  driverName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DashboardCard(
            child: Column(
              children: <Widget>[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Driver status'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Under review',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Divider(color: Theme.of(context).dividerColor),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('My vehicle'),
                  subtitle: Text('${registration.make} ${registration.model}'),
                  trailing: Text(registration.plateNumber),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _ProfileAction(
            icon: Icons.build_circle_outlined,
            title: 'Troubleshooting',
          ),
          const _ProfileAction(
            icon: Icons.camera_alt_outlined,
            title: 'Photo check',
          ),
          const _ProfileAction(
            icon: Icons.card_giftcard_rounded,
            title: 'Invite a friend',
          ),
          const _ProfileAction(
            icon: Icons.settings_outlined,
            title: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _EmptyStatePage extends StatelessWidget {
  const _EmptyStatePage({
    required this.title,
    required this.icon,
    required this.headline,
    required this.description,
    required this.buttonLabel,
  });

  final String title;
  final IconData icon;
  final String headline;
  final String description;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const Spacer(),
            Center(
              child: Column(
                children: <Widget>[
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 58),
                  ),
                  const SizedBox(height: 24),
                  Text(headline, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(buttonLabel),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 7),
      leading: CircleAvatar(
        radius: 27,
        backgroundColor: color ?? AppColors.primary.withValues(alpha: 0.2),
        child: Icon(icon, color: AppColors.ink),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.keyboard_arrow_right_rounded),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.keyboard_arrow_right_rounded),
      onTap: () {},
    );
  }
}
