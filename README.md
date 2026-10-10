# ALPHA +

ALPHA + is the South Sudan driver partner app for AlphaRide. It is built with
Flutter and shares the passenger app's neon-green brand system while keeping a
driver-focused onboarding and operations flow.

## Stage 1

- Single-run animated `ALPHA +` splash
- South Sudan phone entry (`+211`)
- Keyboard-safe six-digit OTP screen
- Driver name collection
- Optional biometric introduction
- Agreements and communication consent
- Juba service registration
- Responsive light and dark themes

The current authentication flow is a UI prototype. Firebase phone
authentication, secure biometric storage, and driver records will be connected
in a later integration stage.

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```
