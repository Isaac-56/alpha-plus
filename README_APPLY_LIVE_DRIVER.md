# Apply the Alpha Plus live-driver update

This update adds the next production milestone after photo verification and
single-device sessions:

- only approved driver profiles can enable the **Online** switch in the app;
- live latitude, longitude, heading and vehicle category are published to the
  shared Firebase Realtime Database;
- AlphaRide's existing top-view vehicle marker controller can display and
  animate those drivers;
- private driver profile fields and uploaded documents are never published to
  the live-location path;
- locations older than 90 seconds are treated as offline;
- Android keeps location updates active with a visible foreground-service
  notification while the driver is online.

## 1. Copy the update

Extract this ZIP. Copy everything inside its `alpha_plus_update` folder into:

```text
C:\Projects\alpha_plus
```

Choose **Replace the files in the destination**.

The ZIP deliberately contains no API key, `google-services.json`,
`firebase_options.dart`, map secret or uploaded driver document.

## 2. Create Realtime Database once

In Firebase Console, select the shared project `alpha-ride-29708`, then open:

```text
Build > Realtime Database > Create Database
```

Choose the location nearest your users and choose **Locked mode**. If the
database already exists, skip this step.

## 3. Verify and deploy

Run in the VS Code PowerShell terminal:

```powershell
cd C:\Projects\alpha_plus

flutter pub get
dart format lib test
flutter analyze
flutter test

firebase deploy --only database --project alpha-ride-29708
```

The deploy is performed once by the developer. Drivers do not run Firebase
commands on their phones.

## 4. Approve a test driver

In Firestore, open the test driver's document and set:

```text
drivers/{driverUid}/reviewStatus = approved
```

The profile stream updates Alpha Plus automatically. The driver can then turn
the Online switch on from the Requests map.

## 5. Test the shared live map

1. Open Alpha Plus and sign in as the approved driver.
2. Open **Requests** and turn **Online** on.
3. Accept the location permission if Android asks.
4. In Firebase Realtime Database, confirm that
   `driver_locations/{driverUid}` appears.
5. Open the AlphaRide passenger app with an authenticated passenger near the
   driver. Its existing marker controller will show the correct vehicle type.
6. Turn the driver Offline and confirm the marker disappears.

## 6. Commit after verification

```powershell
git status
git add android/app/src/main/AndroidManifest.xml `
        database.rules.json `
        firebase.json `
        lib/features/dashboard/data/driver_presence_service.dart `
        lib/features/dashboard/presentation/driver_shell.dart `
        lib/main.dart `
        pubspec.yaml `
        pubspec.lock `
        test/driver_presence_policy_test.dart `
        LIVE_DRIVER_SETUP.md

git commit -m "Add approved driver live availability and GPS presence"
git push origin main
git status
```

If `pubspec.lock` did not change, remove it from the `git add` command.

