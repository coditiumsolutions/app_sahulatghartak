# Sahulat Ghar Tak - Agent Customization Guide

**Project**: A Flutter home services marketplace mobile application, backed by a real ASP.NET Core REST API (`SahulatAppDB`). Customers browse service categories and submit service requests; Providers manage a dashboard of incoming requests, jobs, and earnings.

## Quick Start

- **Install deps**: `flutter pub get`
- **Run (debug, connects to local backend)**: `flutter run` — pick a target device when prompted, or `flutter run -d <device-id>`
- **Build APK**: `flutter build apk`
- **Format**: `dart format lib/`
- **Analyze**: `flutter analyze` (run this after every edit — treat new errors/warnings as blocking; pre-existing `withOpacity` deprecation infos are expected and not worth fixing incidentally)
- **Test**: `flutter test` — ⚠️ currently **fails to even load**: `test/widget_test.dart` is unmodified Flutter counter-app boilerplate that references a nonexistent `MyApp` class (the real app class is `SahulatApp` in `lib/main.dart`). There is no working test suite in this repo yet. Don't report `flutter test` as passing without first checking whether this has been fixed.
- **Build a signed release App Bundle**: `flutter build appbundle --release` — signing is configured via `android/app/build.gradle.kts`, which reads `android/key.properties` (gitignored, machine-local, not in this repo) for the release keystore path/alias/passwords. Without that file present, the release build type falls back to unsigned/default config. Every new upload to Google Play Console requires bumping the `+N` build number in `pubspec.yaml`'s `version:` line (e.g. `1.0.0+2` → `1.0.0+3`) — Play Console permanently rejects a reused version code, even from a never-published upload.

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
- **OTP verification** — `AuthProvider.sendOtp` / `resendOtp` / `verifyOtp`, `lib/models/otp_data.dart`. New client and provider registrations are created with `IsVerified=false`; `OtpVerificationScreen` (`lib/screens/otp_verification_screen.dart`) collects the 6-digit code, auto-sends on entry, and supports resend with a cooldown. A provider upgrade requires the client account to already be OTP-verified.
- **Provider document verification** — `ProviderDocumentProvider` (`lib/providers/provider_document_provider.dart`) / `ProviderDocumentApiService`, `lib/models/provider/provider_documents.dart`. Uploads profile photo + CNIC front/back (via `image_picker`) to `POST /api/provider/upload-documents`; `ProviderDocumentUploadScreen` runs right after provider registration, `VerificationDocumentsScreen` (`lib/screens/provider/profile/verification_documents_screen.dart`, linked from the Profile tab) lets an existing provider view/replace documents and see admin verification status/remarks.
- **Service Categories** — `CategoryProvider` / `CategoryApiService`, `lib/models/category.dart`
- **Client Addresses** — `ClientAddressProvider` / `ClientAddressApiService`, `lib/models/client_address.dart`
- **Customer Service Requests** — `CustomerServiceRequestProvider` / `CustomerServiceRequestApiService`, `lib/models/customer_service_request.dart` (create/update/cancel/delete a request)
- **Provider Profile / Availability** — `ProviderDashboardProvider` methods `loadProviderDetail`, `loadIncomingRequests`, `loadAvailabilityStatus`, `setOnline` (`lib/services/provider_profile_api_service.dart`, `provider_availability_api_service.dart`, `provider_service_request_api_service.dart`)
- **Provider Bookings** — `ProviderBookingsProvider` / `ServiceBookingApiService` (`lib/services/service_booking_api_service.dart`), `lib/models/provider/service_booking.dart` — fetch-by-provider and update (status/amounts) against `/api/service-bookings`. This backs the dashboard's **Jobs tab**, whose widget file is still named `lib/screens/provider/jobs/jobs_tab.dart` but now renders the real `BookingsTab` (not mock data — see below).
- **Account Deletion** — `AuthProvider.deleteAccount` / `AuthApiService.deleteAccount` (`POST /api/auth/delete-account`, re-verifies password server-side since there's no auth token). `lib/widgets/delete_account_dialog.dart` (`showDeleteAccountDialog`) is a shared password-confirmation dialog invoked from a "Delete Account" button on both `ProfileScreen` (customer) and `lib/screens/provider/profile/profile_tab.dart` (provider); on success it clears the session and returns to the landing screen. See `docs/PRIVACY_POLICY.md` §7 for the corresponding user-facing policy (also documents a required web-based deletion path at `https://sahulatghartak.com/delete-account` for Play Store compliance — that page lives outside this repo).

### Mocked / placeholder features

`ProviderDashboardProvider` also exposes `quotes`, `jobHistory`, `earningsSummary`, `walletBalance`, `walletTransactions`, `reviews`, `notifications`, `chatThreads`, `availabilitySlots`, `serviceOfferings`, `documents`, and `supportTickets`. These are all backed by `lib/repositories/provider_dashboard_repository.dart`, which is explicitly documented in its own docstring as dummy/mock data — there are no real backend endpoints for Quotes/Job-History/Earnings/Wallet/Reviews/Chat/Notifications/Availability-Slots/Service-Offerings/Documents(mock)/Support-Tickets yet. Don't try to "fix" these into real API calls without confirming new endpoints exist in `api.txt` first. Note the **Requests tab** (`RequestsTab`, incoming requests + "Send Quote") and **My Quotes screen** (`MyQuotesScreen`) are still mock-backed via this repository, distinct from the real Bookings feature above — don't confuse the two.

### Legacy/unused-in-flow files (still present, still registered as routes)

`lib/models/service.dart`, `lib/models/booking.dart`, `lib/providers/service_provider.dart`, `lib/providers/booking_provider.dart`, `lib/database/db_helper.dart` (SQLite via `sqflite`), and the screens `categories_screen.dart`, `service_detail_screen.dart`, `service_providers_screen.dart`, `booking_screen.dart`, `bookings_list_screen.dart` are earlier-generation, locally-mocked/SQLite-backed code from before the real API integration. They're still registered in `main.dart`'s route table but are not reachable from the current customer home flow (which now goes through `MainCategory` → `SubCategoriesScreen` → `ServiceRequestFormScreen`, see below). Treat them as legacy unless a task explicitly asks you to touch them.

### Customer category browsing flow

Real backend `Category` rows don't have a "main category" grouping concept, so the app layers one on client-side:

- `lib/utils/main_categories.dart` — static list of 3 `MainCategory` entries (Home Maintenance, Specialized Services, Property & Legal Services), each with hardcoded `SubCategoryItem(label, keywords)` entries
- `HomeScreen` shows the 3 main categories as square cards → tapping one opens `SubCategoriesScreen` with that `MainCategory`
- `SubCategoriesScreen._findMatch()` keyword-matches each `SubCategoryItem` against real `Category.name` values (case-insensitive `contains`); a match navigates to `ServiceRequestFormScreen` with the real `Category`, no match shows a "coming soon" snackbar
- `lib/utils/category_icons.dart` and `lib/utils/service_title_suggestions.dart` use the same keyword-matching pattern to pick an icon / hardcoded common-service-title suggestions for a category name

### Customer navigation shell

`HomeScreen.routeName` (`/home`) now resolves to `lib/widgets/main_navigation_shell.dart` (`MainNavigationShell`), a bottom-nav shell that swaps between 4 embedded tabs (`HomeScreen`, `CategoriesScreen`, `ServiceRequestsScreen`, `ProfileScreen`, each constructed with `embedded: true`) via `AnimatedSwitcher` instead of pushing a new route per tab. Each of those screens accepts an `embedded` flag that suppresses its own `Scaffold`/bottom-nav-bar when hosted inside the shell — pass `embedded: true` when reusing them there, `false` (default) when pushing them standalone. `SplashScreen` is the app's actual `initialRoute` (auth/session bootstrap before landing on `LandingScreen` or `MainNavigationShell`). The bottom nav bar (`lib/widgets/bottom_nav.dart`) has a 5th "Offers" slot (index 3) with no backing screen/route yet — it's a placeholder, tapping it is a no-op.

### Provider Dashboard

`ProviderDashboardScreen` (`lib/screens/provider_dashboard_screen.dart`) is a 5-tab bottom-nav shell (Dashboard/Requests/Jobs/Earnings/Profile, `lib/screens/provider/dashboard|requests|jobs|earnings|profile/`) — Jobs is the real, API-backed `BookingsTab` described above; Dashboard/Requests/Earnings/Profile's data lists are still mock-backed. The shell also has a drawer (`lib/widgets/provider/provider_app_drawer.dart`) linking to further feature screens under `lib/screens/provider/*` (chat, documents, notifications, reviews, schedule, services, settings, support, wallet, my-quotes) — all mock-backed except the document-verification screen noted above. Route names for these are centralized in `lib/utils/provider_routes.dart` (`ProviderRoutes`).

Customers with `role == 'Provider'` get a "Switch to Provider" button on `ProfileScreen`; Providers get a symmetric "Switch to Customer" button on `lib/screens/provider/profile/profile_tab.dart`. Both use `pushNamed` (not `pushReplacementNamed`) so either dashboard stays on the navigation stack while switching.

### Terms & Conditions (registration)

`lib/widgets/terms_and_conditions_section.dart` (`TermsAndConditionsSection`) is a shared collapsible-text + checkbox widget wired into both `CustomerRegistrationScreen` and `ProviderRegistrationScreen`. Each screen supplies its own title/body/closing text from `lib/utils/customer_terms_and_conditions.dart` / `lib/utils/provider_terms_and_conditions.dart`; the checkbox must be checked before registration can submit.

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
├── models/              # Data classes (Category, ClientAddress, CustomerServiceRequest, AuthData, OtpData, MainCategory, ProviderProfile, legacy Service/Booking)
│   └── provider/         # Provider-dashboard models: ProviderDetail, ServiceRequest, ServiceBooking (real), Quote/Job/EarningsSummary/WalletTransaction/Review/... (mock), ProviderDocuments
├── providers/           # ChangeNotifier state (AuthProvider, CategoryProvider, ClientAddressProvider, CustomerServiceRequestProvider, ProviderDashboardProvider, ProviderBookingsProvider, ProviderDocumentProvider, legacy ServiceProvider/BookingProvider)
├── services/             # HTTP API clients (one per resource) + SessionService (secure storage)
├── repositories/         # ProviderDashboardRepository — mock/dummy data pending real endpoints
├── database/             # SQLite (DbHelper) — legacy, used only by BookingProvider
├── screens/              # Top-level customer screens (incl. SplashScreen, OtpVerificationScreen, ProviderDocumentUploadScreen); screens/provider/<feature>/ for the Provider Dashboard tabs & drawer pages
├── widgets/              # Reusable UI (AuthCardScaffold + auth field helpers, MainNavigationShell + AppBottomNavigation, MainCategoryCard, SubcategoryCard, BannerSlider, FeaturedServicesCarousel, widgets/provider/ for dashboard-specific widgets incl. DocumentImageSlot)
├── utils/                # constants.dart (colors, kApiBaseUrl, kApiFileBaseUrl), dev_http_overrides.dart, provider_routes.dart, main_categories.dart, category_icons.dart, service_title_suggestions.dart, provider_availability_helper.dart, customer_terms_and_conditions.dart, provider_terms_and_conditions.dart
└── main.dart             # App entry point, MultiProvider setup, route table
```

## Navigation
All screens use named routes defined in `SahulatApp.routes` (`lib/main.dart`). Add new routes there before pushing to them. Provider-dashboard route name constants live in `lib/utils/provider_routes.dart` (`ProviderRoutes`).

## Dependencies
- `provider` — state management
- `http` / `http_parser` — REST API calls (incl. multipart uploads for provider documents)
- `image_picker` — camera/gallery picks for provider document upload (profile photo, CNIC front/back)
- `flutter_secure_storage` — persisted login session
- `sqflite` — legacy local SQLite storage (Booking flow only)
- `path_provider` — legacy SQLite storage path, and re-downloading already-uploaded provider documents to resend on partial re-upload (`ProviderDocumentProvider._resolveFile`)
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
- `docs/PRIVACY_POLICY.md` is the source of truth for what the app claims to collect/share/delete — cross-check it before adding or changing anything touching personal data (new profile fields, new data shared between Customers/Providers, new SDKs), and update it in the same change if the claim would otherwise go stale.
