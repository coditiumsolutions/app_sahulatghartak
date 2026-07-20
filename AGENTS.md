# Sahulat Ghar Tak - Agent Customization Guide

**Project**: A Flutter home services marketplace mobile application, backed by a real ASP.NET Core REST API (`SahulatAppDB`). Customers browse service categories and submit service requests; Providers manage a dashboard of incoming requests, jobs, and earnings.

## Quick Start

- **Install deps**: `flutter pub get`
- **Run (debug, connects to local backend)**: `flutter run` — pick a target device when prompted, or `flutter run -d <device-id>`
- **Build APK**: `flutter build apk`
- **Format**: `dart format lib/`
- **Analyze**: `flutter analyze` (run this after every edit — treat new errors/warnings as blocking; pre-existing `withOpacity` deprecation infos are expected and not worth fixing incidentally)
- **Test**: `flutter test` — ⚠️ currently **fails to even load**: `test/widget_test.dart` is unmodified Flutter counter-app boilerplate that references a nonexistent `MyApp` class (the real app class is `SahulatApp` in `lib/main.dart`). There is no working test suite in this repo yet. Don't report `flutter test` as passing without first checking whether this has been fixed.

List available devices with `flutter devices`. In this environment that typically includes an Android emulator (`emulator-5554`), Windows desktop, Chrome, and Edge.

### Hot reload during manual verification

Prefer `r` (hot reload) / `R` (hot restart) on an already-running `flutter run` session over killing and relaunching the app — it's much faster for iterating on UI changes. Only do a full relaunch after a genuine disconnect (e.g. "Lost connection to device", an app crash, or after `adb shell pm clear` on the package, which kills the running process).

## Backend Setup (required for any live testing)

This app is **not** offline/mocked for its core flows — most screens hit a real backend. To run and manually test features end-to-end you need the ASP.NET Core API running.

- **Local base URL**: `https://localhost:7265/api` (desktop/web/iOS targets) — the Android emulator instead resolves to `https://10.0.2.2:7265/api` automatically (see `lib/utils/constants.dart`; `10.0.2.2` is the emulator's alias for the host machine's `localhost`).
- **Deployed base URL**: `https://sahulatghartak.com/api` — used automatically in release/profile builds (`kDebugMode` switches between the two in `lib/utils/constants.dart`).
- Debug builds trust the ASP.NET Core local dev HTTPS certificate via `lib/utils/dev_http_overrides.dart` (`DevHttpOverrides`, wired up in `main()`), so a self-signed local cert won't block requests — this override is debug-only and does not apply to release builds.
- **Every request/response contract lives in `api.txt` at the project root — it is the source of truth.** Never guess field names, types, or response shapes; read the relevant section of `api.txt` first. If you change a request/response contract, update `api.txt` in the same change (see the `ALSO UPDATE` rule at the top of that file). The `use-api-docs` project skill enforces this workflow automatically for API-related work.
- Without the backend running (or reachable), auth, categories, addresses, and service requests will all fail — the app has no offline fallback for these.

## Architecture Overview

This app uses **Provider** (`provider` package) for state management, with `ChangeNotifier`-based providers separating models, API services, and UI screens.

### Real, API-backed features

These are fully wired to the live backend documented in `api.txt`:

- **Auth** — `AuthProvider` / `AuthApiService` (`lib/services/auth_api_service.dart`): register client, register/upgrade provider, login, session persistence via `flutter_secure_storage` (`lib/services/session_service.dart`)
- **Service Categories** — `CategoryProvider` / `CategoryApiService`, `lib/models/category.dart`
- **Client Addresses** — `ClientAddressProvider` / `ClientAddressApiService`, `lib/models/client_address.dart`
- **Customer Service Requests** — `CustomerServiceRequestProvider` / `CustomerServiceRequestApiService`, `lib/models/customer_service_request.dart` (create/update/cancel/delete a request)
- **Provider Profile / Availability** — `ProviderDashboardProvider` methods `loadProviderDetail`, `loadIncomingRequests`, `loadAvailabilityStatus`, `setOnline` (`lib/services/provider_profile_api_service.dart`, `provider_availability_api_service.dart`, `provider_service_request_api_service.dart`)

### Mocked / placeholder features

`ProviderDashboardProvider` also exposes `activeJobs`, `jobHistory`, `earningsSummary`, `walletBalance`, `walletTransactions`, `reviews`, `notifications`, `chatThreads`, `availabilitySlots`, `serviceOfferings`, `documents`, and `supportTickets`. These are all backed by `lib/repositories/provider_dashboard_repository.dart`, which is explicitly documented in its own docstring as dummy/mock data — there are no real backend endpoints for Jobs/Earnings/Wallet/Reviews/Chat/Notifications/Availability-Slots/Service-Offerings/Documents/Support-Tickets yet. Don't try to "fix" these into real API calls without confirming new endpoints exist in `api.txt` first.

### Legacy/unused-in-flow files (still present, still registered as routes)

`lib/models/service.dart`, `lib/models/booking.dart`, `lib/providers/service_provider.dart`, `lib/providers/booking_provider.dart`, `lib/database/db_helper.dart` (SQLite via `sqflite`), and the screens `categories_screen.dart`, `service_detail_screen.dart`, `service_providers_screen.dart`, `booking_screen.dart`, `bookings_list_screen.dart` are earlier-generation, locally-mocked/SQLite-backed code from before the real API integration. They're still registered in `main.dart`'s route table but are not reachable from the current customer home flow (which now goes through `MainCategory` → `SubCategoriesScreen` → `ServiceRequestFormScreen`, see below). Treat them as legacy unless a task explicitly asks you to touch them.

### Customer category browsing flow

Real backend `Category` rows don't have a "main category" grouping concept, so the app layers one on client-side:

- `lib/utils/main_categories.dart` — static list of 3 `MainCategory` entries (Home Maintenance, Specialized Services, Property & Legal Services), each with hardcoded `SubCategoryItem(label, keywords)` entries
- `HomeScreen` shows the 3 main categories as square cards → tapping one opens `SubCategoriesScreen` with that `MainCategory`
- `SubCategoriesScreen._findMatch()` keyword-matches each `SubCategoryItem` against real `Category.name` values (case-insensitive `contains`); a match navigates to `ServiceRequestFormScreen` with the real `Category`, no match shows a "coming soon" snackbar
- `lib/utils/category_icons.dart` and `lib/utils/service_title_suggestions.dart` use the same keyword-matching pattern to pick an icon / hardcoded common-service-title suggestions for a category name

### Provider Dashboard

`ProviderDashboardScreen` (`lib/screens/provider_dashboard_screen.dart`) is a 5-tab bottom-nav shell (Dashboard/Requests/Jobs/Earnings/Profile, `lib/screens/provider/dashboard|requests|jobs|earnings|profile/`) plus a drawer (`lib/widgets/provider/provider_app_drawer.dart`) linking to the mock-backed feature screens under `lib/screens/provider/*` (chat, documents, notifications, reviews, schedule, services, settings, support, wallet). Route names for these are centralized in `lib/utils/provider_routes.dart` (`ProviderRoutes`).

Customers with `role == 'Provider'` get a "Switch to Provider" button on `ProfileScreen`; Providers get a symmetric "Switch to Customer" button on `lib/screens/provider/profile/profile_tab.dart`. Both use `pushNamed` (not `pushReplacementNamed`) so either dashboard stays on the navigation stack while switching.

## Common Tasks

### Adding/changing an API integration
1. Read the relevant section of `api.txt` first — do not invent field names or shapes.
2. Match the request/response contract exactly, including the common `{ success, message, data }` wrapper most endpoints use.
3. Add the API service method in `lib/services/`, expose it via the relevant `ChangeNotifier` provider in `lib/providers/`.
4. If you're adding a new or changed contract, update `api.txt` in the same change.

### Adding a new screen
1. Create the screen under `lib/screens/` (or `lib/screens/provider/<feature>/` for provider-dashboard features) with a `static const routeName`.
2. Register it in `SahulatApp.routes` in `lib/main.dart`.
3. Navigate via `Navigator.of(context).pushNamed(YourScreen.routeName, arguments: ...)`.

### Adding a category to the customer browsing flow
Edit `lib/utils/main_categories.dart` to add a `SubCategoryItem(label, keywords)` under the appropriate `MainCategory` — `keywords` are matched case-insensitively against real backend `Category.name` values in `SubCategoriesScreen`.

## Project Structure

```
lib/
├── models/              # Data classes (Category, ClientAddress, CustomerServiceRequest, AuthData, MainCategory, ProviderProfile, legacy Service/Booking)
├── providers/           # ChangeNotifier state (AuthProvider, CategoryProvider, ClientAddressProvider, CustomerServiceRequestProvider, ProviderDashboardProvider, legacy ServiceProvider/BookingProvider)
├── services/             # HTTP API clients (one per resource) + SessionService (secure storage)
├── repositories/         # ProviderDashboardRepository — mock/dummy data pending real endpoints
├── database/             # SQLite (DbHelper) — legacy, used only by BookingProvider
├── screens/              # Top-level customer screens; screens/provider/<feature>/ for the Provider Dashboard tabs & drawer pages
├── widgets/              # Reusable UI (AuthCardScaffold + auth field helpers, MainCategoryCard, SubcategoryCard, widgets/provider/ for dashboard-specific widgets)
├── utils/                # constants.dart (colors, kApiBaseUrl), dev_http_overrides.dart, provider_routes.dart, main_categories.dart, category_icons.dart, service_title_suggestions.dart, provider_availability_helper.dart
└── main.dart             # App entry point, MultiProvider setup, route table
```

## Navigation
All screens use named routes defined in `SahulatApp.routes` (`lib/main.dart`). Add new routes there before pushing to them. Provider-dashboard route name constants live in `lib/utils/provider_routes.dart` (`ProviderRoutes`).

## Dependencies
- `provider` — state management
- `http` — REST API calls
- `flutter_secure_storage` — persisted login session
- `sqflite` / `path_provider` — legacy local SQLite storage (Booking flow only)
- `intl` — date/time formatting
- `flutter_animate` — UI animations
- `fl_chart` — charts (Provider earnings/wallet screens)

## Project Skills (`.claude/skills/`)
- **use-api-docs** — read `api.txt` before any API-related work; keep it in sync when contracts change. Applies automatically to API integration tasks.
- **github-commit** — the standard workflow for "commit and push to github"-style requests (safe commits, secret scanning, `.gitignore` hygiene).
- **update-db-docs** — introspects the live `SahulatAppDB` schema via a provided connection string and updates DB docs (`db.txt`/`Database.md`/`db.md`) if/when those exist.
- **sql-pro** — SQL query design/optimization workflow, for direct database work against `SahulatAppDB`.

## Important Notes
- The app initializes with `WidgetsFlutterBinding.ensureInitialized()` and installs `DevHttpOverrides` (debug-only) before `runApp()` — keep both ahead of any network-dependent init.
- Material 3 is enabled (`useMaterial3: true`). Use `kPrimaryColor` / `kSecondaryColor` / `kAccentColor` from `lib/utils/constants.dart` for theme consistency; shared auth-styled screens should reuse `AuthCardScaffold`, `authFieldDecoration()`, `authFieldLabel()`, `AuthPrimaryButton`, and `GenderSelector` from `lib/widgets/auth_card_scaffold.dart`.
- **Dart SDK constraint is `>=2.18.0 <3.0.0`** (see `pubspec.yaml`) — Dart records (`(a, b)` tuple syntax) and other Dart 3-only language features are **not available**. Use parallel indexed arrays/lists instead.
- The existing codebase uses `Color.withOpacity()` throughout (not the newer `withValues()`); match that existing style in new code rather than "fixing" it.
- Not all "backend-shaped" data is real — check whether a `ProviderDashboardProvider` getter is real-API-backed or `ProviderDashboardRepository` mock-backed (see Architecture Overview above) before assuming it can be wired to a new real endpoint.
