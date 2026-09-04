# Sahulat Ghar Tak

A Flutter home services marketplace mobile app. Customers browse service categories, submit
service requests, and manage addresses; verified Providers get a dashboard for incoming
requests, bookings, and their profile. The app is backed by a real ASP.NET Core REST API
(`SahulatAppDB`) — every screen is wired to live endpoints except the Provider
notifications page, which is still a placeholder.

## Features

- **Customer**
  - Mobile-number + OTP registration and login (with Terms & Conditions acceptance)
  - OTP-based Forgot Password / Reset Password flow
  - Browse without an account — login is only required when submitting a service request
  - Browse the backend service catalog (Services → Categories → suggested service
    titles) and submit service requests
  - Manage saved addresses and edit profile details
  - Track submitted service requests
  - Delete account permanently, in-app (password-confirmed) or via a web page
- **Provider**
  - Register/upgrade a customer account to a Provider account (with Terms & Conditions
    acceptance)
  - OTP-verified registration, followed by profile-photo + CNIC document upload for
    admin verification
  - OTP-based Forgot Password / Reset Password flow
  - 5-tab dashboard — Home, Requests, Jobs, Wallet, Profile — all backed by live
    endpoints: online/offline availability, incoming requests, bookings (accept,
    reject, close, cancel), wallet balance/transactions, profile editing, and
    document re-upload/verification status
  - Delete account permanently, in-app (password-confirmed) or via a web page
  - Notifications is the one remaining placeholder screen, pending a backend endpoint

See [AGENTS.md](AGENTS.md) for architecture notes, the feature-by-feature breakdown,
and conventions for extending the app.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>=3.0.0 <4.0.0`, see `pubspec.yaml`)
- A running instance of the companion ASP.NET Core API (`SahulatAppDB`) for any live testing —
  the app has no offline fallback for auth, categories, addresses, or service requests

### Setup

```bash
flutter pub get
flutter devices        # list available targets (emulator, desktop, Chrome, Edge, ...)
flutter run             # or: flutter run -d <device-id>
```

By default the app points at:

- `https://localhost:7265/api` for desktop/web/iOS in debug builds
  (`https://10.0.2.2:7265/api` automatically on the Android emulator)
- `https://sahulatghartak.com/api` for release/profile builds

See `lib/utils/constants.dart` to change the local backend URL.

### Common commands

| Command | Purpose |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run in debug mode against the Local Backend |
| `flutter run --dart-define=USE_PROD=true` | Run in debug mode against the Production Backend |
| `flutter build apk` (or `scripts\build_apk.bat`) | Build a release APK |
| `flutter build appbundle --release` (or `scripts\build_signed_bundle.bat`) | Build a signed release App Bundle for Play Console (needs `android/key.properties`, gitignored — see [AGENTS.md](AGENTS.md#quick-start)) |
| `dart format lib/` | Format code |
| `flutter analyze lib test` | Static analysis — run after every change (13 pre-existing `info` lints are the baseline) |
| `flutter test` | Runs the test suite (17 tests across 5 files) |

## Project structure

```
lib/
├── models/        # Data classes (Category, ServiceCatalog, ServiceTitle, ClientAddress, CustomerServiceRequest, AuthData, OtpData, ...)
│   └── provider/  # Provider-dashboard models (ServiceBooking, ProviderDetail, ProviderDocuments, ProviderWallet, ...)
├── providers/     # ChangeNotifier state management (one per feature area)
├── data/
│   └── repositories/  # One repository per provider — the single data source each ViewModel talks to
├── domain/        # Reserved for domain models / use cases (currently empty)
├── services/      # HTTP API clients, one per backend resource, plus secure-storage/session helpers
├── screens/       # Top-level customer screens; screens/provider/<feature>/ for the Provider Dashboard
├── widgets/       # Reusable UI components
├── utils/         # Constants, routing helpers, theming and icon/image matching helpers
└── main.dart      # App entry point, provider setup, route table
```

## Documentation

- [AGENTS.md](AGENTS.md) — architecture, conventions, and guidance for making changes to this repo
- [api.txt](api.txt) — source of truth for every backend request/response contract
- [docs/PRIVACY_POLICY.md](docs/PRIVACY_POLICY.md) — what the app collects, shares, and deletes
- [docs/APP_STORE_AUDIT_REPORT.md](docs/APP_STORE_AUDIT_REPORT.md) — Play Store / App Store compliance status

---

## Credits

**Developed By:**

- Rayder-23
- Coditium Solutions