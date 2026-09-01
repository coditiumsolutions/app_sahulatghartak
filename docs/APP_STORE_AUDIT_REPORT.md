# App Store Compliance & Readiness Audit Report

**Scope:** Static analysis of `lib/`, `ios/Runner/Info.plist`, `pubspec.yaml`, and routing/config.
**Method:** Read-only inspection (grep/read across the repo) plus verification against implemented fixes.
**App type:** Home-services marketplace — customers book providers for physical, in-person services (cleaning, repairs, etc.); no digital goods or in-app content sales.
**Status update (2026-09-01):** All Critical and Warning items from the original pass are resolved, including a third critical finding identified in a follow-up pass — forced account creation to browse the app (Guideline 5.1.1), which is a common and severe rejection reason on its own. Remaining items are UI/UX polish only.

---

## Executive Summary

| Severity | Count | Items |
|---|---|---|
| 🔴 Critical Rejection Risks | 0 | ~~Non-functional social login buttons~~ (removed), ~~non-functional "Forgot password"~~ (implemented), ~~forced login/registration before browsing (Guideline 5.1.1)~~ (Guest Mode added) — all three resolved |
| 🟡 Warnings | 0 | ~~Privacy Policy not linked in-app~~, ~~missing `ITSAppUsesNonExemptEncryption`~~ — both resolved |
| 🔵 UI/UX Enhancements | 0 | ~~Material-only UI on iOS~~ — light-touch native polish applied (swipe-back confirmed, platform-aware date/time pickers) |

**Good news:** Account deletion (Guideline 5.1.1(v)) is already implemented cleanly for both customer and provider roles, no third-party social SDKs are integrated (so Guideline 4.8 doesn't currently apply), there's no in-app payment/IAP surface to worry about under 3.1.1, the local-dev-vs-production API switch (`lib/utils/constants.dart`) is correctly gated behind `kDebugMode` with no stray hardcoded `localhost` URLs elsewhere in `lib/`, and the Privacy Policy is now confirmed **live** at [https://sahulatghartak.com/privacy-policy](https://sahulatghartak.com/privacy-policy) — that submission blocker from the previous audit pass is resolved.

---

## 1. Critical Rejection Risks — ALL RESOLVED (3 found, 3 fixed)

### 1.1 Non-functional "social sign-in" buttons on the Login screen — ✅ Resolved

- **Rule/Guideline Affected:** App Store Guideline 2.1 (App Completeness).
- **Original Finding:** `lib/screens/login_screen.dart` rendered Google/Facebook/Apple buttons that only showed a "coming soon" toast, with no corresponding auth SDKs in `pubspec.yaml`.
- **Fix Verified:** The social sign-in row and its `_socialButton`/`_showComingSoon` helpers have been removed from `lib/screens/login_screen.dart`. `grep -rn "social" lib/screens/login_screen.dart` now returns no hits. Login screen only exposes the working mobile-number/password flow.

### 1.2 Non-functional "Forgot password?" control — ✅ Resolved

- **Rule/Guideline Affected:** App Store Guideline 2.1 (App Completeness).
- **Original Finding:** `lib/screens/login_screen.dart` wired "Forgot password?" to a placeholder toast instead of a real flow.
- **Fix Verified:** A full reset-password flow now exists and is wired end-to-end: `lib/screens/forgot_password_screen.dart` → OTP verification (`lib/screens/otp_verification_screen.dart`) → `lib/screens/reset_password_screen.dart`, backed by real `POST /api/auth/reset-password` and OTP endpoints. Tested live against the local backend in this session (created a test account, requested a reset, verified OTP, set a new password, confirmed login with the new password) — the full round trip works.

### 1.3 Forced account creation to browse the app — ✅ Resolved

- **Rule/Guideline Affected:** App Store Guideline 5.1.1(i) (Data Collection and Storage). This is a **critical, standalone rejection reason** — Apple's review guidelines explicitly prohibit requiring registration/login just to view basic app information or browse content unless a core feature genuinely depends on an account, and reviewers routinely reject on first launch if there's no way past a login/register wall.
- **Original Finding:** `lib/screens/splash_screen.dart` routed every logged-out user straight to `lib/screens/landing_screen.dart`, whose only two actions were "Register" and "Login" — there was no way to see a single service category without creating an account first, even though category/service browsing itself has no account dependency in the underlying providers. This finding was missed in the original audit pass and surfaced in a follow-up review; it carries the same severity as 1.1/1.2 since it is a documented, frequently-cited App Store rejection trigger.
- **Fix Implemented:**
  - `lib/screens/landing_screen.dart` — added a "Continue as Guest" link that pushes straight into `HomeScreen.routeName` (the main tabbed shell), alongside the existing Register/Login buttons.
  - Category browsing (`HomeScreen`, `SubCategoriesScreen`, `ServiceDetailScreen`, `ServiceProvidersScreen`) required no changes — none of these screens read `AuthProvider`, so they already work unauthenticated.
  - Actions that need an account are now gated individually at the point of use via a new shared guard, `lib/utils/guest_guard.dart`'s `ensureLoggedIn()`, rather than blocking entry to the app:
    - Submitting a service request (`lib/screens/home_screen.dart`'s search-suggestion tap, `lib/screens/subcategories_screen.dart`'s category-grid tap) — a guest tapping either now sees a branded "Login Required" dialog and is routed to `LoginScreen` instead of the request form.
    - The **Requests** tab (`lib/screens/service_requests_screen.dart`) now shows a "Log in to see your requests" prompt with a direct Log In action instead of silently rendering an empty list for guests.
    - The **Profile** tab (`lib/screens/profile_screen.dart`) now shows a "You're browsing as a guest" card with Log In / Create Account actions instead of the previous bare "Not logged in" text.
  - Verified via `flutter analyze` (no new errors/warnings introduced) and by re-reading the render path of each guarded screen to confirm the `!isLoggedIn` branch renders standalone (doesn't dereference `currentUser`).
- **Manual verification still needed:** Run through the guest path on-device (Continue as Guest → browse a category → attempt to submit a request → confirm the login prompt appears → complete login → confirm the request form now opens) before submission — this is the highest-priority manual check remaining given the severity of the original finding.

## 2. iOS UI/UX & Native Experience Audit

Since this is a shared Flutter codebase (one `lib/` tree shipping to both iOS and Android from `android/` and `ios/`), a few of these findings are framed cross-platform where the same unguarded layout code creates a matching failure mode on Android — notably 2.1, which now covers both iOS's home indicator/notch and Android's system navigation area (3-button nav bar, or the gesture-nav pill on newer Android).

### 2.1 Inconsistent `SafeArea` coverage (iOS home indicator **and** Android navigation bar) — ✅ Resolved

- **Original Issue:** Bottom system chrome (iOS home indicator, Android 3-button/gesture nav) could obscure content on screens without a `SafeArea` wrap, and Android 15/API 35's enforced edge-to-edge mode made the app's own gradient bottom nav bar show a stray white/uncolored strip behind the 3-button dock.
- **Fix Verified:**
  - `lib/widgets/auth_card_scaffold.dart` now computes a dynamic top inset (`(topInset - 20).clamp(...)`) so headers clear the Dynamic Island/notch, and wraps its scrollable content in `SafeArea(top: false, ...)` so bottom system chrome no longer clips form content (Login/Registration/Reset screens).
  - `lib/screens/request_detail_screen.dart` wraps its scroll body in `SafeArea(top: false, ...)` — the previously-clipped request-details card now has proper bottom clearance.
  - `android/app/src/main/kotlin/.../MainActivity.kt` now calls `WindowCompat.setDecorFitsSystemWindows(window, false)` and `lib/widgets/bottom_nav.dart` / `lib/widgets/provider/provider_bottom_nav.dart` / `lib/main.dart` set `systemNavigationBarColor: Colors.transparent` — this is the correct fix for Android 15+ (the OS makes `systemNavigationBarColor` tinting a no-op from API 35 onward; transparency + edge-to-edge is the only supported approach), and was verified against a real device.
  - Flow-critical messages ("Account not found", "Password reset successfully", etc.) were also upgraded from easy-to-miss `SnackBar`s to a branded, must-dismiss dialog (`lib/widgets/message_dialog.dart`) on both platforms.

### 2.2 Material-only UI on iOS — ✅ Resolved (light-touch pass)

- **Issue Description:** No use of `Cupertino*` widgets or `PlatformAdaptive`-style patterns was found; the app is built entirely on Material widgets (`ElevatedButton`, `Scaffold`, Material `Icons`, etc.). This was never an App Store rejection reason by itself, but reviewers and users do notice back-navigation and pickers that don't match iOS conventions.
- **Scope decision:** Not required for approval, so a full Cupertino rewrite (branching every dialog/switch/control by platform) was deliberately skipped as unnecessary risk/effort for a non-blocking item. A light-touch pass was applied instead:
  - **iOS swipe-back gesture:** Already present with no code changes needed — `lib/main.dart`'s `ThemeData` never overrides `pageTransitionsTheme`, so Flutter's Material 3 default (`CupertinoPageTransitionsBuilder` on iOS/macOS) already applies to every route. All navigation in the app goes through `MaterialPageRoute`/named routes (`grep` for `PageRouteBuilder`/`CupertinoPageRoute` across `lib/` returns no hits), so nothing was overriding or blocking the native edge-swipe-to-pop gesture.
  - **Native-feeling date/time pickers:** Added `lib/utils/platform_date_picker.dart` (`showPlatformDatePicker` / `showPlatformTimePicker`), which shows a `CupertinoDatePicker` wheel in a modal sheet on iOS and falls back to the existing Material calendar/clock dial elsewhere. Wired into all three call sites: `lib/screens/service_request_form_screen.dart`, `lib/screens/booking_screen.dart`, and `lib/utils/provider_availability_helper.dart` (provider availability-hours dialog).
- **Verified:** `flutter analyze` clean (no new errors/warnings).
- **Note (unrelated, flagged not fixed):** `lib/screens/booking_screen.dart`, reachable from `lib/screens/service_detail_screen.dart`'s "Book Now" button, appears to be an older/unbranded duplicate of the real booking flow (`lib/screens/service_request_form_screen.dart`) — plain yellow `AppBar`, out of step with the rest of the app's styling. Out of scope for this audit pass; worth a follow-up decision on whether to retire it or restyle it.

---

## 3. Metadata, Permissions & Config Verification

### 3.1 Info.plist Review

| Permission Key | Present? | Description Quality |
|---|---|---|
| `NSCameraUsageDescription` | ✅ (`ios/Runner/Info.plist:29-30`) | Good — specific: *"...uses your camera to capture your profile photo and CNIC images during provider registration."* |
| `NSPhotoLibraryUsageDescription` | ✅ (`ios/Runner/Info.plist:31-32`) | Good — specific: *"...needs access to your photo library to select your profile photo and CNIC images..."* |
| `NSLocationWhenInUseUsageDescription` | ❌ Not present | Not currently needed — no `geolocator`/location plugin found in `pubspec.yaml`; address entry (`lib/screens/add_address_screen.dart`) appears to be manual text entry, not GPS-based. No action required unless location capture is added later. |
| `NSMicrophoneUsageDescription` | ❌ Not present | No audio/video capture code found (`image_picker` is used for stills only) — not currently needed. |
| `NSUserTrackingUsageDescription` (ATT) | ❌ Not present | No analytics/ad-tracking SDK found in `pubspec.yaml` — not currently needed. If any analytics SDK (Firebase Analytics, Facebook SDK, etc.) is added later, this key plus an ATT prompt becomes mandatory. |

Both present permission strings are specific and user-facing (they name the exact feature — CNIC/profile photo capture), which is exactly what Apple's guidance ("purpose strings must explain why, in context") expects. No generic placeholder text ("This app needs your camera") was found.

### 3.2 Network & Build Flags

- **Release endpoint switch:** `lib/utils/constants.dart:36-38` correctly branches on `kDebugMode`:
  ```dart
  final String kApiBaseUrl = kDebugMode
      ? 'https://$_devHost:7265/api'
      : 'https://sahulatghartak.com/api';
  ```
  No other file in `lib/` hardcodes `localhost`/`127.0.0.1`/`10.0.2.2` — verified via repo-wide search. Release/profile builds correctly resolve to the production host.
- **SSL/cert override:** `lib/utils/dev_http_overrides.dart` installs a `badCertificateCallback` that trusts self-signed certs, but only for `localhost`, `127.0.0.1`, `10.0.2.2`, and private LAN ranges (`10.x`, `192.168.x`, `172.16-31.x`) — see `_isTrustedDevHost` at `lib/utils/dev_http_overrides.dart:13-27`. It is only installed when `kDebugMode` is true (`lib/main.dart:44-48`), so it is compiled out of release builds and never weakens cert validation against the production domain. No action needed.
- **Export compliance flag:** ✅ Resolved — `<key>ITSAppUsesNonExemptEncryption</key><false/>` is now present at `ios/Runner/Info.plist:27-28`, so App Store Connect will no longer prompt the export-compliance question on future uploads.
- **Debug logging:** No `print()`/`debugPrint()` calls found in `lib/` — clean.

### 3.3 Privacy Policy hosting status — ✅ Resolved

- **Status:** Confirmed live at [https://sahulatghartak.com/privacy-policy](https://sahulatghartak.com/privacy-policy). `docs/PRIVACY_POLICY.md` reflects this. Submitting to App Store Connect with this URL as the App Privacy → Privacy Policy URL is unblocked.
- **In-app link:** Added — `lib/utils/privacy_policy_launcher.dart` defines `kPrivacyPolicyUrl` and a launch helper, now wired into both `lib/screens/profile_screen.dart:359` and `lib/screens/provider/profile/profile_tab.dart:302`.
- **Web account-deletion page:** Confirmed live at [https://sahulatghartak.com/delete-account](https://sahulatghartak.com/delete-account), matching the promise in Section 7 of `docs/PRIVACY_POLICY.md`.

---

## 5. Action Plan & Next Steps

All Critical, Warning, and UI/UX items are resolved. Remaining items are manual verification or deferred/out-of-scope follow-ups:

1. **[Critical, verify before submission]** Manually run through the guest-browsing path on-device per section 1.3 (Continue as Guest → browse → attempt booking → login prompt → login → booking succeeds) — highest priority given this closed a critical rejection risk.
2. **[UI/UX, verify on-device]** Confirm the new iOS date/time pickers (booking form, provider availability-hours dialog) look and behave correctly on an iOS simulator/device per section 2.2.
3. **[Follow-up, out of scope]** Decide whether to retire or restyle `lib/screens/booking_screen.dart`, an apparently-outdated duplicate booking flow reachable from the service detail screen — see note in section 2.2.
4. **[Warning, deferred]** If any analytics/ads SDK is added later, add `NSUserTrackingUsageDescription` and wire up an ATT prompt at that time — not needed today.

---

*All file paths above were verified to exist in this repository as of the audit date (2026-09-01).*
