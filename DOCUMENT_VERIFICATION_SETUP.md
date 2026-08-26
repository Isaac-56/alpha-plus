# Alpha Plus document verification

The driver licence flow performs an on-device photo-quality check before a
photo can receive a completed tick. It checks file size, resolution, lighting,
contrast, and blur. A successful quality check does not approve the identity or
prove that a document is genuine; the uploaded documents remain under review.

## Firebase setup

Alpha Plus and Alpha Ride currently use the shared Firebase project
`alpha-ride-29708`.

1. Open Firebase Console, select **Alpha Ride**, then open **Storage**.
2. Select **Get started** if Storage has not been created yet.
3. Keep a production location close to the app's users when Firebase asks.
4. From `C:\Projects\alpha_plus`, deploy the private upload rules:

   ```powershell
   firebase deploy --only storage --project alpha-ride-29708
   ```

The rules only permit an authenticated driver to access files stored below
`drivers/<their Firebase uid>/documents/`. Images are limited to 12 MB.

## Verify locally

Run these commands after copying the update into the Alpha Plus project:

```powershell
cd C:\Projects\alpha_plus
flutter pub get
dart format lib test
flutter analyze
flutter test
git diff --check
```

## Production note

This first-stage detector protects the workflow from obviously dark, blurry,
low-resolution, or oversized photos. Production identity approval should add a
trusted server-side verification provider or a trained document/OCR service,
plus manual review for uncertain cases. Never approve a driver only from the
client-side quality result.
