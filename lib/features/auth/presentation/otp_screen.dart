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

  bool get _busy => _submitting || _resending;

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
    if (_busy) return;
    setState(() => _errorMessage = null);
    if (code.length != 6) {
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
      _timer?.cancel();
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _controller.clear();
      setState(() {
        _submitting = false;
        _errorMessage = readableAuthError(error);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_busy) _focusNode.requestFocus();
      });
    }
  }

  Future<void> _resendCode() async {
    if (_busy || _remainingSeconds > 0) {
      return;
    }

    setState(() {
      _resending = true;
      _errorMessage = null;
    });
    FocusScope.of(context).unfocus();

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
        _timer?.cancel();
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        return;
      }

      setState(() {
        _controller.clear();
        _verificationId = session.verificationId;
        _resendToken = session.resendToken;
        _resending = false;
      });
      _startTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_busy) _focusNode.requestFocus();
      });
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
      authStyle: true,
      centerHeader: true,
      header: const AuthHeaderIcon(icon: Icons.sms_outlined),
      title: 'Verify your number',
      subtitle:
          'Enter the six-digit code sent by SMS to\n${widget.phoneNumber}.',
      bottom: ElevatedButton(
        key: const Key('verifyOtpButton'),
        onPressed: _controller.text.length == 6 && !_busy
            ? () => _handleCode(_controller.text)
            : null,
        child: _submitting
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Text('Verify and continue', textAlign: TextAlign.center),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AutofillGroup(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _busy ? null : _focusNode.requestFocus,
              child: Stack(
                children: <Widget>[
                  ExcludeSemantics(
                    child: Row(
                      children: <Widget>[
                        for (int index = 0; index < 6; index++) ...<Widget>[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(
                            child: Builder(
                              builder: (BuildContext context) {
                                final String value =
                                    index < _controller.text.length
                                    ? _controller.text[index]
                                    : '';
                                final bool active =
                                    !_busy && index == _controller.text.length;
                                final bool filled = value.isNotEmpty;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 58,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: filled
                                        ? AppColors.primary.withValues(
                                            alpha: 0.10,
                                          )
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _errorMessage != null
                                          ? Theme.of(context).colorScheme.error
                                          : active || filled
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSurface
                                          : Theme.of(context).dividerColor,
                                      width: active ? 1.5 : 1,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      value,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontSize: 24,
                                            height: 1,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0,
                      alwaysIncludeSemantics: true,
                      child: Semantics(
                        label: 'Six-digit verification code',
                        child: TextField(
                          key: const Key('otpField'),
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          enabled: !_busy,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          showCursor: false,
                          autofillHints: const <String>[
                            AutofillHints.oneTimeCode,
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            counterText: '',
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: _handleCode,
                          onSubmitted: _handleCode,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          if (_errorMessage != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Container(
                key: const Key('otpError'),
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
            ),
            const SizedBox(height: 18),
          ],
          Text(
            _remainingSeconds > 0
                ? 'Request a new code in 00:$seconds'
                : 'Didn’t receive the code?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Align(
            child: TextButton.icon(
              key: const Key('resendOtpButton'),
              onPressed: _remainingSeconds == 0 && !_busy ? _resendCode : null,
              icon: _resending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sms_outlined),
              label: Text(_resending ? 'Sending…' : 'Resend code'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
