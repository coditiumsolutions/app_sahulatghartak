# Sahulat Ghar Tak - Agent Customization Guide

**Project**: A Flutter home services marketplace mobile application, backed by a real ASP.NET Core REST API (`SahulatAppDB`). Customers browse service categories and submit service requests; Providers manage a dashboard of incoming requests, bookings, and their wallet/profile.

## Quick Start

- **Install deps**: `flutter pub get`
- **Run (debug, connects to local backend)**: `flutter run` — pick a target device when prompted, or `flutter run -d <device-id>`. Run against the deployed production backend instead with `flutter run --dart-define=USE_PROD=true` (see `lib/utils/constants.dart`).
- **Build APK**: `flutter build apk` (or `scripts\build_apk.bat`)
- **Build scripts**: `scripts/build_apk.bat`, `scripts/build_signed_bundle.bat`, `scripts/run_launch_chrome.bat` — self-locating (resolve the repo root via `%~dp0`, not a hardcoded path) and portable across machines (only fall back to a hardcoded Flutter install path when `flutter` isn't already on `PATH`).
- **Format**: `dart format lib/`
- **Analyze**: `flutter analyze lib test` (run this after every edit — treat new errors/warnings as blocking). Baseline is **13 pre-existing `info` lints** (12 `prefer_const_constructors` + 1 `use_super_parameters`, all in `lib/screens/` and `lib/widgets/`); leave those alone and just make sure you add none.
- **Test**: `flutter test` — 17 tests across 5 files, all passing: `test/widget_test.dart` (smoke test), `test/contact_details_mapping_test.dart` (customer/provider contact-field JSON mapping), `test/session_service_test.dart` (session persistence/replacement/logout), `test/customer_service_request_repository_test.dart` (repository merge/filter + passcode persistence), `test/provider_bookings_repository_test.dart` (rejected-bookings merge + seen-count round-trip). Add new tests alongside these as coverage grows; there is no broader suite yet. Note there is no `mockito`/`mocktail` in this project — the existing tests use hand-written fakes that subclass the real service/store and override methods, so follow that style.
- **Build a signed release App Bundle**: `flutter build appbundle --release` (or `scripts\build_signed_bundle.bat`) — signing is configured via `android/app/build.gradle.kts`, which reads `android/key.properties` (gitignored, machine-local, not in this repo) for the release keystore path/alias/passwords. Without that file present, the release build type falls back to unsigned/default config. Every new upload to Google Play Console requires bumping the `+N` build number in `pubspec.yaml`'s `version:` line (e.g. `1.0.0+2` → `1.0.0+3`) — Play Console permanently rejects a reused version code, even from a never-published upload.
  - ⚠️ **Known failure mode — stale/incomplete bundle**: an `appbundle` build reusing a stale incremental Gradle build can finish "successfully" (exit 0, prints `Built ... app-release.aab`) while silently missing the entire `flutter_assets` directory — no images, no app icon/logo, no `MaterialIcons-Regular.otf`. Installed, this renders as icons/logos replaced by fallback tofu/emoji glyphs and all `Image.asset` images missing, and the `.aab` is a few MB smaller than a correct build. The build finishing fast (well under a minute) for a full release build is itself a red flag. Always run `flutter clean` before a release `appbundle` build (already done by `scripts\build_signed_bundle.bat`), and after building, verify the artifact before handing it off: the `.aab` is a zip — check it contains `base/assets/flutter_assets/` entries including `fonts/MaterialIcons-Regular.otf` and the app's declared image assets, e.g. `python3 -c "import zipfile; z=zipfile.ZipFile('path/to/app-release.aab'); print([n for n in z.namelist() if 'flutter_assets' in n])"`. Don't rely on Gradle's process exit code alone — PowerShell can report exit code 1 for a build that actually succeeded (a benign Gradle/javac stderr warning line gets treated as a native command error), so check the log text for `Built build\app\outputs\bundle\release\app-release.aab` and do the asset-completeness check regardless of exit code.

List available devices with `flutter devices`. In this environment that typically includes an Android emulator (`emulator-5554`), Windows desktop, Chrome, and Edge.

### Hot reload during manual verification

Prefer `r` (hot reload) / `R` (hot restart) on an already-running `flutter run` session over killing and relaunching the app — it's much faster for iterating on UI changes. Only do a full relaunch after a genuine disconnect (e.g. "Lost connection to device", an app crash, or after `adb shell pm clear` on the package, which kills the running process).

## WSL environment notes

This repo lives on the Windows filesystem (`D:\Ry Work [D]\...`) and is normally edited/built from Windows tooling (Android Studio, VS Code, etc.) with `core.autocrlf=true`. WSL's own git previously didn't see that setting, so WSL-side `git diff`/`git status` used to show every tracked file as modified (a CRLF-vs-LF false alarm). **Fixed** by setting `core.autocrlf=true` globally in WSL's own git config too, so both sides agree on line-ending handling — plain `git status`/`git diff`/`git add`/`git commit` from WSL Bash are safe to use directly now.

WSL still can't run `flutter`/`dart` directly — the SDK at `/mnt/d/ryDevelop/flutter` is a Windows-targeted install whose wrapper scripts (`bin/flutter`, `bin/dart`) have CRLF line endings and break under WSL bash, and there's no cached Linux dart-sdk to fall back to. For any `flutter`/`dart` command (`analyze`, `test`, `build`, `pub get`, `run`, etc.), use `powershell.exe` from WSL Bash, which reaches the Windows-native Flutter SDK:

```bash
powershell.exe -NoProfile -Command "Set-Location -LiteralPath 'D:\Ry Work [D]\Bahria Town\SahulatGharTak App\Flutter App'; flutter analyze lib"
```

- **Always use `-LiteralPath`, never plain `cd`/`Set-Location <path>`** — the `[D]` in the folder name is treated as a wildcard glob by PowerShell's path resolution and fails to resolve with a bare path argument. This fails *silently*: PowerShell prints an error but keeps going and runs the next command from the wrong directory, so a skipped `-LiteralPath` can look like a successful run against the wrong tree.
- The locally-running ASP.NET Core API (`https://localhost:7265/api` — see Backend Setup below) is also only reachable from the Windows side, not WSL bash — WSL2 is a separate network namespace, so `curl`/plain `http` calls to it from WSL fail with connection refused even though the API is genuinely running and the Android emulator target (`https://10.0.2.2:7265/api`) works fine. Use `powershell.exe -NoProfile -Command "Invoke-RestMethod -Uri '...' ..."` instead when testing endpoints directly from a shell.
- For a git commit message with a body (or any `$`/backtick-containing text), don't pass it inline via `powershell.exe -Command` from bash — bash's own `$()`/backtick expansion mangles it before PowerShell ever sees it, and `git commit` still exits 0 with the corrupted message, so the failure is silent. Prefer plain bash `git commit -m "..." -m "..."` now that WSL/Windows git agree (see above); only reach for a PowerShell here-string (`@'...'@`, written to a temp `.ps1` and run with `-File`) if a PowerShell-specific git operation is unavoidable, and verify with `git log -1 --pretty=%B` afterward.
- Windows PowerShell 5.1 is what's installed (no `pwsh.exe`/PS7) — e.g. `Invoke-RestMethod -SkipCertificateCheck` isn't available; use the classic `ServerCertificateValidationCallback` override to bypass the local dev HTTPS cert instead.
- A detached long-running process (e.g. `flutter run` left running in the background) must use `Start-Process -PassThru -WindowStyle Hidden`, not `Start-Job` — jobs die when the launching `powershell.exe -Command`/`-File` process exits after each shell call.

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
- **Provider document verification** — `ProviderDocumentProvider` (UI state: `ImagePicker`, picked `File`s, loading/progress) → `ProviderDocumentRepository` (`lib/data/repositories/provider_document_repository.dart`, wraps `ProviderDocumentApiService` + the temp-file re-download used on partial re-upload), `lib/models/provider/provider_documents.dart`. Uploads profile photo + CNIC front/back (via `image_picker`) to `POST /api/provider/upload-documents`; `ProviderDocumentUploadScreen` runs right after provider registration, `VerificationDocumentsScreen` (`lib/screens/provider/profile/verification_documents_screen.dart`, linked from the Profile tab) lets an existing provider view/replace documents and see admin verification status/remarks.
- **Service Categories** — `CategoryProvider` → `CategoryRepository` (`lib/data/repositories/category_repository.dart`) → `CategoryApiService`, `lib/models/category.dart`
- **Client Addresses** — `ClientAddressProvider` → `ClientAddressRepository` (`lib/data/repositories/client_address_repository.dart`) → `ClientAddressApiService`, `lib/models/client_address.dart`
- **Customer Service Requests** — `CustomerServiceRequestProvider` (thin ViewModel, UI state only) → `CustomerServiceRequestRepository` (`lib/data/repositories/customer_service_request_repository.dart`, merges `CustomerServiceRequestApiService` with the on-device `DeletedRequestsStore`/`RequestPasscodeStore`), `lib/models/customer_service_request.dart` (create/update/cancel/delete a request).
- **Provider Profile / Availability** — `ProviderDashboardProvider` methods `loadProviderDetail`, `loadIncomingRequests`, `loadAvailabilityStatus`, `setOnline` → `ProviderDashboardRepository` (`lib/data/repositories/provider_dashboard_repository.dart`) → `ProviderProfileApiService`, `ProviderAvailabilityApiService`, `ProviderServiceRequestApiService`
- **Provider Bookings** — `ProviderBookingsProvider` → `ProviderBookingsRepository` (`lib/data/repositories/provider_bookings_repository.dart`, merges `ServiceBookingApiService` with the on-device `RejectedBookingsStore`), `lib/models/provider/service_booking.dart` — fetch-by-provider and update (status/amounts) against `/api/service-bookings`. This backs the dashboard's **Jobs tab**, whose widget file is still named `lib/screens/provider/jobs/jobs_tab.dart` but the class it renders is `BookingsTab`.
- **Service Catalog / Service Titles / Provider Wallet** — `ServiceCatalogProvider` → `ServiceCatalogRepository`, `ServiceTitleProvider` → `ServiceTitleRepository`, `ProviderWalletProvider` → `ProviderWalletRepository` (all `lib/data/repositories/`) — thin pass-throughs, no merging.
- **Account Deletion** — `AuthProvider.deleteAccount` / `AuthApiService.deleteAccount` (`POST /api/auth/delete-account`, re-verifies password server-side since there's no auth token). `lib/widgets/delete_account_dialog.dart` (`showDeleteAccountDialog`) is a shared password-confirmation dialog invoked from a "Delete Account" button on both `ProfileScreen` (customer) and `lib/screens/provider/profile/profile_tab.dart` (provider); on success it clears the session and returns to the landing screen. See `docs/PRIVACY_POLICY.md` §7 for the corresponding user-facing policy (also documents a required web-based deletion path at `https://sahulatghartak.com/delete-account` for Play Store compliance — that page lives outside this repo).
- **Forgot / Reset Password** — OTP-based, atomic flow: `lib/screens/forgot_password_screen.dart` (`ForgotPasswordScreen`) collects the mobile number and sends an OTP, `lib/screens/reset_password_screen.dart` (`ResetPasswordScreen`) collects the OTP + new password and calls the reset-password endpoint via `AuthApiService`/`AuthProvider`. Both are reachable from `LoginScreen`.
- **Profile editing** — `lib/screens/edit_profile_screen.dart` defines `CustomerEditProfileScreen` (customer), `lib/screens/provider/profile/edit_profile_screen.dart` defines `EditProfileScreen` (provider) — **note the file/class names are swapped relative to each other**, don't assume by filename alone. Both are wired to the real `providers-detail`/`clients-detail` update APIs (previously the provider one only updated local state).
- **Guest browsing** — customers can browse the app without an account per App Store Guideline 5.1.1; `lib/utils/guest_guard.dart` (`ensureLoggedIn`) gates only the actions that actually require a session (e.g. submitting a service request), showing a dismissible "Login Required" dialog (`Keep Browsing` vs `Log In`) rather than forcing navigation.
- **Branded message dialogs** — `lib/widgets/message_dialog.dart` (`showMessageDialog`) replaces SnackBars for flow-outcome messages (login/registration/reset/delete failures and confirmations) that are easy to miss; prefer it over `ScaffoldMessenger`/SnackBar for anything the user must acknowledge.

**Every provider except `AuthProvider` is repository-backed** (`lib/data/repositories/`, one repository per provider) — the ViewModel holds UI state only and never touches a service directly. See `docs/architecture-audit.md` §6 for the migration history and Task 6 (Auth) as the one remaining, deliberately-deferred piece.

### Legacy Service/Booking stack — removed

The earlier-generation, locally-mocked/SQLite-backed code (`lib/models/service.dart`, `lib/models/booking.dart`, `lib/providers/service_provider.dart`, `lib/providers/booking_provider.dart`, `lib/database/`, `service_detail_screen.dart`, `booking_screen.dart`, `categories_screen.dart`, `bookings_list_screen.dart`) has been deleted and unregistered from `main.dart`'s route table. Everything customer-facing now runs on the real catalog flow (`ServiceCatalog` → `Category` → `ServiceRequestFormScreen`). The `sqflite` and `path` packages are still listed in `pubspec.yaml` but nothing in `lib/` imports either — dead weight pending removal, not evidence of an active local-DB feature.

### Customer category browsing flow

Three real backend levels, all API-driven — there is no client-side hardcoded category list any more:
`Services` (parent catalog) → `Categories` (children, filtered by `serviceUid`) → `ServiceTitles` (per-category suggestions).

- `HomeScreen` reads `ServiceCatalogProvider` (→ `ServiceCatalogRepository` → `ServiceCatalogApiService`, `lib/models/service_catalog.dart`) and renders each `ServiceCatalog` as a square `MainCategoryCard`; tapping one opens `SubCategoriesScreen` through an `OpenContainer` transform.
- `SubCategoriesScreen` fetches that service's categories (`CategoryApiService.fetchCategories(serviceUid: ...)`) and renders them as `SubcategoryCard`s; tapping one pushes `ServiceRequestFormScreen` with the real `Category`.
- `ServiceRequestFormScreen` calls `ServiceTitleProvider.loadServiceTitles(category.id)` to fill the Service Title dropdown, plus an "Other (not listed)" option that swaps in a free-text field.
- `FeaturedServicesCarousel` on the home screen shows real `Category` rows from `CategoryProvider` and taps straight through to the request form.
- `lib/utils/category_icons.dart`, `category_images.dart`, `service_catalog_style.dart`, and `service_colors.dart` keyword-match a backend name to an icon / image / color — the only client-side hardcoding left in this flow, and each falls back to a default for unknown names.
- **Category fetches are deliberately screen-scoped**: `SubCategoriesScreen` and `CategoryPickerScreen` each own their own request instead of reading the shared `CategoryProvider`. `OpenContainer` builds every card's destination up front, so several instances fetch concurrently and a shared provider let whichever response landed last show the wrong service's categories. Keep new category fetches scoped to the screen that needs them.

### Customer navigation shell

`HomeScreen.routeName` (`/home`) resolves to `lib/widgets/main_navigation_shell.dart` (`MainNavigationShell`), a bottom-nav shell that swaps between **3** embedded tabs — `HomeScreen`, `ServiceRequestsScreen`, `ProfileScreen`, each constructed with `embedded: true` — via `AnimatedSwitcher` instead of pushing a new route per tab. Each of those screens accepts an `embedded` flag that suppresses its own `Scaffold`/bottom-nav bar when hosted inside the shell; pass `embedded: true` when reusing them there, `false` (default) when pushing them standalone. The bar itself is `lib/widgets/bottom_nav.dart` (`AppBottomNavigation`) with exactly three items — Home / Requests / Profile; standalone screens render it with `currentIndex: -1` so nothing is highlighted. `SplashScreen` is the app's actual `initialRoute` (auth/session bootstrap before landing on `LandingScreen` or `MainNavigationShell`).

### Provider Dashboard

`ProviderDashboardScreen` (`lib/screens/provider_dashboard_screen.dart`) is a 5-tab bottom-nav shell: `ProviderHomeTab` / `RequestsTab` / `BookingsTab` / `WalletTab` / `ProfileTab`, living under `lib/screens/provider/dashboard|requests|jobs|wallet|profile/`. Note the Jobs tab's widget file is `jobs/jobs_tab.dart` but the class is `BookingsTab`, and the 4th tab is **Wallet** (`wallet/wallet_tab.dart`), not "Earnings".

**All five tabs are real-API-backed** — they read `ProviderBookingsProvider`, `ProviderWalletProvider`, `ProviderDocumentProvider`, `AuthProvider`, and `ProviderDashboardProvider`'s real methods (`providerDetail`, availability). `ProviderDashboardProvider` no longer has a mock-data half at all (see `docs/architecture-audit.md` §6 Task 2 — the old mock `lib/repositories/provider_dashboard_repository.dart` and its 11 orphan `lib/models/provider/` models were dead code with zero UI consumers and have been deleted). There is **no** app drawer (`provider_app_drawer.dart` does not exist), and no chat/reviews/schedule/services/settings/support/my-quotes screens.

The only genuine placeholder is `lib/screens/provider/notifications/notifications_screen.dart` — a static "coming soon" page with no provider wiring, pending a real notifications endpoint. `lib/screens/provider/jobs/rejected_requests_screen.dart` is real (reached from `RequestsTab`, backed by `ProviderBookingsProvider` + `RejectedBookingsStore`). `lib/utils/provider_routes.dart` (`ProviderRoutes`) holds four route constants — `dashboard`, `notifications`, `editProfile`, `verificationDocuments`; other provider screens declare their own `routeName` and are registered in `lib/main.dart` alongside them.

Customers with `role == 'Provider'` get a "Switch to Provider" button on `ProfileScreen`; Providers get a symmetric "Switch to Customer" button on `lib/screens/provider/profile/profile_tab.dart`. Both use `pushNamed` (not `pushReplacementNamed`) so either dashboard stays on the navigation stack while switching.

### Terms & Conditions (registration)

`lib/widgets/terms_and_conditions_section.dart` (`TermsAndConditionsSection`) is a shared collapsible-text + checkbox widget wired into both `CustomerRegistrationScreen` and `ProviderRegistrationScreen`. Each screen supplies its own title/body/closing text from `lib/utils/customer_terms_and_conditions.dart` / `lib/utils/provider_terms_and_conditions.dart`; the checkbox must be checked before registration can submit.

## Common Tasks

### Adding/changing an API integration
1. Read the relevant section of `api.txt` first — do not invent field names or shapes.
2. Match the request/response contract exactly, including the common `{ success, message, data }` wrapper most endpoints use.
3. Add the API service method in `lib/services/`, then expose it through the feature's `lib/data/repositories/` Repository rather than having the `ChangeNotifier` provider call the service directly — every provider except `AuthProvider` already follows this shape (see `docs/architecture-audit.md` §6). `AuthProvider` is the one remaining exception, still calling its services directly pending a dedicated regression pass; don't block unrelated work on migrating it.
4. If you're adding a new or changed contract, update `api.txt` in the same change.

### Adding a new screen
1. Create the screen under `lib/screens/` (or `lib/screens/provider/<feature>/` for provider-dashboard features) with a `static const routeName`.
2. Register it in `SahulatApp.routes` in `lib/main.dart`.
3. Navigate via `Navigator.of(context).pushNamed(YourScreen.routeName, arguments: ...)`.

### Adding a service, category, or service title
These are backend rows (`Services` → `Categories` → `ServiceTitles`), not client-side lists — add them on the API/database side and the app picks them up with no Flutter change. Optionally add a keyword for the new name in `lib/utils/category_icons.dart` / `category_images.dart` / `service_catalog_style.dart` so it doesn't fall back to the default icon/image/color.

## Project Structure

```
lib/
├── models/              # Data classes (Category, ServiceCatalog, ServiceTitle, ClientAddress, CustomerServiceRequest, AuthData, OtpData, ProviderProfile, ClientDetail)
│   └── provider/        # Provider-dashboard models, all real/in-use: ProviderDetail, ServiceRequest, ServiceBooking, ProviderWallet, ProviderDocuments, ProviderAvailabilityStatus
├── providers/           # ChangeNotifier ViewModels, UI state only (AuthProvider, CategoryProvider, ClientAddressProvider, CustomerServiceRequestProvider, ProviderDashboardProvider, ProviderBookingsProvider, ProviderDocumentProvider, ProviderWalletProvider, ServiceCatalogProvider, ServiceTitleProvider) — all repository-backed except AuthProvider
├── data/
│   └── repositories/    # One Repository per provider above (9 total) — AuthRepository not yet extracted
├── domain/              # Empty scaffolding (models/, use_cases/ hold only .gitkeep) — populate per-feature only when justified, see docs/architecture-audit.md Phase 4
├── services/            # HTTP API clients (one per resource) + SessionService and the on-device stores (DeletedRequestsStore, RejectedBookingsStore, RequestPasscodeStore)
├── screens/             # Top-level customer screens (Splash, Landing, Login, registration, OTP, Home, SubCategories, ServiceRequestForm/Requests/Detail, Profile, AddAddress, CategoryPicker, ServiceProviders); screens/provider/<feature>/ for the 5 Provider Dashboard tabs and their detail pages (there is no drawer)
├── widgets/             # Reusable UI (AuthCardScaffold + auth field helpers, MainNavigationShell + AppBottomNavigation, MainCategoryCard, SubcategoryCard, FeaturedServicesCarousel, dialogs, widgets/provider/ for dashboard-specific widgets)
├── utils/               # constants.dart (colors, kApiBaseUrl, kApiFileBaseUrl), dev_http_overrides.dart, api_error.dart, motion.dart, guest_guard.dart, provider_routes.dart, category_icons/category_images/service_catalog_style/service_colors, status_progress.dart, cancel_reasons.dart, platform_date_picker.dart, privacy_policy_launcher.dart, provider_availability_helper.dart, customer/provider_terms_and_conditions.dart
└── main.dart            # App entry point, MultiProvider setup, route table
```

## Navigation
All screens use named routes defined in `SahulatApp.routes` (`lib/main.dart`). Add new routes there before pushing to them. Provider-dashboard route name constants live in `lib/utils/provider_routes.dart` (`ProviderRoutes`).

## Dependencies
- `provider` — state management
- `http` / `http_parser` — REST API calls (incl. multipart uploads for provider documents)
- `image_picker` — camera/gallery picks for provider document upload (profile photo, CNIC front/back)
- `flutter_secure_storage` — persisted login session
- `sqflite` / `path` — listed but **unused** (dead weight left over from the removed legacy Service/Booking stack, see Architecture Overview); nothing in `lib/` imports either
- `path_provider` — re-downloading already-uploaded provider documents to resend on partial re-upload (`ProviderDocumentProvider._resolveFile`)
- `intl` — date/time formatting
- `flutter_animate` — UI animations
- `fl_chart` — listed but **unused**; nothing in `lib/` imports it (the wallet tab renders no charts)

## Project Skills (`.claude/skills/`)
- **flutter-apply-architecture-best-practices** / **flutter-build-responsive-layout** / **flutter-animations** — Flutter reference workflows for layering (UI/Logic/Data), adaptive layout, and motion.
- **improve-animations** / **review-animations** — motion audit (planning, read-only) and diff review against a craft bar.
- **use-api-docs** — read `api.txt` before any API-related work; keep it in sync when contracts change. Applies automatically to API integration tasks.
- **github-commit** — the standard workflow for "commit and push to github"-style requests (safe commits, secret scanning, `.gitignore` hygiene).
- **update-db-docs** — introspects the live `SahulatAppDB` schema via a provided connection string and updates DB docs (`db.txt`/`Database.md`/`db.md`) if/when those exist.
- **sql-pro** — SQL query design/optimization workflow, for direct database work against `SahulatAppDB`.

## Important Notes
- The app initializes with `WidgetsFlutterBinding.ensureInitialized()` and installs `DevHttpOverrides` (debug-only) before `runApp()` — keep both ahead of any network-dependent init.
- Material 3 is enabled (`useMaterial3: true`). Use `kPrimaryColor` / `kSecondaryColor` / `kAccentColor` from `lib/utils/constants.dart` for theme consistency; shared auth-styled screens should reuse `AuthCardScaffold`, `authFieldDecoration()`, `authFieldLabel()`, `AuthPrimaryButton`, and `GenderSelector` from `lib/widgets/auth_card_scaffold.dart`.
- **Dart SDK constraint is `>=2.18.0 <3.0.0`** (see `pubspec.yaml`) — Dart records (`(a, b)` tuple syntax) and other Dart 3-only language features are **not available**. Use parallel indexed arrays/lists instead.
- The codebase has been fully migrated to `Color.withValues(alpha: ...)` — there are zero remaining `withOpacity()` calls. Use `withValues` in new code.
- `docs/PRIVACY_POLICY.md` is the source of truth for what the app claims to collect/share/delete — cross-check it before adding or changing anything touching personal data (new profile fields, new data shared between Customers/Providers, new SDKs), and update it in the same change if the claim would otherwise go stale.
- `docs/APP_STORE_AUDIT_REPORT.md` tracks App Store / Play Store compliance readiness (permissions, privacy, encryption declarations, UI polish like edge-to-edge/SafeArea) — check it before iOS/Android store-submission-related work and update it if you resolve or introduce a compliance-relevant item.
- Android edge-to-edge: `MainActivity.kt` + a `SystemUiOverlayStyle` set up so the branded bottom dock sits transparently behind the system nav bar (Android 15+ ignores solid nav-bar colors) — don't reintroduce an opaque nav bar color. New auth screens and the request-detail page use `SafeArea` for the iOS notch/Dynamic Island and Android system bars; follow that pattern for new full-bleed screens.
- API service methods should convert raw exceptions (timeouts, connection errors) into friendly, readable messages before they reach the UI — see the pattern already applied across `lib/services/*_api_service.dart` — rather than surfacing raw exception text to users.
