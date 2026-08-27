# Alpha Plus work queue

Updated 27 August 2026. Finish the pages first. Database setup is paused at the
user's request and must not resume without their instruction.

## Current page pass: phone, OTP, name

Source changes prepared. Local Flutter checks and a real-device visual check
are required before calling this pass verified.

- Match Alpha Ride's authentication typography: 29 px headings, 15.5 px
  supporting copy, and 17 px primary-button labels.
- Keep the legal checkbox and real phone verification behavior.
- Add a visible OTP verification action and an SMS autofill hint.
- Prevent overlapping resend/verification requests and reset stale digits.
- Keep six OTP slots within narrow screens; preserve light/dark support.
- Hide decorative header artwork when the keyboard opens.
- Allow international names while retaining first/last name fields and the
  existing minimum-length validation.
- Prevent name editing and repeat submissions during a profile save.

## Next: agreement and biometric pages

- Driver agreement: make Read details open actual content; it currently does
  nothing. Obtain the final driver agreement and privacy text before release.
- Keep required agreement consent separate from optional product updates.
- Persist consent and notification preferences with the appropriate versions.
- Biometric opt-in: Enable quick login currently only navigates onward. Add
  real device capability checks, OS authentication, saved user choice, and
  enforcement when reopening the app. Do not claim biometrics are enabled yet.
- Add cancellation, unavailable-hardware, failure, and retry behavior without
  weakening phone authentication or the existing session check.

## Remaining page review

- Service and registration choice.
- Vehicle details and licence information.
- Document capture, quality feedback, upload and review status.
- Device permissions and completion screen.
- Profile, account settings and support.
- Money, payment availability and other placeholder actions.
- Dashboard typography and navigation, without changing the paused database work.

## Paused: shared Realtime Database and live-driver work

Verified from the user's Firebase screenshots:

- Project: alpha-ride-29708.
- Database created in Belgium (europe-west1).
- The database is empty, with default read=false/write=false rules.
- Exact endpoint: https://alpha-ride-29708-default-rtdb.europe-west1.firebasedatabase.app

Not completed:

- Configure both apps to use that exact endpoint. No URL patch was applied.
- Deploy the shared Realtime Database rules. No deployment was performed.
- Enforce driver approval and active driver sessions on the server; the current
  location rules only check UID ownership and data shape.
- Test online/offline, stationary-driver freshness, reconnection, background
  behavior, and location sharing between passenger and driver devices.
- Implement real trip dispatch, acceptance, and trip-state synchronization.

The earlier live-presence repair passed the user's analysis and all 16 tests.
That confirms those local checks, not the remaining cloud or device behavior.
