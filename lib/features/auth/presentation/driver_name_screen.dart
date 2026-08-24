import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/onboarding_scaffold.dart';
import '../../profile/data/driver_profile_repository.dart';

class DriverNameScreen extends StatefulWidget {
  const DriverNameScreen({
    this.userId,
    this.phoneNumber,
    this.profileStore,
    super.key,
  });

  final String? userId;
  final String? phoneNumber;
  final DriverProfileStore? profileStore;

  @override
  State<DriverNameScreen> createState() => _DriverNameScreenState();
}

class _DriverNameScreenState extends State<DriverNameScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  late final DriverProfileStore _profileStore;
  bool _saving = false;
  String? _errorMessage;

  bool get _isValid =>
      _firstName.text.trim().length >= 2 && _lastName.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _profileStore = widget.profileStore ?? FirebaseDriverProfileStore();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_isValid || _saving) {
      return;
    }

    User? currentUser;
    if (widget.userId == null || widget.phoneNumber == null) {
      currentUser = FirebaseAuth.instance.currentUser;
    }
    final String? userId = widget.userId ?? currentUser?.uid;
    final String phoneNumber =
        widget.phoneNumber ?? currentUser?.phoneNumber ?? '';

    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = 'Your sign-in session expired. Please sign in again.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _profileStore.saveIdentity(
        uid: userId,
        phoneNumber: phoneNumber,
        firstName: _firstName.text,
        lastName: _lastName.text,
      );
      if (!mounted) {
        return;
      }
    } on Object {
      if (mounted) {
        setState(() {
          _errorMessage =
              'We could not save your profile. Check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'What should we call you?',
      subtitle: 'Use the name shown on your official driver documents.',
      bottom: ElevatedButton(
        onPressed: _isValid && !_saving ? _continue : null,
        child: _saving
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Text('Next'),
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
                if (_isValid && !_saving) {
                  _continue();
                }
              },
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 16),
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
            ],
          ],
        ),
      ),
    );
  }
}
