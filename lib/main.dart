import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/driver_auth_service.dart';
import 'features/auth/presentation/biometric_opt_in_screen.dart';
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

class AlphaPlusApp extends StatelessWidget {
  const AlphaPlusApp({this.firebaseInitializationError, this.home, super.key});

  final Object? firebaseInitializationError;
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alpha Plus',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeInOutCubic,
      home:
          home ??
          AppBootstrap(
            firebaseInitializationError: firebaseInitializationError,
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

            return _DriverProfileGate(
              userId: userId,
              phoneNumber: _authService!.currentPhoneNumber ?? '',
              authService: _authService!,
              profileStore: _profileStore!,
            );
          },
        );
      },
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
              driverName: profile.fullName,
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
                'Connect Alpha Plus to Firebase',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Run flutterfire configure, enable Phone Authentication, and '
                'create Firestore before testing sign-in.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              const SelectableText(
                'See FIREBASE_SETUP.md',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
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
