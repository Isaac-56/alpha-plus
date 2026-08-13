import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/onboarding_scaffold.dart';
import 'biometric_opt_in_screen.dart';

class DriverNameScreen extends StatefulWidget {
  const DriverNameScreen({super.key});

  @override
  State<DriverNameScreen> createState() => _DriverNameScreenState();
}

class _DriverNameScreenState extends State<DriverNameScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();

  bool get _isValid =>
      _firstName.text.trim().length >= 2 && _lastName.text.trim().length >= 2;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BiometricOptInScreen(
          driverName: '${_firstName.text.trim()} ${_lastName.text.trim()}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'What should we call you?',
      subtitle: 'Use the name shown on your official driver documents.',
      bottom: ElevatedButton(
        onPressed: _isValid ? _continue : null,
        child: const Text('Next'),
      ),
      child: AutofillGroup(
        child: Column(
          children: <Widget>[
            TextField(
              key: const Key('firstNameField'),
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.givenName],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z '\-]")),
              ],
              decoration: const InputDecoration(
                labelText: 'First name',
                hintText: 'Enter your first name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('lastNameField'),
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.familyName],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z '\-]")),
              ],
              decoration: const InputDecoration(
                labelText: 'Last name',
                hintText: 'Enter your last name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_isValid) {
                  _continue();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
