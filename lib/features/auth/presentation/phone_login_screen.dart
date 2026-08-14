import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();

  bool get _isValid => _phoneController.text.length == 9;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_isValid) {
      _phoneFocus.requestFocus();
      return;
    }

    final String number = _phoneController.text.replaceAll(' ', '');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(phoneNumber: '+211 $number'),
      ),
    );
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
        onPressed: _isValid ? _continue : null,
        child: const Text('Continue'),
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
          Text(
            'By continuing, you accept the Alpha + User Agreement and Privacy Policy.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
