# Security release

Alpha Plus now initializes App Check using Play Integrity (Android) or App Attest with Device Check fallback (Apple). Only explicit debug builds may use the registered debug provider via `--dart-define=ALPHA_APP_CHECK_DEBUG=true`. Production release builds require the existing private keystore; CI can build unsigned bundles solely for verification. Native backups and cleartext traffic are disabled.

The three Firebase rules files mirror the canonical backend repository, so deploying this checkout cannot accidentally restore older broad permissions. Deploy the shared backend and its rules from the up-to-date AlphaRide checkout.

Follow the staged [backend security rollout](https://github.com/Isaac-56/alpharide/blob/main/docs/security-hardening-rollout.md). Both apps must be updated before closing the old fleet feed. Register signing certificates and App Check providers, verify valid requests on real devices and admin/dispatcher, then enable enforcement. No cloud enforcement or production signing credentials are configured merely by pulling this repository.
