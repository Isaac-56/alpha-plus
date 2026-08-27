import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/driver_auth_service.dart';
import 'features/auth/data/driver_biometric_controller.dart';
import 'features/auth/data/driver_session_service.dart';
import 'features/auth/presentation/biometric_opt_in_screen.dart';
import 'features/auth/presentation/driver_biometric_gate.dart';
import 'features/auth/presentation/driver_name_screen.dart';
import 'features/auth/presentation/phone_login_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/dashboard/presentation/driver_shell.dart';
import 'features/profile/data/driver_profile_repository.dart';
import 'features/profile/models/driver_profile.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseInitializationError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (error) {
    firebaseInitializationError = error;
  }

  runApp(
    AlphaPlusApp(firebaseInitializationError: firebaseInitializationError),
  );
}

class AlphaPlusApp extends StatefulWidget {
  const AlphaPlusApp({
    this.firebaseInitializationError,
    this.home,
    this.authService,
    this.biometricController,
    super.key,
  });

  final Object? firebaseInitializationError;
  final Widget? home;
  final DriverAuthService? authService;
  final DriverBiometricController? biometricController;

  @override
  State<AlphaPlusApp> createState() => _AlphaPlusAppState();
}

class _AlphaPlusAppState extends State<AlphaPlusApp> {
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String?>? _authSubscription;
  DriverAuthService? _authService;
  DriverBiometricController? _biometrics;
  String? _activeUid;

  @override
  void initState() {
    super.initState();
    // Existing isolated widget previews (home: ...) don't initialize Firebase.
    // Production always installs the guard; tests can inject its dependencies.
    if (widget.firebaseInitializationError == null &&
        (widget.home == null || widget.biometricController != null)) {
      _authService = widget.authService ?? FirebaseDriverAuthService();
      _biometrics =
          widget.biometricController ?? DriverBiometricController.instance;
      _activeUid = _authService!.currentUserId;
      unawaited(_biometrics!.bindAccount(_activeUid));
      _authSubscription = _authService!.userIdChanges.listen(
        _accountChanged,
        onError: (Object error, StackTrace stackTrace) {
          _biometrics!.prepareForPhoneSignIn();
        },
      );
    }
  }

  void _accountChanged(String? uid) {
    if (!mounted || uid == _activeUid) return;
    // Discard ALL routes on sign-in, logout, or account replacement. Merely
    // changing the home widget leaves pushed private pages on the old stack.
    setState(() {
      _activeUid = uid;
      _navigatorKey = GlobalKey<NavigatorState>();
    });
    unawaited(_biometrics!.bindAccount(uid));
  }

  Future<void> _verifyByPhone() async {
    final String? uid = _authService!.currentUserId;
    if (uid == null) return;
    if (widget.authService != null) {
      await _authService!.signOut();
    } else {
      // Local sign-out remains possible during an outage. The next successful
      // phone login activates a new session; do not revoke another device's.
      await DriverSessionService.instance.forceLocalSignOut(uid);
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Alpha Plus',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeInOutCubic,
      builder: _biometrics == null
          ? null
          : (BuildContext context, Widget? child) => DriverBiometricGate(
              controller: _biometrics!,
              onPhoneSignIn: _verifyByPhone,
              child: child!,
            ),
      home:
          widget.home ??
          AppBootstrap(
            firebaseInitializationError: widget.firebaseInitializationError,
          ),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({this.firebaseInitializationError, super.key});

  final Object? firebaseInitializationError;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _minimumSplashDuration;
  DriverAuthService? _authService;
  DriverProfileStore? _profileStore;

  @override
  void initState() {
    super.initState();
    _minimumSplashDuration = Future<void>.delayed(
      const Duration(milliseconds: 2450),
    );

    if (widget.firebaseInitializationError == null) {
      _authService = FirebaseDriverAuthService();
      _profileStore = FirebaseDriverProfileStore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _minimumSplashDuration,
      builder: (BuildContext context, AsyncSnapshot<void> splashSnapshot) {
        if (splashSnapshot.connectionState != ConnectionState.done) {
          return const SplashScreen(automaticallyNavigate: false);
        }

        if (widget.firebaseInitializationError != null ||
            _authService == null ||
            _profileStore == null) {
          return const _FirebaseSetupScreen();
        }

        return StreamBuilder<String?>(
          stream: _authService!.userIdChanges,
          initialData: _authService!.currentUserId,
          builder: (BuildContext context, AsyncSnapshot<String?> authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting &&
                authSnapshot.data == null) {
              return const _StartupProgress();
            }

            final String? userId = authSnapshot.data;
            if (userId == null) {
              return PhoneLoginScreen(authService: _authService!);
            }

            final String phoneNumber = _authService!.currentPhoneNumber ?? '';

            return _DriverSessionGate(
              key: ValueKey<String>('driver-session-$userId'),
              userId: userId,
              phoneNumber: phoneNumber,
              child: _DriverProfileGate(
                userId: userId,
                phoneNumber: phoneNumber,
                authService: _authService!,
                profileStore: _profileStore!,
              ),
            );
          },
        );
      },
    );
  }
}

class _DriverSessionGate extends StatefulWidget {
  const _DriverSessionGate({
    required this.userId,
    required this.phoneNumber,
    required this.child,
    super.key,
  });

  final String userId;
  final String phoneNumber;
  final Widget child;

  @override
  State<_DriverSessionGate> createState() => _DriverSessionGateState();
}

class _DriverSessionGateState extends State<_DriverSessionGate>
    with WidgetsBindingObserver {
  late final Future<bool> _initialValidation;
  bool _signOutScheduled = false;
  bool _resumeCheckInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialValidation = DriverSessionService.instance.validateExistingSession(
      uid: widget.userId,
      phoneNumber: widget.phoneNumber,
      forceServer: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_validateAfterResume());
    }
  }

  Future<void> _validateAfterResume() async {
    if (_resumeCheckInProgress || _signOutScheduled) {
      return;
    }

    _resumeCheckInProgress = true;

    try {
      final bool isCurrent = await DriverSessionService.instance
          .validateExistingSession(
            uid: widget.userId,
            phoneNumber: widget.phoneNumber,
            forceServer: true,
          );

      if (!isCurrent && mounted) {
        _scheduleForcedSignOut();
      }
    } finally {
      _resumeCheckInProgress = false;
    }
  }

  void _scheduleForcedSignOut() {
    if (_signOutScheduled) {
      return;
    }

    _signOutScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DriverSessionService.instance.forceLocalSignOut(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initialValidation,
      builder: (BuildContext context, AsyncSnapshot<bool> validationSnapshot) {
        if (validationSnapshot.connectionState != ConnectionState.done) {
          return const _SessionStatusScreen();
        }

        if (validationSnapshot.data != true) {
          _scheduleForcedSignOut();
          return const _SessionStatusScreen(
            message: 'This account is active on another device.',
          );
        }

        return StreamBuilder<bool>(
          stream: DriverSessionService.instance.watchSession(
            uid: widget.userId,
          ),
          builder: (BuildContext context, AsyncSnapshot<bool> sessionSnapshot) {
            if (sessionSnapshot.hasData && sessionSnapshot.data == false) {
              _scheduleForcedSignOut();
              return const _SessionStatusScreen(
                message: 'Signing out this older device…',
              );
            }

            return widget.child;
          },
        );
      },
    );
  }
}

class _SessionStatusScreen extends StatelessWidget {
  const _SessionStatusScreen({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(color: AppColors.primary),
              if (message != null) ...<Widget>[
                const SizedBox(height: 18),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverProfileGate extends StatelessWidget {
  const _DriverProfileGate({
    required this.userId,
    required this.phoneNumber,
    required this.authService,
    required this.profileStore,
  });

  final String userId;
  final String phoneNumber;
  final DriverAuthService authService;
  final DriverProfileStore profileStore;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DriverProfile?>(
      stream: profileStore.watchProfile(userId),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<DriverProfile?> profileSnapshot,
          ) {
            if (profileSnapshot.hasError) {
              return _ProfileLoadError(onSignOut: authService.signOut);
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _StartupProgress();
            }

            final DriverProfile? profile = profileSnapshot.data;
            if (profile == null || !profile.hasIdentity) {
              return DriverNameScreen(
                userId: userId,
                phoneNumber: phoneNumber,
                profileStore: profileStore,
              );
            }

            if (!profile.onboardingCompleted) {
              return BiometricOptInScreen(driverName: profile.fullName);
            }

            return DriverShell(
              driverId: profile.uid,
              driverName: profile.fullName,
              reviewStatus: profile.reviewStatus,
              registration: profile.registration,
              onSignOut: authService.signOut,
            );
          },
    );
  }
}

class _StartupProgress extends StatelessWidget {
  const _StartupProgress();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _FirebaseSetupScreen extends StatelessWidget {
  const _FirebaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded, size: 46),
              ),
              const SizedBox(height: 28),
              Text(
                'Alpha Plus could not connect',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Check your internet connection, close the app, and try '
                'again. If the problem continues, contact Alpha Plus support.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.lock_person_outlined, size: 64),
              const SizedBox(height: 22),
              Text(
                'We could not load your private driver profile.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Check your connection and confirm the Firestore security '
                'rules were deployed.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await onSignOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Return to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
