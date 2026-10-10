# Apply the Alpha Plus photo-check update

Extract the ZIP and copy its contents into:

```text
C:\Projects\alpha_plus
```

Allow Windows to merge folders and replace files. The ZIP contains paths
relative to the project root; it does not contain API keys or Firebase secret
configuration.

Then run:

```powershell
cd C:\Projects\alpha_plus

flutter pub get
dart format lib test
flutter analyze
flutter test
git diff --check
```

Deploy the security rules once from the project owner's computer:

```powershell
firebase deploy --only firestore:rules,storage --project alpha-ride-29708
```

Run the app on a physical phone and complete the checks in
`PHOTO_CHECK_SETUP.md`.

When everything passes, commit and push:

```powershell
git add .
git commit -m "Add secure driver photo check with automatic face screening"
git push origin main
git status
```

Do not commit API keys, `android/secrets.properties`, private signing files, or
Firebase Admin SDK credentials.
