import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../data/driver_auth_service.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({this.authService, super.key});

  final DriverAuthService? authService;

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  late final DriverAuthService _authService;
  bool _submitting = false;
  String? _errorMessage;

  bool get _isValid => _phoneController.text.length == 9;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? FirebaseDriverAuthService();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_isValid) {
      _phoneFocus.requestFocus();
      return;
    }

    final String number = _phoneController.text.replaceAll(' ', '');
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final PhoneVerificationSession session = await _authService.requestCode(
        phoneNumber: '+211$number',
      );
      if (!mounted) {
        return;
      }

      if (session.automaticallyVerified) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpScreen(
            phoneNumber: '+211 $number',
            verificationId: session.verificationId,
            resendToken: session.resendToken,
            authService: _authService,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() => _errorMessage = readableAuthError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      showBackButton: false,
      centerHeader: true,
      header: Container(
        width: 144,
        height: 144,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 104,
          height: 104,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.phone_rounded,
            size: 54,
            color: AppColors.ink,
          ),
        ),
      ),
      title: 'Enter your phone number',
      subtitle:
          'We’ll send you a verification code by SMS to confirm your number.',
      bottom: ElevatedButton(
        onPressed: _isValid && !_submitting ? _continue : null,
        child: _submitting
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Text('Continue'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Phone number',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('phoneField'),
            controller: _phoneController,
            focusNode: _phoneFocus,
            autofocus: false,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              hintText: '912 345 678',
              counterText: '',
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('🇸🇸', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      '+211',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 1,
                      height: 28,
                      color: Theme.of(context).dividerColor,
                    ),
                  ],
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _continue(),
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'By continuing, you accept the Alpha Plus User Agreement and Privacy Policy.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
