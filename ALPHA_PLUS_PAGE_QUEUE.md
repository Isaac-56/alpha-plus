# Alpha Plus work queue

Updated 27 August 2026. Finish the pages first. Realtime Database setup remains
paused at the user's request. The user handles Git commits and pushes manually
after each tested update.

## Confirmed checkpoints

- Live-presence repair: the user reported analysis clean and all 16 tests passed.
  Cloud configuration and real presence behavior remain unverified.
- Phone, OTP, and name page pass: the user reported analysis clean and all 20
  tests passed. Consent/SMS gating, OTP retry/resend, and name validation retained.
- Maps build repair: the user's Android debug build succeeded; key loading
  restored without changing or printing the local key file.
- Map-logo positioning: the user confirmed it worked. Preserve this layout
  and native attribution clearance in later page changes.

## Previous update: agreement page and shared legal reader

Source and regression tests prepared. Syntax/scope/package checks completed;
local Flutter analysis/tests and real-device/Firestore checks are still required.

- Match the approved authentication typography, spacing, and buttons.
- Open shared agreement/privacy summaries from both login and onboarding.
- Keep required acknowledgement separate from optional product updates.
- Start both choices unchecked; reading details does not select them.
- Save summary version/timestamp and updates preference to the existing
  signed-in driver's profile before advancing; support failure and retry.
- Do not represent summaries or a mutable profile field as finalized legal
  policies, a tamper-proof audit, or a completed legal compliance system.

## Current update: biometric quick unlock

Source, installer, and tests prepared; local Flutter/Android and real-device
checks are required before this feature is considered verified.

- Real on-device biometrics, optional per-UID local opt-in, and cancellation.
- Lock above all routes when the app reopens; invalidate late native results.
- Reset navigation on account changes/logout so old private pages are removed.
- Actual local sign-out for SMS recovery, with a fresh phone/session grant.
- Profile > Settings > Quick unlock with confirmed enable/disable.
- Additive native setup preserving the Maps loader and photo/camera code.
- Android 7/API 24 minimum; iOS permission alone does not configure iOS Firebase.
- This is a local UI lock, not encrypted storage or a backend authorization check.

## Next: service and registration pages

Review the service selector and stage-one screen, then vehicle and licence
forms, keeping server/data setup paused unless the user asks to resume it.
Do not turn disabled delivery or placeholder city choices into fake features.

## Remaining page review

- Service and registration choice.
- Vehicle details and licence information.
- Document capture, quality feedback, upload and review status.
- Device permissions and completion screen.
- Profile, account settings, privacy/preferences, and support.
- Money, payment availability and other placeholder actions.
- Dashboard typography and navigation, preserving the map fix.

## Before public launch

- Obtain approved full driver terms and privacy notices, publish/version them,
  and implement the correct acceptance flow and trusted backend enforcement.
- Define the product-updates channel and allow drivers to change/withdraw the
  optional preference. Do not send product messages merely because the UI exists.
- Verify deployed Firestore/Storage rules, review permissions, session behavior,
  photo uploads, document review, and account deletion end to end.
- Rotate the previously shared Maps key before release and retain restrictions.

## Paused: shared Realtime Database and live-driver work

Last verified from the user's console screenshots:

- Project: alpha-ride-29708.
- Database created in Belgium (europe-west1).
- Empty database; default read=false/write=false rules shown.
- Endpoint: https://alpha-ride-29708-default-rtdb.europe-west1.firebasedatabase.app

Not completed:

- Configure both apps to use that exact endpoint. No URL patch was applied.
- Review and deploy shared Realtime Database rules. Deployment was not confirmed.
- Enforce driver approval and active driver sessions on the server; the current
  local location rules only check UID ownership and data shape.
- Test online/offline, stationary-driver freshness, reconnection, background
  behavior, onDisconnect races, and visibility between passenger/driver devices.
- Implement real dispatch, safe acceptance, and synchronized trip states.

Do not resume deployment or present live dispatch as working without the user's
instruction and the required backend/device verification.
