import 'package:flutter/material.dart';

import 'alpha_back_button.dart';
import 'alpha_components.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.bottom,
    this.header,
    this.centerHeader = false,
    this.showBackButton = true,
    this.onBack,
    this.authStyle = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottom;
  final Widget? header;
  final bool centerHeader;
  final bool showBackButton;
  final VoidCallback? onBack;
  // Opt in only on authentication pages. Other onboarding layouts stay intact.
  final bool authStyle;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets keyboardInsets = MediaQuery.viewInsetsOf(context);
    final bool keyboardVisible = keyboardInsets.bottom > 0;
    final ThemeData baseTheme = Theme.of(context);
    final ColorScheme colors = baseTheme.colorScheme;
    final ThemeData pageTheme = authStyle
        ? baseTheme.copyWith(
            scaffoldBackgroundColor: colors.surface,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                disabledBackgroundColor: colors.onSurface.withValues(
                  alpha: 0.08,
                ),
                disabledForegroundColor: colors.onSurface.withValues(
                  alpha: 0.42,
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        : baseTheme;

    final Widget page = Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: authStyle ? 560 : AppSpacing.contentMaxWidth,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        authStyle ? 8 : 18,
                        24,
                        keyboardInsets.bottom > 0 ? 24 : 36,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              if (showBackButton)
                                AlphaBackButton(onPressed: onBack)
                              else
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.drive_eta_rounded,
                                    color: colors.onSurface,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: AlphaStatusPill(
                                      label: 'Alpha Plus',
                                      icon: Icons.verified_user_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: authStyle && keyboardVisible
                                ? 18
                                : showBackButton
                                ? 34
                                : 12,
                          ),
                          if (header != null &&
                              !(authStyle && keyboardVisible)) ...<Widget>[
                            Align(alignment: Alignment.center, child: header!),
                            const SizedBox(height: 36),
                          ],
                          Align(
                            alignment: centerHeader
                                ? Alignment.center
                                : Alignment.centerLeft,
                            child: Text(
                              title,
                              textAlign: centerHeader
                                  ? TextAlign.center
                                  : TextAlign.left,
                              style: authStyle
                                  ? pageTheme.textTheme.headlineLarge?.copyWith(
                                      fontSize: 29,
                                      height: 1.18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.7,
                                    )
                                  : pageTheme.textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.65,
                                    ),
                            ),
                          ),
                          if (subtitle != null) ...<Widget>[
                            const SizedBox(height: 14),
                            Align(
                              alignment: centerHeader
                                  ? Alignment.center
                                  : Alignment.centerLeft,
                              child: Text(
                                subtitle!,
                                textAlign: centerHeader
                                    ? TextAlign.center
                                    : TextAlign.left,
                                style: pageTheme.textTheme.bodyLarge?.copyWith(
                                  color: pageTheme.textTheme.bodyMedium?.color,
                                  fontSize: authStyle ? 15.5 : null,
                                  height: authStyle ? 1.55 : null,
                                  fontWeight: authStyle
                                      ? FontWeight.w400
                                      : null,
                                  letterSpacing: authStyle ? -0.1 : null,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(
                            height: authStyle && keyboardVisible ? 20 : 36,
                          ),
                          child,
                        ],
                      ),
                    ),
                  ),
                  if (bottom != null)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: pageTheme.scaffoldBackgroundColor,
                        border: Border(
                          top: BorderSide(color: pageTheme.dividerColor),
                        ),
                        boxShadow: null,
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
          ),
        ),
      ),
    );
    return authStyle ? Theme(data: pageTheme, child: page) : page;
  }
}

class AuthHeaderIcon extends StatelessWidget {
  const AuthHeaderIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 144,
        height: 144,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 104,
          height: 104,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 50, color: colors.onSurface),
        ),
      ),
    );
  }
}
