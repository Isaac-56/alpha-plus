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
      duration: const Duration(milliseconds: 2850),
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
          final double carEntrance = Curves.easeOutBack.transform(
            const Interval(0, 0.34).transform(_controller.value),
          );
          final double carOpacity = Curves.easeOut.transform(
            const Interval(0, 0.18).transform(_controller.value),
          );
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Center(
                child: Transform.scale(
                  scale: 1 + (pulse * 0.025),
                  child: Container(
                    width: 290,
                    height: 290,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 286,
                        height: 222,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            Opacity(
                              opacity: carOpacity,
                              child: Transform.translate(
                                offset: Offset(0, -34 * (1 - carEntrance)),
                                child: Transform.scale(
                                  scale: 0.82 + (carEntrance * 0.18),
                                  child: Image.asset(
                                    'assets/branding/alpha_plus_car_frame.png',
                                    width: 286,
                                    height: 222,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 113,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List<Widget>.generate(
                                  7,
                                  (int index) => _AnimatedLetter(
                                    controller: _controller,
                                    index: index,
                                    character: 'ALPHA +'[index],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: SizedBox(
                            width: 118,
                            height: 3,
                            child: LinearProgressIndicator(
                              value: Curves.easeInOutCubic.transform(
                                _controller.value,
                              ),
                              backgroundColor: AppColors.ink.withValues(
                                alpha: 0.12,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
    if (character == ' ') {
      return const SizedBox(width: 10);
    }

    final double start = 0.22 + (index * 0.055);
    final double end = (start + 0.22).clamp(0, 1).toDouble();
    final CurvedAnimation entrance = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, index.isEven ? 0.7 : -0.7),
          end: Offset.zero,
        ).animate(entrance),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.62, end: 1).animate(entrance),
          child: Text(
            character,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 36,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.7,
            ),
          ),
        ),
      ),
    );
  }
}
