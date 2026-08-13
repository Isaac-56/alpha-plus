import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'phone_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..addStatusListener(_openLoginWhenComplete);

    _controller.forward();
  }

  void _openLoginWhenComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, Animation<double> animation, _) {
          return FadeTransition(
            opacity: animation,
            child: const PhoneLoginScreen(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_openLoginWhenComplete)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double pulse = math.sin(_controller.value * math.pi * 3);
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Center(
                child: Transform.scale(
                  scale: 1 + (pulse * 0.035),
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink.withValues(
                          alpha: 0.05 + (_controller.value * 0.04),
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Semantics(
                  label: 'Alpha Plus',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(
                      6,
                      (int index) => _AnimatedLetter(
                        controller: _controller,
                        index: index,
                        character: 'ALPHA+'[index],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.62, 0.88, curve: Curves.easeOut),
                  ),
                  child: const Text(
                    'DRIVE WITH CONFIDENCE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.1,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedLetter extends StatelessWidget {
  const _AnimatedLetter({
    required this.controller,
    required this.index,
    required this.character,
  });

  final AnimationController controller;
  final int index;
  final String character;

  @override
  Widget build(BuildContext context) {
    final double start = 0.08 + (index * 0.075);
    final double end = (start + 0.28).clamp(0, 1).toDouble();
    final CurvedAnimation entrance = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, index.isEven ? 0.75 : -0.75),
          end: Offset.zero,
        ).animate(entrance),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.55, end: 1).animate(entrance),
          child: Text(
            character,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 45,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.2,
            ),
          ),
        ),
      ),
    );
  }
}
