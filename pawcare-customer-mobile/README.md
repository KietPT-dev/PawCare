# PawCare Customer Mobile

Flutter client for the PawCare Customer role. During local development it
always calls the Public API at `http://127.0.0.1:8081/api/v1` (the iOS
Simulator's loopback address to this Mac).

## Structure

- `lib/app`: application bootstrap and customer shell
- `lib/core`: theme, reusable widgets, local mock data
- `lib/features`: each customer capability is isolated by feature
  - `auth`, `home`, `pets`, `discovery`, `booking`, `activity`, `profile`

## API endpoint

No customer configuration screen is shown. The local API port is fixed at
`8081`, so start the backend once and then run the app normally. For a deployed
environment, a build-time value replaces the local endpoint:

```bash
flutter run --dart-define=PAWCARE_API_URL=https://api.example.com/api/v1
```

## Start after installing Flutter

```bash
cd pawcare-customer-mobile
flutter create .
flutter pub get
flutter run
```

Do not run `flutter create .` until Flutter SDK is installed. It generates platform folders (`android`, `ios`, `web`, etc.) while preserving the existing `lib` structure.
