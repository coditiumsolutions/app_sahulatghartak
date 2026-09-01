# App Store Compliance & Readiness Audit Report

**Scope:** Static analysis of `lib/`, `ios/Runner/Info.plist`, `pubspec.yaml`, and routing/config.
**Method:** Read-only inspection (grep/read across the repo). No code was modified.
**App type:** Home-services marketplace — customers book providers for physical, in-person services (cleaning, repairs, etc.); no digital goods or in-app content sales.

---

## Executive Summary

| Severity | Count | Items |
|---|---|---|
| 🔴 Critical Rejection Risks | 2 | Non-functional social login buttons, non-functional "Forgot password" |
| 🟡 Warnings | 3 | Privacy Policy not yet linked in-app; missing `ITSAppUsesNonExemptEncryption`; `Info.plist` doesn't declare a Privacy Policy link |
| 🔵 UI/UX Enhancements | 2 | Inconsistent `SafeArea` coverage — bottom system chrome (iOS home indicator, Android 3-button/gesture nav) can obscure content on unwrapped screens; Material-only UI on iOS (no Cupertino affordances) |

**Good news:** Account deletion (Guideline 5.1.1(v)) is already implemented cleanly for both customer and provider roles, no third-party social SDKs are integrated (so Guideline 4.8 doesn't currently apply), there's no in-app payment/IAP surface to worry about under 3.1.1, the local-dev-vs-production API switch (`lib/utils/constants.dart`) is correctly gated behind `kDebugMode` with no stray hardcoded `localhost` URLs elsewhere in `lib/`, and the Privacy Policy is now confirmed **live** at [https://sahulatghartak.com/privacy-policy](https://sahulatghartak.com/privacy-policy) — that submission blocker from the previous audit pass is resolved.

---

## 1. Critical Rejection Risks (Immediate App Store Rejections)

### 1.1 Non-functional "social sign-in" buttons on the Login screen

- **Rule/Guideline Affected:** App Store Guideline 2.1 (App Completeness) — Apple explicitly flags UI elements that are present but non-functional ("buttons/links that don't work" is one of the most common 2.1 rejection reasons in review notes).
- **Current Finding:** `lib/screens/login_screen.dart:57-73` defines `_socialButton`, whose `onTap` calls `_showComingSoon(label)` (line 59), which just shows a `SnackBar` reading `"$feature coming soon"` (line 53-55). It's wired up to three rendered buttons at lines 133-137:
  ```dart
  _socialButton(icon: Icons.g_mobiledata, color: const Color(0xFFDB4437), label: 'Google sign-in'),
  _socialButton(icon: Icons.facebook, color: const Color(0xFF1877F2), label: 'Facebook sign-in'),
  _socialButton(icon: Icons.apple, color: Colors.black, label: 'Apple sign-in'),
  ```
  No `google_sign_in`, `flutter_facebook_auth`, or `sign_in_with_apple` packages exist in `pubspec.yaml` — these are purely decorative placeholders.
- **Why it will fail:** Apple reviewers routinely tap every visible interactive control. A row of branded login icons that produce a "coming soon" toast reads as an incomplete/placeholder build, a textbook 2.1 rejection. It's also brand-risk: displaying Google/Facebook/Apple marks on buttons that don't perform the advertised action can trigger a guideline 4.8 / trademark-adjacent note even without those SDKs integrated, since the icons imply a real capability.
- **Suggested Remediation:** Two clean options:
  1. **Remove the row entirely** until real social auth is built (recommended for this release — the app already has a working mobile-number/password flow, and Guideline 4.8 only *requires* "Sign in with Apple" if you offer other third-party login options; removing the row removes that obligation too). Delete lines 119-139 (`Row`/divider + `_socialButton` row) and the now-unused `_socialButton`/`_showComingSoon` helpers if nothing else calls them.
  2. If social login is actually planned for this release, implement it for real (`google_sign_in`, `sign_in_with_apple`) and ensure Apple's button ships alongside any other third-party provider per 4.8.

### 1.2 Non-functional "Forgot password?" control

- **Rule/Guideline Affected:** App Store Guideline 2.1 (App Completeness) — same "non-functional control" pattern as above.
- **Current Finding:** `lib/screens/login_screen.dart:111-114`:
  ```dart
  TextButton(
    onPressed: () => _showComingSoon('Password reset'),
    child: const Text('Forgot password?', ...),
  ),
  ```
- **Why it will fail:** Same reasoning as 1.1 — a visibly enabled, prominently placed button that only shows a placeholder toast is an easy manual-review catch, and it's also a real UX gap for locked-out users pre-launch.
- **Suggested Remediation:** Either hide the button until a password-reset flow (there is already `sendOtp`/`resendOtp`/`verifyOtp` in `lib/services/auth_api_service.dart:63-75` used for registration OTP — check if it can be reused for a reset-password OTP flow with the backend team) ships, or implement the reset screen now since the OTP primitives already exist server-side.

## 2. iOS UI/UX & Native Experience Audit

Since this is a shared Flutter codebase (one `lib/` tree shipping to both iOS and Android from `android/` and `ios/`), a few of these findings are framed cross-platform where the same unguarded layout code creates a matching failure mode on Android — notably 2.1, which now covers both iOS's home indicator/notch and Android's system navigation area (3-button nav bar, or the gesture-nav pill on newer Android).

### 2.1 Inconsistent `SafeArea` coverage (iOS home indicator **and** Android navigation bar)

- **Issue Description:** Only 13 of the app's screens/widgets use `SafeArea`, against 31 files that build a `Scaffold`. This isn't only an iOS concern: on Android, `MediaQuery.padding.bottom` reflects whichever system navigation mode the device is using — the classic 3-button dock (back/home/recents), the 2-button variant, or the gesture-nav pill — and on newer Android versions (edge-to-edge is enforced by default from Android 15/API 35 onward) the app draws full-screen and is responsible for keeping content clear of that bar itself, exactly as it is on iOS for the notch/Dynamic Island/home indicator. An unwrapped screen risks the same visual bug on both platforms: content sitting under the status bar, or interactive elements (buttons, links) obscured by or overlapping the bottom system chrome.
- **Affected Components/Files:**
  - Screens with `Scaffold(` but no `SafeArea` at all: `lib/screens/login_screen.dart`, `lib/screens/provider_registration_screen.dart`, `lib/screens/customer_registration_screen.dart`, `lib/screens/provider/wallet/wallet_tab.dart`, `lib/screens/add_address_screen.dart`, and others under `lib/screens/provider/`.
  - **Concrete example of the bottom-inset gap:** `lib/widgets/auth_card_scaffold.dart:51-52` — the shared shell used by Login, Customer Registration, and Provider Registration — wraps only the top back-button in `SafeArea(bottom: false, ...)` (`lib/widgets/auth_card_scaffold.dart:51`). The scrollable form content below it (`SingleChildScrollView` at `lib/widgets/auth_card_scaffold.dart:71-72`) uses a fixed `EdgeInsets.fromLTRB(24, ..., 24, 24)` — a flat 24px bottom padding regardless of device. On a phone with a 3-button Android nav dock (or an iPhone home indicator), the last element in that scroll view (e.g. the "Create account" link, or a registration form's submit button) can end up rendered flush against, or under, that system chrome instead of clear of it.
  - Files already doing it right, worth using as the reference pattern: `lib/widgets/bottom_nav.dart:65-66` and `lib/widgets/provider/provider_bottom_nav.dart:47-48` both wrap their content in `SafeArea(top: false, ...)`, which correctly reserves space for whatever the platform's bottom system chrome is (home indicator on iOS, 3-button/gesture nav on Android) — this is why the app's own bottom tab bar doesn't have this problem, only the screens that lack any `SafeArea` do.
- **Best Practice Solution:** Since custom app bars/headers/shells are common here (`ProviderTabHeader`, `AuthCardScaffold`), the cleanest fix is centralizing `SafeArea` inside those shared wrappers rather than patching each screen individually. Specifically: change `lib/widgets/auth_card_scaffold.dart`'s inner `SingleChildScrollView` to also respect the bottom inset (e.g. wrap it in `SafeArea(top: false, child: ...)` alongside the existing top-only one, or add `MediaQuery.of(context).padding.bottom` to the scroll view's bottom padding) so Login/Registration forms get the same protection the bottom tab bars already have.

### 2.2 Material-only UI on iOS

- **Issue Description:** No use of `Cupertino*` widgets or `PlatformAdaptive`-style patterns was found; the app is built entirely on Material widgets (`ElevatedButton`, `Scaffold`, Material `Icons`, etc.). This is not an App Store rejection reason by itself (many approved apps ship Material on iOS), but reviewers and users do notice back-navigation, dialogs, and switches that don't match iOS conventions.
- **Affected Components/Files:** App-wide — `MaterialApp` in `lib/main.dart:72`, and Material widgets throughout `lib/screens/` and `lib/widgets/`.
- **Best Practice Solution:** Not required for approval; flagging as a polish item only. If desired, `flutter build ios` with `MaterialApp` already renders iOS-appropriate scroll physics/typography automatically in recent Flutter versions — no action needed unless you want native-feeling dialogs/date pickers (`showCupertinoModalPopup`, `CupertinoAlertDialog`) for a more native App Store presence.

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
- **Export compliance flag:** `ITSAppUsesNonExemptEncryption` is absent from `Info.plist`. This isn't a rejection risk (the app only uses standard HTTPS/TLS, which is exempt), but its absence means App Store Connect will prompt the export-compliance question on every submission. Adding `<key>ITSAppUsesNonExemptEncryption</key><false/>` to `ios/Runner/Info.plist` skips that manual step on future uploads.
- **Debug logging:** No `print()`/`debugPrint()` calls found in `lib/` — clean.

### 3.3 Privacy Policy hosting status (updated)

- **Status:** ✅ Resolved — confirmed live at [https://sahulatghartak.com/privacy-policy](https://sahulatghartak.com/privacy-policy). The trailing note in `docs/PRIVACY_POLICY.md` has been updated to reflect this. Submitting to App Store Connect with this URL as the App Privacy → Privacy Policy URL is no longer blocked.
- **Still open:**
  - **No in-app link yet.** `grep -rn "Privacy Policy" lib` still returns no hits — the app itself has no visible link to the policy (compare `lib/utils/customer_terms_and_conditions.dart` / `lib/utils/provider_terms_and_conditions.dart`, which *are* wired into the registration screens via `lib/widgets/terms_and_conditions_section.dart`). Apple doesn't strictly require an in-app link if the App Store Connect metadata URL is set, but it's expected best practice for apps collecting account/ID data and is worth adding. Suggested placement: next to "Delete Account" in `lib/screens/profile_screen.dart` and `lib/screens/provider/profile/profile_tab.dart`, using the already-imported `url_launcher` package:
    ```dart
    TextButton(
      onPressed: () => launchUrl(Uri.parse('https://sahulatghartak.com/privacy-policy')),
      child: const Text('Privacy Policy'),
    )
    ```
  - ~~Web account-deletion page unconfirmed~~ — **resolved.** [https://sahulatghartak.com/delete-account](https://sahulatghartak.com/delete-account) is now confirmed live, matching the promise in Section 7 of `docs/PRIVACY_POLICY.md`.

---

## 4. Action Plan & Next Steps

Ordered by severity — complete section 1 items before submitting a build for review.

1. **[Critical]** Remove or fully implement the social sign-in buttons — `lib/screens/login_screen.dart:119-139, 57-73`. (Recommended: remove for this release.)
2. **[Critical]** Remove or implement "Forgot password?" — `lib/screens/login_screen.dart:111-114`.
3. **[Done]** ~~Host the Privacy Policy at a public HTTPS URL~~ — confirmed live at [https://sahulatghartak.com/privacy-policy](https://sahulatghartak.com/privacy-policy). Register that URL in App Store Connect → App Privacy if not already set.
4. **[Warning]** Add an in-app link to the Privacy Policy from both profile screens (`lib/screens/profile_screen.dart`, `lib/screens/provider/profile/profile_tab.dart`) — see snippet in section 3.3.
5. **[Done]** ~~Confirm the web account-deletion page is live~~ — confirmed at [https://sahulatghartak.com/delete-account](https://sahulatghartak.com/delete-account).
6. **[Warning]** Add `ITSAppUsesNonExemptEncryption = false` to `ios/Runner/Info.plist` to skip the export-compliance prompt on every future submission.
7. **[Warning]** If any analytics/ads SDK is planned before submission, add `NSUserTrackingUsageDescription` and wire up an ATT prompt at that time — not needed today.
8. **[UI/UX]** Fix the bottom-inset gap in `lib/widgets/auth_card_scaffold.dart` (only the top back-button is `SafeArea`-wrapped; the scrollable form content isn't) so Login/Registration forms respect the bottom system inset the same way `bottom_nav.dart`/`provider_bottom_nav.dart` already do, then spot-check remaining bare-`Scaffold` screens (wallet tab, add-address) — test on both a notched iOS simulator and an Android device/emulator set to 3-button navigation, since both reserve real screen space at the bottom.
9. **[UI/UX, optional]** Consider Cupertino-styled dialogs/back gestures for a more native iOS feel — not required for approval.

---

*All file paths above were verified to exist in this repository as of the audit date. No source files were modified during this audit.*
