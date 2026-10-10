# Alpha Plus: phone, OTP and name pages

This is the first page-consistency pass after pausing database setup. It does
not claim that every driver page is finished. The remaining work is recorded
in ALPHA_PLUS_PAGE_QUEUE.md, which the installer copies into the project.

## What changes

The three pages use the passenger app's heading, supporting text and primary
button sizes. Their header icons and centered alignment are consistent, and
decorative icons collapse when the keyboard opens. The form width is limited
on larger screens. Other onboarding pages keep their existing visual settings
unless they explicitly opt into the new auth layout.

OTP keeps the existing Firebase authentication service and automatic submission
after six digits. It adds a visible Verify and continue button, an SMS autofill
hint, accessible input labeling, flexible digit slots, and safe handling of
resend/verification overlap. Resending successfully clears the old digits and
uses the new verification session. SMS autofill depends on the device and OS;
the hint does not guarantee that a code will be filled automatically.

Name entry keeps separate first/last fields to match the driver profile. It no
longer removes accented or non-Latin characters. Each field is capped at 80
characters, names are trimmed before saving, and fields cannot change while a
save is in progress. The existing minimum of two characters per name remains.

## Apply outside the project

Save AlphaPlus-auth-pages-v1.zip in Downloads, then run PowerShell:

```powershell
$pages = Join-Path $env:USERPROFILE 'Downloads\AlphaPlus-auth-pages-v1'
Expand-Archive -LiteralPath "$env:USERPROFILE\Downloads\AlphaPlus-auth-pages-v1.zip" -DestinationPath $pages -Force
& "$pages\APPLY_PAGES.ps1" -ProjectPath 'C:\Projects\alpha_plus'
```

Do not copy the extracted package directory into alpha_plus. The script checks
the project, backs up the affected files beside it, installs the scoped update,
and runs dependency resolution, formatting, analysis, tests, and whitespace
checks. It stops on failure and does not stage, commit, deploy, or push.

If PowerShell blocks execution, send the error without changing a managed policy.

## Verify on your phone

After the script reports AUTH PAGE CHECKS PASSED:

```powershell
cd C:\Projects\alpha_plus
flutter run
```

Check phone login, the agreement checkbox, OTP input/resend, and name entry in
light and dark mode. Check with the keyboard open and with larger system text.
Use an existing Firebase test number for repeated OTP checks if available.
Send the analysis/test output and screenshots before the next page pass.

## No database deployment

There is no Firebase deployment command for this package. It does not replace
main.dart, Firebase options, API keys, database rules, the map/dashboard, the
session service, document checking, or photo verification. No new package
dependencies are required.

The existing uncommitted live-driver changes are left alone. Once the page
checks pass, review and stage only this page update:

```powershell
git diff --stat
git add lib/core/widgets/onboarding_scaffold.dart lib/features/auth/presentation/phone_login_screen.dart lib/features/auth/presentation/otp_screen.dart lib/features/auth/presentation/driver_name_screen.dart test/widget_test.dart ALPHA_PLUS_PAGE_QUEUE.md
git diff --cached --stat
git commit -m "Align Alpha Plus phone OTP and name pages with Alpha Ride"
git push origin main
```

Do not use git add . here: the paused live-driver work may still be uncommitted.
Review anything already staged before committing.

## Verification status

The source was checked with a Dart syntax parser, relative imports were checked
against the existing project, and the package was checked for unintended files
and secret patterns. Focused widget tests were added to the existing test suite
for request overlap/recovery, renewed OTP sessions, international names, and
narrow-screen/keyboard layouts in both themes.

Flutter/Dart execution, rendered screen verification, and the PowerShell
installer could not be run in this preparation environment. The installer runs
the required Flutter checks on your machine; a phone check is still required.

The autofill integration uses Flutter's documented
[one-time-code hint](https://api.flutter.dev/flutter/services/AutofillHints/oneTimeCode-constant.html).
