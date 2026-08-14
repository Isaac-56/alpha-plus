import 'package:flutter/material.dart';

import 'alpha_back_button.dart';

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
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottom;
  final Widget? header;
  final bool centerHeader;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets keyboardInsets = MediaQuery.viewInsetsOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  keyboardInsets.bottom > 0 ? 24 : 36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (showBackButton) AlphaBackButton(onPressed: onBack),
                    SizedBox(height: showBackButton ? 34 : 12),
                    if (header != null) ...<Widget>[
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
                        style: Theme.of(context).textTheme.displaySmall,
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),
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
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 22,
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
