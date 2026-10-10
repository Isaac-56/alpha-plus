# Maps and ride release

The driver app uses Android package com.alpharide.driver. Release builds previously used each build machine's debug certificate, which changes the SHA-1 used by restricted Maps keys. A release built elsewhere can therefore authenticate differently. This is a configuration cause to verify, not a confirmed diagnosis of a particular phone.

Store the existing release keystore and its credentials in android/key.properties (ignored by Git):

```properties
storeFile=/absolute/path/to/existing-release.jks
storePassword=YOUR_SECRET
keyAlias=YOUR_EXISTING_ALIAS
keyPassword=YOUR_SECRET
```

Use the existing signing identity for updates, rather than generating a replacement. Store MAPS_API_KEY in android/secrets.properties or the build environment. Enable Maps SDK for Android and billing in Google Cloud. Restrict the key to com.alpharide.driver and the SHA-1 from that certificate. If distributing through Play App Signing, include the Play app-signing certificate's SHA-1 too. Register the development certificate separately for debug installs. CI_PLACEHOLDER is for build-only validation; its bundle will not display a real map.

```sh
cd android
./gradlew signingReport
cd ..
flutter build appbundle --release
```

Production release builds now require key.properties, rather than silently signing with a machine-dependent debug key. Keep credentials out of GitHub. Check adb logcat for Maps authorization failures if a correctly signed release still has blank tiles.

References: https://developers.google.com/maps/api-security-best-practices and https://developers.google.com/maps/flutter-package/config

Deploy the coordinated alpharide backend before distributing this app. Completion keeps the ride layer mounted after its active pointer disappears and displays the server's final fare, fee, earnings and receipt. A current accurate location is required to end a trip; a stale cached endpoint must not change the customer's fare. Requests/active-ride streams stay stable during UI updates. Passenger photos come from the backend's profile snapshot at acceptance.

Run flutter analyze and flutter test, including driver_completion_receipt_test.dart, then test accept/cancel/finish and immediate availability on two real phones. GitHub CI verifies the code and builds a bundle with a placeholder Maps key; it cannot validate real Maps authorization, Firebase deployment or device latency.

## Shared backend rules

Both apps use the same Firebase project. Deploy shared Firestore rules from the Alpha Ride backend repository. Keep the driver repository copy identical to that canonical file: older rules deny active_driver_rides reads and silently hide the accepted-trip controls. After deploying rules, restart both apps so failed listeners reconnect.

## Returning startup

Fixed splash waiting has been removed. A returning verified session uses a matching local cached session while the server session listener remains authoritative for login replacement. Fresh sessions still validate the account role and session. Server session reads have a six-second bound with the existing temporary-outage policy; an existing local session is not silently logged out by a slow network. Rebuild this APK to use the startup changes.
