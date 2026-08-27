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
  bool _agreedToLegal = false;
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
    if (_submitting) return;
    if (!_isValid) {
      _phoneFocus.requestFocus();
      setState(() {
        _errorMessage = 'Enter a valid 9-digit South Sudan phone number.';
      });
      return;
    }

    if (!_agreedToLegal) {
      FocusScope.of(context).unfocus();
      setState(() {
        _errorMessage = 'Please accept the User Agreement and Privacy Policy.';
      });
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

  Future<void> _showLegalDetails() {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Align(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'User Agreement & Privacy',
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              const _LegalSection(
                icon: Icons.description_outlined,
                title: 'User Agreement',
                body:
                    'Use accurate account and driver information, follow local laws and safety requirements, and use Alpha Plus only for authorised transport services. Accounts may be limited when information is false, unsafe, or misused.',
              ),
              const SizedBox(height: 22),
              const _LegalSection(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                body:
                    'Alpha Plus uses your phone number, profile, driver documents, vehicle details, and trip-related location to verify your account, operate rides, provide safety features, and support you. Access is limited to what is needed for the service.',
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      authStyle: true,
      showBackButton: false,
      centerHeader: true,
      header: const AuthHeaderIcon(icon: Icons.phone_rounded),
      title: 'Enter your phone number',
      subtitle:
          'We’ll send you a verification code by SMS to confirm your number.',
      bottom: ElevatedButton(
        onPressed: _submitting ? null : _continue,
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
            enabled: !_submitting,
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
            onChanged: (_) {
              setState(() {
                if (_errorMessage?.startsWith('Enter a valid') ?? false) {
                  _errorMessage = null;
                }
              });
            },
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Checkbox(
                  key: const Key('legalConsentCheckbox'),
                  value: _agreedToLegal,
                  activeColor: AppColors.primary,
                  checkColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: _submitting
                      ? null
                      : (bool? value) {
                          setState(() {
                            _agreedToLegal = value ?? false;
                            if (_agreedToLegal &&
                                (_errorMessage?.startsWith('Please accept') ??
                                    false)) {
                              _errorMessage = null;
                            }
                          });
                        },
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Read the User Agreement and Privacy Policy',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _showLegalDetails,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text.rich(
                          TextSpan(
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(height: 1.45),
                            children: <InlineSpan>[
                              const TextSpan(text: 'I agree to Alpha Plus’s '),
                              TextSpan(
                                text: 'User Agreement',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.ink),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
