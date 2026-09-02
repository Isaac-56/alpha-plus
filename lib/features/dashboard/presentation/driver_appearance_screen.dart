import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_controller.dart';

class DriverAppearanceScreen extends StatelessWidget {
  const DriverAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App appearance')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: <Widget>[
            Text(
              'Choose how Alpha Plus looks on this device. System is the '
              'default and follows your phone automatically.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Material(
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: AppThemeController.themeMode,
                builder:
                    (
                      BuildContext context,
                      ThemeMode selectedMode,
                      Widget? child,
                    ) {
                      return Column(
                        children: <Widget>[
                          _ThemeModeTile(
                            key: const Key('themeModeSystem'),
                            icon: Icons.settings_suggest_outlined,
                            title: 'Use device settings',
                            subtitle:
                                'Follow your phone appearance automatically',
                            selected: selectedMode == ThemeMode.system,
                            onTap: () => AppThemeController.setThemeMode(
                              ThemeMode.system,
                            ),
                          ),
                          _ThemeModeTile(
                            key: const Key('themeModeLight'),
                            icon: Icons.light_mode_outlined,
                            title: 'Light mode',
                            subtitle: 'White Alpha Plus theme',
                            selected: selectedMode == ThemeMode.light,
                            onTap: () => AppThemeController.setThemeMode(
                              ThemeMode.light,
                            ),
                          ),
                          _ThemeModeTile(
                            key: const Key('themeModeDark'),
                            icon: Icons.dark_mode_outlined,
                            title: 'Dark mode',
                            subtitle: 'Comfortable viewing in low light',
                            selected: selectedMode == ThemeMode.dark,
                            showDivider: false,
                            onTap: () =>
                                AppThemeController.setThemeMode(ThemeMode.dark),
                          ),
                        ],
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 5,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            child: Icon(icon),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    color: AppColors.ink,
                    size: 18,
                  )
                : null,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 72, color: Theme.of(context).dividerColor),
      ],
    );
  }
}
