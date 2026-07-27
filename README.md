# Sahulat Ghar Tak

A Flutter home services marketplace mobile app. Customers browse service categories, submit
service requests, and manage addresses; verified Providers get a dashboard for incoming
requests, bookings, and their profile. The app is backed by a real ASP.NET Core REST API
(`SahulatAppDB`) — most screens are wired to live endpoints rather than mock data.

## Features

- **Customer**
  - Mobile-number + OTP registration and login
  - Browse service categories (grouped client-side into Home Maintenance / Specialized
    Services / Property & Legal Services) and submit service requests
  - Manage saved addresses
  - Track submitted service requests
- **Provider**
  - Register/upgrade a customer account to a Provider account
  - OTP-verified registration, followed by profile-photo + CNIC document upload for
    admin verification
  - Dashboard: online/offline availability, incoming requests, real bookings (accept,
    close, cancel), profile, and document re-upload/status
  - Additional dashboard sections (earnings, wallet, reviews, chat, notifications,
    schedule, support, etc.) are present as UI-complete screens backed by mock data,
    pending backend endpoints

See [AGENTS.md](AGENTS.md) for a detailed breakdown of which features are real vs. mocked,
architecture notes, and conventions for extending the app.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>=2.18.0 <3.0.0`, see `pubspec.yaml`)
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
| `flutter run` | Run in debug mode against the local backend |
| `flutter build apk` | Build a release APK |
| `dart format lib/` | Format code |
| `flutter analyze` | Static analysis — run after every change |
| `flutter test` | ⚠️ Currently fails to load; see [AGENTS.md](AGENTS.md#quick-start) |

## Project structure

```
lib/
├── models/        # Data classes (Category, ClientAddress, CustomerServiceRequest, AuthData, OtpData, ...)
│   └── provider/   # Provider-dashboard models (ServiceBooking, ProviderDocuments, ServiceRequest, ...)
├── providers/     # ChangeNotifier state management (one per feature area)
├── services/      # HTTP API clients, one per backend resource
├── repositories/  # Mock/dummy data for not-yet-built backend features
├── database/      # Legacy local SQLite storage
├── screens/       # Top-level customer screens; screens/provider/<feature>/ for the Provider Dashboard
├── widgets/       # Reusable UI components
├── utils/         # Constants, routing helpers, category matching helpers
└── main.dart      # App entry point, provider setup, route table
```

## Documentation

- [AGENTS.md](AGENTS.md) — architecture, conventions, and guidance for making changes to this repo
- [api.txt](api.txt) — source of truth for every backend request/response contract
