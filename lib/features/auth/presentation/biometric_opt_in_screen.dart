import 'package:flutter/material.dart';

import '../../../core/widgets/onboarding_scaffold.dart';
import '../data/driver_biometric_controller.dart';
import 'agreements_screen.dart';

class BiometricOptInScreen extends StatefulWidget {
  const BiometricOptInScreen({
    required this.driverName,
    this.controller,
    super.key,
  });

  final String driverName;
  final DriverBiometricController? controller;

  @override
  State<BiometricOptInScreen> createState() => _BiometricOptInScreenState();
}

class _BiometricOptInScreenState extends State<BiometricOptInScreen> {
  final GlobalKey _messageAnchor = GlobalKey();
  late final DriverBiometricController _controller =
      widget.controller ?? DriverBiometricController.instance;
  String? _message;
  bool _navigating = false;

  Future<void> _continue() async {
    if (_navigating || _controller.busy) return;
    setState(() => _navigating = true);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AgreementsScreen(driverName: widget.driverName),
      ),
    );
    if (mounted) setState(() => _navigating = false);
  }

  Future<void> _enable() async {
    setState(() => _message = null);
    final DriverBiometricResult result = await _controller.enable();
    if (!mounted) return;
    if (result == DriverBiometricResult.success) {
      await _continue();
    } else {
      setState(() => _message = driverBiometricMessage(result));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final BuildContext? messageContext = _messageAnchor.currentContext;
        if (messageContext != null) {
          Scrollable.ensureVisible(
            messageContext,
            alignment: 1,
            duration: const Duration(milliseconds: 250),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final bool working = _controller.busy || _navigating;
        return PopScope(
          canPop: !working,
          child: OnboardingScaffold(
            authStyle: true,
            centerHeader: true,
            showBackButton: Navigator.of(context).canPop(),
            header: const AuthHeaderIcon(icon: Icons.fingerprint_rounded),
            title: 'Unlock with your fingerprint or face',
            subtitle:
                'Optional quick access on this device after phone verification.',
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ElevatedButton(
                  key: const Key('enableDriverBiometrics'),
                  onPressed: working || !_controller.ready
                      ? null
                      : _controller.enabled
                      ? _continue
                      : _enable,
                  child: working
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(
                          _controller.enabled
                              ? 'Continue'
                              : 'Enable quick unlock',
                        ),
                ),
                if (!_controller.enabled) ...<Widget>[
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('skipDriverBiometrics'),
                    onPressed: working ? null : _continue,
                    child: const Text('Not now'),
                  ),
                ],
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _Benefit(
                  icon: Icons.lock_outline_rounded,
                  title: 'Lock when you leave',
                  body:
                      'Your driver pages stay locked when Alpha Plus reopens.',
                ),
                const _Benefit(
                  icon: Icons.fingerprint_rounded,
                  title: 'Checked by your device',
                  body:
                      'Use a fingerprint or face enrolled on this device. '
                      'Alpha Plus does not receive the biometric template.',
                ),
                const _Benefit(
                  icon: Icons.tune_rounded,
                  title: 'Your choice',
                  body:
                      'Manage Quick unlock in Profile > Settings. '
                      'You can still sign out and verify by phone.',
                ),
                if (_controller.enabled)
                  const Text(
                    'Quick unlock is enabled for this account on this device.',
                  ),
                if (_message != null)
                  Semantics(
                    key: _messageAnchor,
                    liveRegion: true,
                    child: Text(
                      _message!,
                      key: const Key('biometricOptInMessage'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
