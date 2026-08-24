# Alpha Plus Firebase setup

Alpha Plus now uses Firebase Phone Authentication and Cloud Firestore. Complete
these steps once for each Firebase project before testing real SMS sign-in.

## 1. Register the Android app

1. Open the Firebase console and select the Alpha Plus project.
2. Add an Android app with this package name:

   `com.alpharide.driver`

3. From the project root, print the Android signing fingerprints:

   ```powershell
   cd C:\Projects\alpha_plus\android
   .\gradlew signingReport
   cd ..
   ```

4. In Firebase **Project settings > Your apps > Android**, add the debug
   SHA-1 and SHA-256 values shown by `signingReport`.

## 2. Generate the Flutter Firebase configuration

Install the CLIs if they are not already available:

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

From the Alpha Plus project root, run:

```powershell
cd C:\Projects\alpha_plus
dart pub global run flutterfire_cli:flutterfire configure `
  --project=YOUR_FIREBASE_PROJECT_ID `
  --platforms=android
```

Choose the Android app with package `com.alpharide.driver`. When asked whether
to overwrite `lib\firebase_options.dart`, choose **yes**. The placeholder file
included with this update exists only to show a setup screen before the real
configuration is generated.

## 3. Enable phone sign-in

1. Open **Firebase Authentication > Sign-in method**.
2. Enable **Phone**.
3. During development, add a fictional South Sudan test number and a fixed
   six-digit test code under **Phone numbers for testing**. This avoids SMS
   quota usage while you test the UI.

Real SMS verification should be tested on a physical Android device after the
SHA fingerprints are registered.

## 4. Create Firestore and deploy the private rules

1. Open **Firestore Database** and create the database.
2. Deploy the included rules from the project root:

   ```powershell
   firebase use YOUR_FIREBASE_PROJECT_ID
   firebase deploy --only firestore:rules
   ```

Each driver profile is stored at `drivers/{firebaseUid}`. The included rules
allow a signed-in driver to read and write only the document matching their own
Firebase UID.

## 5. Verify the project

```powershell
cd C:\Projects\alpha_plus
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Do not commit service-account JSON files or private server credentials. The
generated mobile Firebase options identify the Firebase app but do not grant
administrator access.
