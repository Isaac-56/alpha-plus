import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/onboarding_scaffold.dart';
import '../data/driver_biometric_controller.dart';

/// Placed above the root Navigator, so pushed routes are covered as well.
class DriverBiometricGate extends StatefulWidget {
  const DriverBiometricGate({
    required this.controller,
    required this.onPhoneSignIn,
    required this.child,
    super.key,
  });

  final DriverBiometricController controller;
  final Future<void> Function() onPhoneSignIn;
  final Widget child;

  @override
  State<DriverBiometricGate> createState() => _DriverBiometricGateState();
}

class _DriverBiometricGateState extends State<DriverBiometricGate>
    with WidgetsBindingObserver {
  final GlobalKey _messageAnchor = GlobalKey();
  bool _signingOut = false;
  String? _message;
  String? _messageUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_changed);
    final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    if (state != null) widget.controller.handleLifecycle(state);
  }

  @override
  void didUpdateWidget(DriverBiometricGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  void _changed() {
    if (!mounted) return;
    if (_messageUid != widget.controller.uid) {
      _message = null;
      _messageUid = widget.controller.uid;
    }
    if (widget.controller.coverApp) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.controller.handleLifecycle(state);
  }

  Future<void> _unlock() async {
    setState(() => _message = null);
    final String? uid = widget.controller.uid;
    final DriverBiometricResult result = await widget.controller.unlock();
    if (!mounted || widget.controller.uid != uid) return;
    setState(() {
      _messageUid = uid;
      _message = result == DriverBiometricResult.success
          ? null
          : driverBiometricMessage(result);
    });
    _revealMessage();
  }

  void _revealMessage() {
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

  Future<void> _phoneSignIn() async {
    if (_signingOut) return;
    setState(() {
      _signingOut = true;
      _message = null;
    });
    widget.controller.prepareForPhoneSignIn();
    try {
      // This must actually sign out, not simply navigate around the lock.
      await widget.onPhoneSignIn();
    } on Object {
      if (mounted) {
        setState(() => _message = 'Could not sign out. Please try again.');
        _revealMessage();
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DriverBiometricController controller = widget.controller;
    final bool covered = controller.coverApp || _signingOut;
    final bool loading = !controller.ready || _signingOut;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Offstage(
          offstage: covered,
          child: ExcludeFocus(
            excluding: covered,
            child: ExcludeSemantics(excluding: covered, child: widget.child),
          ),
        ),
        if (covered)
          OnboardingScaffold(
            key: const Key('driverBiometricLock'),
            authStyle: true,
            centerHeader: true,
            showBackButton: false,
            header: const AuthHeaderIcon(icon: Icons.lock_outline_rounded),
            title: controller.loadFailed
                ? 'Check quick-unlock settings'
                : 'Unlock Alpha Plus',
            subtitle: controller.loadFailed
                ? 'Your saved preference could not be confirmed. Access remains locked.'
                : 'Use your device biometrics to open your driver account.',
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ElevatedButton(
                  key: const Key('unlockDriverApp'),
                  onPressed: loading || controller.busy
                      ? null
                      : controller.loadFailed
                      ? () => unawaited(controller.retryLoading())
                      : _unlock,
                  child: loading || controller.busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(controller.loadFailed ? 'Try again' : 'Unlock'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('biometricPhoneSignIn'),
                  onPressed: _signingOut ? null : _phoneSignIn,
                  child: const Text('Sign out and verify by phone'),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                const Text(
                  'Phone verification remains available if biometrics are unavailable. '
                  'Quick unlock cannot restore a session ended on another device.',
                  textAlign: TextAlign.center,
                ),
                if (_message != null) ...<Widget>[
                  const SizedBox(height: 20),
                  Semantics(
                    key: _messageAnchor,
                    liveRegion: true,
                    child: Text(
                      _message!,
                      key: const Key('biometricLockMessage'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
