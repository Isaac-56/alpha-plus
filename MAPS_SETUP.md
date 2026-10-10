# Alpha Plus Maps setup

Alpha Plus uses a dedicated Google Maps Platform API key at Android build
time. The compiled APK contains the key, so drivers installing the app do not
need to configure anything.

## Google Cloud key restrictions

In the same Google Cloud project used by the app:

1. Enable **Maps SDK for Android**.
2. Restrict the key to **Android apps**.
3. Add package name `com.alpharide.driver`.
4. Add the SHA-1 fingerprint for every certificate used to sign the app.
5. Under API restrictions, allow only **Maps SDK for Android**.

The current debug certificate fingerprint is:

`3A:6A:84:46:2B:B9:85:F1:1C:6A:F8:4A:E9:61:E3:B9:DE:25:B5:C4`

Before publishing, also add the SHA-1 fingerprint of the release or Google
Play App Signing certificate.

## Local configuration

From the project root in PowerShell:

```powershell
Copy-Item .\android\secrets.properties.example `
  .\android\secrets.properties

notepad .\android\secrets.properties
```

Replace the placeholder with the Maps key and save the file:

```properties
MAPS_API_KEY=PASTE_YOUR_RESTRICTED_ANDROID_MAPS_KEY_HERE
```

Then rebuild the app:

```powershell
flutter clean
flutter pub get
flutter run
```

For CI or another build machine, set the `MAPS_API_KEY` environment variable
instead of creating `android/secrets.properties`.

## Security notes

- `android/secrets.properties` is ignored by Git.
- Do not paste the real key into Dart, `AndroidManifest.xml`, chat, screenshots,
  or GitHub.
- Android application restrictions are essential because API keys embedded in
  mobile apps can be extracted from an APK.
