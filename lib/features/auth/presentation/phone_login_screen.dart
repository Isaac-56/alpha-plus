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

  bool get _isValid => _phoneController.text.replaceAll(' ', '').length >= 9;

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
      title: 'Drive with Alpha+',
      subtitle:
          'Enter your phone number to sign in or create a driver account.',
      bottom: ElevatedButton(
        onPressed: _isValid ? _continue : null,
        child: const Text('Continue'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Text(
                'A+',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 42),
          Text('Phone number', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Row(
                  children: <Widget>[
                    Text('🇸🇸', style: TextStyle(fontSize: 23)),
                    SizedBox(width: 9),
                    Text(
                      '+211',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('phoneField'),
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  autofocus: false,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: const InputDecoration(
                    hintText: '912 345 678',
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _continue(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'By continuing, you accept the Alpha+ User Agreement and Privacy Policy.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
