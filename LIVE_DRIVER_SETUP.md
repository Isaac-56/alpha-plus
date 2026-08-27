# Alpha Plus live driver presence

This milestone lets an approved Alpha Plus driver go online and publish a
short-lived location to the shared Firebase Realtime Database. AlphaRide's
existing live-driver marker controller already reads `driver_locations`.

## One-time Firebase deployment

In Firebase Console, first open **Build > Realtime Database** for the shared
`alpha-ride-29708` project and create the default database if it does not
already exist. Choose the location nearest your users and start in locked mode.
Do not use test mode; this update supplies the rules.

From `C:\Projects\alpha_plus` run:

```powershell
firebase deploy --only database --project alpha-ride-29708
```

This is a one-time rules deployment, not something each driver performs.

The Android foreground-service notification keeps approved drivers' location
updates active while Alpha Plus is in the background. Going offline, signing
out, losing the active single-device session, or closing the connection removes
the active map presence.

## Approval required for testing

For a test driver, open Firestore in the Firebase console and change:

```text
drivers/{driverUid}/reviewStatus = approved
```

Only trusted staff/backend code should approve production drivers.

## What is public to signed-in app users

The live presence contains only driver ID, coordinates, heading, accuracy,
vehicle category, availability, a random presence ID, and update time. It does
not publish the driver's name, phone number, licence, plate number, or uploaded
documents.

## Verify

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
firebase deploy --only database --project alpha-ride-29708
```
