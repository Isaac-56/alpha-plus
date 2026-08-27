# Alpha Plus biometric quick unlock

This is the next page update after the agreement page. It implements optional
device biometrics for an existing driver session. It does not replace Firebase
phone authentication, approve drivers, or deploy any backend changes.

## What is implemented

- Onboarding: a real fingerprint/face prompt, with capability and enrollment
  checks. Not now continues without opting in. Cancel or failure does not enable.
- A local preference for each driver UID on this installation; an unlock grant
  is kept only in memory, not stored as a successful authentication.
- A lock above the entire navigation stack on startup and after leaving the app.
  Hidden pages cannot receive taps, keyboard focus, or accessibility focus.
- Interrupted or stale native results cannot unlock after backgrounding or an
  account change. A native dialog's temporary inactive event is handled without
  repeatedly starting prompts. Unlock is started by tapping the Unlock button.
- Sign out and verify by phone: actual local Firebase sign-out, followed by the
  existing phone flow. Only successful phone authentication AND session activation
  grant access for that visit. The saved preference remains enabled for later visits.
- Profile > Settings > Quick unlock: enable or turn off with confirmation. A
  fresh phone sign-in can authorize turning it off if biometrics no longer work.
- Navigation is reset when the authenticated UID changes or signs out, removing
  any old private pages above the login screen.

Fingerprint/face checks use biometrics already enrolled on the device, not the
driver photo-check selfie. They do not prove that an enrolled biometric belongs
to the approved driver. Alpha Plus receives a success/failure result, not a
biometric template. The separate photo-review flow is unchanged.

## Compatibility and limits

The maintained Flutter [local_auth 3.0.2 package](https://pub.dev/packages/local_auth/versions/3.0.2)
requires Android API 24 (Android 7) or newer. The installer raises a lower minSdk
to 24 and preserves any higher setting. Older Android devices cannot install
this build. Existing Flutter/Firebase versions are not intentionally upgraded.

The Android setup adds USE_BIOMETRIC, changes the active MainActivity to
FlutterFragmentActivity, and updates LaunchTheme/NormalTheme parents across
light/dark and Android 12 resources while preserving splash colors and artwork.
See the [official Android setup](https://pub.dev/packages/local_auth_android).

An iOS Face ID usage description is added as well, following the
[official iOS setup](https://pub.dev/packages/local_auth_darwin). This does not
configure Firebase for iOS or certify an iOS build. The current app remains an
Android testing target. Web, desktop, and unsupported devices do not receive
biometric access through this feature.

This is an optional local UI lock, not encrypted document storage, a
hardware-backed credential vault, or a server authorization boundary. The only
saved value is the opt-in preference; Firebase continues to manage its session.
The preference uses the existing shared_preferences dependency and is not a
tamper-proof security record. See its [storage limitations](https://pub.dev/packages/shared_preferences).
Backend rules, session enforcement, and private-document protections remain
necessary. Android screenshots/task-switcher snapshot hardening and cryptographic
binding to an unchanged biometric enrollment set are not part of this patch.

## Apply with the installer

First apply the preceding agreement-page ZIP if you have not done so. The
installer checks that those files, the map-camera helper, and the Maps key loader
exist before making changes. If you've edited main.dart, the auth service, the
biometric screen, or widget_test.dart since the supplied updates, compare those
replacement files before applying this patch.

Stop `flutter run` with `q`, download this ZIP to Downloads, then run:

```powershell
$biometricUpdate = Join-Path $env:USERPROFILE 'Downloads\AlphaPlus-biometric-unlock-v1'
Expand-Archive -LiteralPath "$env:USERPROFILE\Downloads\AlphaPlus-biometric-unlock-v1.zip" -DestinationPath $biometricUpdate -Force
& "$biometricUpdate\APPLY_BIOMETRICS.ps1" -ProjectPath 'C:\Projects\alpha_plus'
```

Use the script, not just a lib/test copy: it also merges the native requirements.
It prepares edits in memory, makes a timestamped backup beside the project, then:

1. Adds `local_auth: ^3.0.2` to pubspec without replacing other dependencies.
2. Makes the targeted Android/iOS edits described above, preserving the Maps
   key loader, signing configuration, location/camera permissions, and artwork.
3. Adds the Settings entry to your existing driver_detail_screens.dart instead
   of replacing that file with a snapshot.
4. Copies the six application files, tests, and guides.
5. Runs pub get, Dart format, analysis, tests, whitespace checks, and a debug APK build.

It does not read or print the local Maps key file, commit, push, or deploy. It
stops if it finds an unexpected native configuration. Do not bypass that check;
send the reported message without API keys. A check failure after copying leaves
the changes applied and the backup available for review.

After the script succeeds:

```powershell
cd C:\Projects\alpha_plus
flutter run
```

A full rebuild is required; hot reload cannot register a new native plugin.

## Required device checks before pushing

Use a test driver account. A completed driver can access the feature through
Profile > Settings > Quick unlock; there is no need to reset onboarding.

1. Cancel the enable prompt. Confirm the setting stays off. During onboarding,
   Not now must still work and must not enable anything.
2. Enable with a device fingerprint/face and confirm the setting shows enabled.
3. Leave Alpha Plus and return. Confirm the lock appears and Cancel keeps it
   locked. Unlock successfully.
4. Open a profile/detail page, background the app, and return. Confirm that page
   is hidden until authentication. Back must not expose another private page.
5. Start unlocking, then press Home before finishing. Return and retry; a late
   result from the old prompt must not unlock automatically.
6. Close/restart the app. Confirm the saved preference still requires unlock.
7. From the lock, choose Sign out and verify by phone. Complete real phone
   verification and confirm you can enter. Leave/return: the lock should resume.
8. Turn quick unlock off in Settings. Cancel the confirmation first, then
   confirm. Check that returning to the app no longer requires this local lock.
9. With a second test device, sign into the same driver account. Verify the old
   session signs out even if its biometric prompt or a detail page is open.
   The existing cloud-session system must be working for this check.
10. Check missing enrollment, device lockout, larger text, light/dark mode,
    navigation, Maps, document camera, and the existing photo check.

When the OS temporarily disables biometrics, unlock the device normally or use
the phone fallback. This feature does not silently accept the device PIN as a
biometric check. It does not stop or approve live-driver GPS operations; those
remain under the existing availability/session flow and the paused backend work.

## Validation performed here

- Dart and PowerShell syntax parsing; Kotlin/XML checks on reconstructed edits.
- Import resolution against the current update chain and patch-scope checks.
- Existing widget tests retained; controller and widget regression tests added
  for cancellation, late results, account replacement, persistence, failed
  storage, resume, SMS recovery, route coverage, settings, and narrow layouts.
- Package integrity and credential-pattern scans.

Flutter, Dart, PowerShell, and a native phone runtime are not installed in the
preparation workspace. The installer itself, Flutter analysis/tests, native
builds, real OS prompts, Firebase recovery, and two-device behavior have NOT
been executed here. The static checks are not a substitute for the steps above.

## Manual commit

After all local checks and the device checks pass, inspect your diff in VS Code.
Stage only this update's code, tests, guides, dependency files, and targeted
native changes. Never stage android/secrets.properties or a backup directory.
Review any additional native files changed automatically by Flutter separately.

```powershell
git status
git diff --stat
git diff --check
```

Commit message:

```text
Add biometric quick unlock and protect driver navigation
```

After staging the reviewed files, you can run:

```powershell
git diff --cached --check
git commit -m "Add biometric quick unlock and protect driver navigation"
git push origin main
git status
```

Realtime Database setup remains paused. No Firebase deploy command is required
for this local biometric update.
