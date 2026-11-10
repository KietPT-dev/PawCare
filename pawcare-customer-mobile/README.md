# PawCare Customer Mobile

Flutter client for the PawCare Customer role. It uses one `AppConfig` endpoint;
the saved URL is restored with the customer's session.

## Structure

- `lib/app`: application bootstrap and customer shell
- `lib/core`: theme, reusable widgets, local mock data
- `lib/features`: each customer capability is isolated by feature
  - `auth`, `home`, `pets`, `discovery`, `booking`, `activity`, `profile`

## API endpoint

No customer configuration screen is shown. For a deployed environment, provide
the endpoint as a build-time value:

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
