# Alpha Plus photo check

The Photo check page now uses a fresh front-camera capture. Before upload, the
app checks photo quality and uses on-device ML Kit face detection to require one
usable, front-facing face. A successful automatic check is submitted as
`pending`; it is not treated as final identity approval.

## One-time backend deployment

The Firebase project owner runs these commands once after installing this
update. End users do not run them.

```powershell
cd C:\Projects\alpha_plus
firebase deploy --only firestore:rules,storage --project alpha-ride-29708
```

The app writes the review record to `driver_photo_checks/{driverUid}` and the
private image to
`drivers/{driverUid}/documents/photo_checks/{captureId}.jpg`.

## Run and verify

```powershell
cd C:\Projects\alpha_plus
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Verify these cases on a physical Android phone:

1. Deny camera permission: the app must show a retry/settings message and must
   not mark the check complete.
2. Capture no face or multiple faces: the photo must be rejected locally.
3. Capture a dark, blurry, distant, or turned face: the app must ask for a
   retake.
4. Capture one clear face: the app must enable **Submit photo check**.
5. Submit: the page must show **Review in progress** only after Firebase upload
   and Firestore write both succeed.

## Production note

Single-image face detection is quality and face-presence screening, not strong
anti-spoof liveness verification. Before fully automatic production approval,
add a trusted backend/admin review or a dedicated challenge/video liveness
provider. Never let the mobile client set its own final `approved` status.
