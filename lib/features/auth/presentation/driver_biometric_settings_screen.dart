import 'package:flutter/material.dart';

import '../../../core/widgets/onboarding_scaffold.dart';
import '../data/driver_biometric_controller.dart';

class DriverBiometricSettingsTile extends StatelessWidget {
  const DriverBiometricSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: const Key('openQuickUnlockSettings'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.fingerprint_rounded),
      title: const Text('Quick unlock'),
      subtitle: const Text('Fingerprint or face on this device'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const DriverBiometricSettingsScreen(),
        ),
      ),
    );
  }
}

class DriverBiometricSettingsScreen extends StatefulWidget {
  const DriverBiometricSettingsScreen({this.controller, super.key});
  final DriverBiometricController? controller;

  @override
  State<DriverBiometricSettingsScreen> createState() =>
      _DriverBiometricSettingsScreenState();
}

class _DriverBiometricSettingsScreenState
    extends State<DriverBiometricSettingsScreen> {
  late final DriverBiometricController _controller =
      widget.controller ?? DriverBiometricController.instance;
  String? _message;

  Future<void> _change() async {
    if (_controller.busy) return;
    setState(() => _message = null);
    final bool enabling = !_controller.enabled;
    final DriverBiometricResult result = enabling
        ? await _controller.enable()
        : await _controller.disable();
    if (!mounted) return;
    setState(() {
      _message = result == DriverBiometricResult.success
          ? enabling
                ? 'Quick unlock enabled.'
                : 'Quick unlock turned off.'
          : driverBiometricMessage(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) => PopScope(
        canPop: !_controller.busy,
        child: OnboardingScaffold(
          authStyle: true,
          centerHeader: true,
          showBackButton: Navigator.of(context).canPop(),
          header: const AuthHeaderIcon(icon: Icons.fingerprint_rounded),
          title: 'Quick unlock',
          subtitle: _controller.enabled
              ? 'Enabled for this account on this device.'
              : 'Currently turned off.',
          bottom: ElevatedButton(
            key: const Key('changeQuickUnlock'),
            onPressed:
                !_controller.ready ||
                    _controller.uid == null ||
                    _controller.busy ||
                    _controller.mustUnlock
                ? null
                : _change,
            child: _controller.busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    _controller.enabled
                        ? 'Turn off quick unlock'
                        : 'Enable quick unlock',
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'When enabled, your driver pages are locked after you leave the app '
                'and when it starts again. Unlocking uses the biometrics enrolled '
                'on this device.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 20),
              const Text(
                'Turning it off requires confirmation with biometrics or a fresh '
                'phone sign-in. This preference does not transfer to another phone.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 20),
              const Text(
                'Phone verification and single-device sessions still apply. '
                'Quick unlock does not create a Firebase session or approve a driver.',
                style: TextStyle(height: 1.6),
              ),
              if (_message != null) ...<Widget>[
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _message!,
                    key: const Key('quickUnlockSettingsMessage'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
