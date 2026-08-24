import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/onboarding_scaffold.dart';
import '../data/driver_auth_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
    this.authService,
    super.key,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  final DriverAuthService? authService;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _remainingSeconds = 30;
  late final DriverAuthService _authService;
  late String _verificationId;
  int? _resendToken;
  bool _submitting = false;
  bool _resending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? FirebaseDriverAuthService();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingSeconds != 30) {
      setState(() => _remainingSeconds = 30);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _handleCode(String code) async {
    setState(() {});
    if (code.length != 6 || _submitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await _authService.verifyCode(
        verificationId: _verificationId,
        smsCode: code,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _controller.clear();
      _focusNode.requestFocus();
      setState(() {
        _submitting = false;
        _errorMessage = readableAuthError(error);
      });
    }
  }

  Future<void> _resendCode() async {
    if (_resending || _remainingSeconds > 0) {
      return;
    }

    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    try {
      final String compactPhone = widget.phoneNumber.replaceAll(' ', '');
      final PhoneVerificationSession session = await _authService.requestCode(
        phoneNumber: compactPhone,
        forceResendingToken: _resendToken,
      );
      if (!mounted) {
        return;
      }

      if (session.automaticallyVerified) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        return;
      }

      setState(() {
        _verificationId = session.verificationId;
        _resendToken = session.resendToken;
        _resending = false;
      });
      _startTimer();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _resending = false;
          _errorMessage = readableAuthError(error);
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String seconds = _remainingSeconds.toString().padLeft(2, '0');

    return OnboardingScaffold(
      title: 'Verify your number',
      subtitle:
          'Enter the six-digit code sent by SMS to ${widget.phoneNumber}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusNode.requestFocus,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double boxWidth = ((constraints.maxWidth - 40) / 6)
                    .clamp(38, 48)
                    .toDouble();

                return Stack(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List<Widget>.generate(6, (int index) {
                        final String value = index < _controller.text.length
                            ? _controller.text[index]
                            : '';
                        final bool active =
                            index == _controller.text.length ||
                            (index == 5 && _controller.text.length == 6);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: boxWidth,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : Theme.of(context).dividerColor,
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            value,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        );
                      }),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.01,
                        child: TextField(
                          key: const Key('otpField'),
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          showCursor: false,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: _handleCode,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 26),
          if (_submitting) ...<Widget>[
            const LinearProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 18),
          ],
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
            const SizedBox(height: 18),
          ],
          Text(
            _remainingSeconds > 0
                ? 'You can request another code in 00:$seconds'
                : 'Didn’t receive the code?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _remainingSeconds == 0 && !_resending
                ? _resendCode
                : null,
            icon: _resending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sms_outlined),
            label: Text(_resending ? 'Sending…' : 'Resend by SMS'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
