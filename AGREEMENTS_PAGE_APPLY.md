# Alpha Plus agreement page update

This patch follows the working authentication pages, Maps build repair, and
map-logo position update. It contains only five application Dart files, the
updated widget tests, this guide, and the page queue.

## What changes

- The agreement page uses the same heading, spacing, button, and light/dark
  styling as the phone, OTP, and name pages.
- The required acknowledgement and optional product updates start unchecked.
  Product updates are not required to continue.
- Agreement, privacy, and updates links open a scrollable reader. Reading or
  closing a document does not select a checkbox.
- Phone login uses the same legal-summary reader. Phone validation, SMS
  requests, OTP routing, and its consent gate are unchanged.
- Continue saves the choices to the signed-in driver's existing Firestore
  profile before opening service registration. Duplicate taps are blocked.
- A save failure preserves choices, reveals the error, and allows retry.

These are the existing onboarding summaries, not final published contracts or
privacy notices. The screen labels them as summaries. Before public launch,
the owner must supply approved full policies and complete policy versioning,
acceptance, and backend enforcement. This patch does not claim legal compliance.

## Apply

1. Stop the current `flutter run` with `q`.
2. Make a backup before replacing files. For example, in PowerShell:

```powershell
cd C:\Projects\alpha_plus
$agreementBackup = Join-Path (Split-Path (Get-Location).Path -Parent) ("alpha_plus-before-agreements-" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $agreementBackup | Out-Null
Copy-Item -Path .\lib, .\test -Destination $agreementBackup -Recurse
```

3. Extract `AlphaPlus-agreements-page-v1.zip`.
4. Copy its `lib` and `test` folders into `C:\Projects\alpha_plus`, merging
   folders and replacing the included files. Do not delete your existing
   `lib` or `test` folders. Copy both Markdown files to the project root too.
5. If you have made additional code changes since the map-logo update, compare
   the three replacement files first: `agreements_screen.dart`,
   `phone_login_screen.dart`, and `test/widget_test.dart`.

No Android/iOS build files, manifest, Maps settings, Firebase configuration,
security rules, dependencies, sessions, or map source are included. Your local
Maps key is not needed and must not be copied into this package or Git.

## Verify locally

Run these one at a time. Stop and share the output if any command fails.

```powershell
cd C:\Projects\alpha_plus
dart format lib\features\auth test\widget_test.dart
flutter analyze
flutter test
git diff --check
flutter run
```

Flutter/Dart are not installed in the preparation environment. Dart syntax
parsing, relative-import resolution, patch-scope checks, existing-test
preservation, ZIP integrity, and credential-pattern scans were performed;
Flutter analysis, widget tests, an Android build, visual checks, and a real
Firestore save still need to be run on your machine.

## Check on a test account

Use a separate signed-in test driver with an existing draft/pending profile
whose onboarding is unfinished. After name entry, select **Not now** on the
biometric screen to reach Agreements. A completed driver goes to the dashboard
and will not automatically see this page. Do not delete a real account, reset
onboarding, change approval status, or bypass authentication just to view it.

1. Confirm both checkboxes start off and Continue is disabled.
2. Open all three readers and return. Confirm reading did not select consent.
3. Select product updates alone: Continue must remain disabled.
4. Clear updates, select the required acknowledgement, then Continue.
5. Confirm it advances only after saving. In the test driver's Firestore
   document, check that the version/timestamp exist and productUpdates is false.
6. If you repeat with updates selected, verify the preference becomes true.
7. For a failure check, disconnect the test device before Continue. After the
   save timeout, confirm the error becomes visible, selections remain, and
   service registration has not opened. Reconnect and retry.
8. Check light/dark mode, larger text, scrolling, and the Back/Done buttons.

The biometric page is unchanged and still needs actual OS authentication;
selecting its existing Enable button does not yet enable a real biometric lock.

## Existing Firestore connection only

This patch does not use the paused Realtime Database. Do not run a Firebase
deployment for this page update. It uses the existing signed-in driver's
`drivers/{uid}` Firestore document with these fields:

```text
onboardingAcknowledgement.documentKind = onboarding_summary
onboardingAcknowledgement.version = onboarding-summary-2026-08-27-v1
onboardingAcknowledgement.acknowledged = true
onboardingAcknowledgement.recordedAt = server timestamp
communicationPreferences.productUpdates = true or false
communicationPreferences.updatedAt = server timestamp
```

The write updates the existing profile and preserves unrelated fields and
preferences. It does not create a missing profile or change identity, review
status, registration, or onboarding completion. The current local driver rules
permit owner updates to draft/pending profiles; live rule deployment was not
verified here. If permission is denied, retain the rules and report the error;
do not change them to allow unrestricted access.

The record is a mutable onboarding acknowledgement, not an immutable legal
consent audit. A production updates sender and a settings control to change
that optional preference are not part of this patch.

The UI stops waiting after 20 seconds, but a queued Firestore write may still
finish later. Timeout means the save was not confirmed in time, not that it
was cancelled. The UI will not advance without a successful attempt. Retrying
submits the current choices again. See [Firestore update behavior](https://pub.dev/documentation/cloud_firestore/latest/cloud_firestore/DocumentReference/update.html)
and [Dart timeout behavior](https://api.dart.dev/dart-async/Future/timeout.html).

## Manual Git commit

Only after the checks and device test pass, review `git status` and your diff.
Stage this patch explicitly:

```powershell
git add lib/features/auth/data/driver_agreement_store.dart lib/features/auth/data/driver_legal_content.dart lib/features/auth/presentation/driver_legal_details_screen.dart lib/features/auth/presentation/agreements_screen.dart lib/features/auth/presentation/phone_login_screen.dart test/widget_test.dart AGREEMENTS_PAGE_APPLY.md ALPHA_PLUS_PAGE_QUEUE.md
git diff --cached --stat
git diff --cached --check
git commit -m "Finish driver agreement page and save onboarding choices"
git push origin main
git status
```

Nothing has been committed, pushed, or deployed by this patch.
