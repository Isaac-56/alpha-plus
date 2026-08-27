# Alpha Plus map attribution position

## What changes

The old map used 280-340 logical pixels of bottom padding to frame the driver
above the dashboard card. Google Maps also moves its logo and copyright by
that padding, which explains the logo appearing toward the middle of the screen.

This update separates those two concerns:

- Native attribution sits near the bottom-left edge of the map, above the
  navigation bar. A transparent 56-pixel strip beneath the dashboard card keeps
  the SDK's logo and notices unobstructed.
- The camera uses the measured header and card bounds to keep the driver's
  position in the visible map area. The actual GPS coordinates are unchanged.
- The dashboard card can scroll on short screens or with larger text.
- Existing authentication tests are preserved. Two tests cover the new layout
  clearance and camera projection.

No logo is removed, redrawn, or covered. No Firebase, API-key, Gradle, dependency,
driver-presence service, or security-rule files are included.

## Apply

1. Stop the running Flutter app with `q` in its terminal.
2. Back up these existing files outside `C:\Projects\alpha_plus`:
   - `lib\features\dashboard\presentation\driver_shell.dart`
   - `test\widget_test.dart`
3. Extract the ZIP into Downloads.
4. Copy the extracted `lib` and `test` folders directly into
   `C:\Projects\alpha_plus`. Merge the folders and choose Replace files.

Do not put an extra `AlphaPlus-map-logo-position-v1` folder inside the project.
The ZIP contains a new helper as well as the two replacements; copy both folders.

The Dart files are:

```text
lib/features/dashboard/presentation/driver_shell.dart
lib/features/dashboard/presentation/driver_map_camera.dart
test/widget_test.dart
```

## Verify

Run each command separately and stop if any command reports an error:

```powershell
cd C:\Projects\alpha_plus
dart format lib\features\dashboard\presentation\driver_shell.dart lib\features\dashboard\presentation\driver_map_camera.dart test\widget_test.dart
flutter analyze
flutter test
git diff --check
flutter run
```

On the phone, open Requests and check:

1. Google attribution is visible below the dashboard card and above the bottom
   navigation, with nothing covering it.
2. Center on my location keeps the driver in the visible map area above the card.
3. In landscape or with larger system text, the card scrolls and attribution stays
   clear. Return to portrait and check again.

Send a screenshot of the full Requests screen before we close this step.

## Manual GitHub checkpoint

Commit and push manually only after analysis, tests, and the phone check pass.
Suggested commit message:

```text
Keep Google attribution at the bottom of the driver map
```

Select only the three Dart files above for this change (and this note if desired).
Do not include `android/secrets.properties`. Database setup remains paused;
there is no Firebase deployment for this change.

## Verification boundary

Preparation checks cover Dart syntax, unchanged unrelated source sections,
camera-projection calculations, relative imports, whitespace, and ZIP contents.
Flutter and Dart SDKs are not installed in the preparation environment, so
`flutter analyze`, widget tests, an Android build, and the native map appearance
still need to be verified on your computer and phone. The layout test uses a
bounding-box proxy; it does not render the native Google logo.

Reference: [Google Maps padding and attribution](https://developers.google.com/maps/documentation/android-sdk/configure-map#map_padding).
