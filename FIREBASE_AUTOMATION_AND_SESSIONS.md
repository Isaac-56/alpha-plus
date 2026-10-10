# Firebase activation and single-device sessions

## What happens automatically for users

`firebase_options.dart`, `google-services.json`, and the Android package name
are compiled into Alpha Plus. Every installed copy connects to the configured
Firebase project automatically. Drivers do not run Firebase CLI commands and
you do not approve each phone manually.

Enable Firebase Authentication's **Phone** provider once in the shared
Firebase project. After that, every real driver can request an SMS from the
installed app automatically. Numbers entered in Firebase's "Phone numbers for
testing" table are only development shortcuts; real customer numbers are not
added there manually.

All production APKs or app bundles must be signed with the same release key.
Register that release certificate's SHA-1 and SHA-256 once in the Firebase
Android app. Every device installing that signed release then uses the same
approved identity. Debug certificates are only for development machines.

The SHA fingerprints identify your signed application, not an individual
phone. You register the release fingerprints once, regardless of how many
drivers install Alpha Plus.

## What the developer deploys once

Security rules live in Firebase, not inside the installed APK. Deploy them once
after changing `firestore.rules`:

```powershell
firebase deploy --only firestore:rules --project alpha-ride-29708
```

That single deployment protects every current and future installation. It is
not repeated for each driver or device.

## Immediate single-device driver session

After a successful phone verification, Alpha Plus generates a new random
session ID and writes it to `driver_sessions/{firebaseUid}`. The older device
has a live Firestore listener on the same document. When the new session ID
arrives from the server, the older device immediately removes its local session
and signs out.

If the older app is backgrounded or closed, it performs a server validation as
soon as it resumes and signs out before showing private driver pages.

The old device must have network connectivity to receive an immediate event.
No mobile application can receive a cloud logout while the device is fully
offline; it is enforced on the next online/resume check.

Passenger sessions remain in `user_sessions`, while Alpha Plus uses
`driver_sessions`. This allows one person to use the passenger and driver apps
without the two apps accidentally logging each other out.
