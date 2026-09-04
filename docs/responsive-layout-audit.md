# Responsive / Adaptive Layout Audit

Audit date: 2026-09-03
Implementation passes reviewed: 2026-09-04 (five passes)
Scope: `lib/`
Method: manual review + `grep` sweeps across `lib/`, evaluated against
`.claude/skills/flutter-build-responsive-layout`.

**Baseline for any further work**: `flutter analyze lib test` must stay at
**13 issues** (12 `prefer_const_constructors` + 1 `use_super_parameters`, all
pre-existing) and `flutter test` at **17/17**. Both green as of the last pass.

## 1. State of play

The app no longer stretches edge-to-edge on wide windows. Grids gain columns
with available width, the four primary content screens are capped and centred,
and the one eager backend-driven list is lazy. What the app still does **not**
do is change its layout *shape* at any width — every screen returns the same
single-column tree, just narrower relative to the window. That was a deliberate
call (see §4), not an oversight.

| Signal | At audit | Now |
|---|---|---|
| Screens capping content width | 0 | 4 |
| `GridView`s using width-derived column counts | 0 / 3 | 3 / 3 |
| Eager `ListView(children:)` over backend data | 1 | 0 |
| Hardcoded pixel widths (`width: <n≥100>`) | 20 | 1 |
| Broad `MediaQuery.of(context)` reads | 3 | 1 |
| Widgets with hover + keyboard focus (ripple visible) | 0 | 11 |
| Screen-root breakpoint layouts | 0 | 0 |
| Orientation locks / `OrientationBuilder` / hardware-type checks | 0 | 0 |

## 2. Resolved

**Grid column counts** — all three sites use
`SliverGridDelegateWithMaxCrossAxisExtent` + `.builder`
(`home_screen.dart:236`, `provider_home_tab.dart:155`,
`subcategories_screen.dart:224`). Column math verified against each site's real
padding chain:

| Screen | 320dp | 390dp | 768dp | 1200dp | Was |
|---|---|---|---|---|---|
| `home_screen` | 2 | 2 | 4 | 4 (capped) | fixed 2 |
| `provider_home_tab` | 2 | 2 | 4 | uncapped | fixed 2 |
| `subcategories` | **2** | 3 | 5 | 6 (capped) | fixed 3 |

Phone rendering is unchanged except `subcategories`, which drops to 2 columns
below ~345dp — cards go from ~77dp to ~122dp wide. Confirm visually (Task A).

**Content width capping** — `Center` + `ConstrainedBox(maxWidth: kContentMaxWidth)`
on `home_screen.dart:214`, `service_requests_screen.dart:178`,
`request_detail_screen.dart:270`, `subcategories_screen.dart:155`. All four
placements were checked for layout regressions and are sound: inside
`SingleChildScrollView`/`SliverToBoxAdapter` the vertical constraint is
unbounded so `Align` shrink-wraps rather than expanding; in the `subcategories`
`Stack` the parent `Expanded` bounds it and the inner `Column` is
`mainAxisSize.max`, so the vertical centring is a no-op.
`_SearchSuggestionsOverlay` is capped separately at `kOverlayMaxWidth` since it
renders outside the page column. `request_detail_screen.dart:967`
(`maxWidth: 380`) was correctly left alone — it sizes an inline status chip.

**Lazy rendering** — `wallet_tab.dart:72` converted from an eager
`ListView(children:)` spreading `wallet.transactions.map(...)` to a
`CustomScrollView` + `SliverList.builder`. All grids use `.builder`.
`edit_profile_screen.dart:81` and `verification_documents_screen.dart:116` keep
eager `ListView`s but with fixed static children — acceptable.

**Hardcoded widths** — 20 → 1 via `lib/widgets/decorative_glow_circle.dart`
(shared scaling header circle, 9 call sites) and `appLogoSize()` in
`lib/utils/breakpoints.dart` (shared by landing + splash).

**Orientation and input-source handling** — no `setPreferredOrientations`, no
`OrientationBuilder`/`MediaQuery.orientationOf` layout switching, no
hardware-type checks. Android manifest sets no `screenOrientation`; iOS
`Info.plist:62-74` allows portrait + both landscape, plus upside-down on iPad.
Clean against the skill; no action needed.

## 3. Remaining work

Three tasks tracked. Task B is closed as of pass 5 (kept below for its
deliberate-exception note); Task C is partly done. Task A (the only High item
left) needs a human at a resizable window — it can't be completed from here.

### Task A — Verify on a resized window *(High)*

The skill ends both of its workflows with the same step: *run validator →
resize the application window → review layout transitions → fix overflow
errors.* That has not been done. The capping work above is verified-compiles,
not verified-correct.

Run `flutter run -d windows` (or `-d chrome`), drag the window from phone width
to desktop width and back, and check:

- No overflow errors in either direction, at any width.
- `subcategories` at <345dp — is 2 columns better than the old 3? If not, lower
  `maxCrossAxisExtent` at `subcategories_screen.dart:224`.
- `DecorativeGlowCircle` scales header circles *up*, to 1.8× on wide viewports
  (a 180dp circle becomes 324dp). Deliberate, but opposite to the skill's
  "constrain on large screens" guidance. If it looks wrong, change the upper
  clamp at `decorative_glow_circle.dart:15` from `baseSize * 1.8` to `baseSize * 1.0`.
- `landing_screen.dart` and `splash_screen.dart` are full-bleed `Stack`s with no
  `SafeArea` — check for clipping under notches/status bars. Add `SafeArea` only
  if it actually clips.
- Does the capped 840dp column look sparse on `service_requests_screen`? If so,
  convert its `ListView.separated` (`:220`) to a `GridView.builder` with
  `SliverGridDelegateWithMaxCrossAxisExtent`, per the skill's large-screen
  workflow. If it looks fine, close this without a change.

### Task B — Finish input accessibility *(Medium)* — **done, pass 5**

The skill asks for mice, trackpads, keyboard navigation, and appropriately
sized touch targets. All flagged bare `GestureDetector`s are now `InkWell`
(gaining hover, focus, and splash together): `featured_services_carousel.dart`,
`status_filter_tabs.dart`, `provider/document_image_slot.dart` (the remove-photo
button), `provider_home_tab.dart` (online/offline toggle),
`request_detail_screen.dart` (the provider-photo avatar), and the "Create
account"/"Login"/"Resend" text links in `login_screen.dart`,
`customer_registration_screen.dart`, `provider_registration_screen.dart`,
`otp_verification_screen.dart`.

**Deliberately left as `GestureDetector`**: `request_detail_screen.dart`'s
full-screen photo-dismiss overlay (in `_showEnlargedPhoto`). It wraps an
`InteractiveViewer`; an `InkWell` there would both paint a ripple over the
photo and compete with `InteractiveViewer`'s own pan/zoom gesture arena. The
existing plain-tap-to-dismiss is the correct pattern for this one case.

**Not done**: touch-target size verification (needs a device/inspector, not a
code change — folds into Task A).

### Task C — Housekeeping sweep *(Low)* — **partly done, pass 5**

- ~~Run `dart format lib/`~~ — **not done**. Still recommended as its own
  standalone commit before or after this work lands, not bundled here, since
  it touches every file with no behavior change.
- `auth_card_scaffold.dart:31` — **done**: now `MediaQuery.paddingOf(context).top`.
- `provider/jobs/booking_detail_screen.dart:429` — **still deliberately
  skipped**; this doc's own guidance says land it with the Phase 3 screen
  split, not standalone, and that reasoning hasn't changed.
- `pubspec.yaml` SDK floor — **done**: raised `>=2.18.0 <3.0.0` →
  `>=3.0.0 <4.0.0`. Running `dart format` after the change triggered `pub get`
  and picked up 4 newer dev-dependency patch versions (`matcher`, `meta`,
  `test_api`, `vector_math`) already anticipated by an earlier commit on this
  branch.

## 4. Deferred by decision — screen-root breakpoint layouts

The original audit's top finding was that the app has no breakpoint logic. The
skill's primary workflow is exactly this: wrap in `LayoutBuilder`, read
`constraints.maxWidth`, and return a different tree above/below a threshold.

This was **closed by decision rather than implemented**: `kCompactMaxWidth` was
removed from `lib/utils/breakpoints.dart` and no screen-root `LayoutBuilder` was
added. Content capping (§2) delivers most of the practical benefit for far less
code, which is a reasonable trade for a phone-first app.

Recorded here so it is a known gap rather than a forgotten one. To re-open,
restore the constant and start with `service_requests_screen` (status filters as
a left rail beside the list) or `home_screen` (featured carousel beside the
services grid). Extract the current tree into `_buildCompactLayout()` verbatim
first, confirm nothing changed, then write the wide variant — and use
`constraints.maxWidth`, not `MediaQuery.sizeOf`, so the decision reflects the
space the parent actually allocated.

## 5. Change log

**Pass 1 — grids and decorative sizing**: grid delegate swap ×3;
`GridView.count` → `.builder` in `provider_home_tab`; extracted
`DecorativeGlowCircle` across 9 call sites; landing logo clamped.

**Pass 2 — capping, lazy lists, shared constants**: `Center` +
`ConstrainedBox` on 4 screens; new `lib/utils/breakpoints.dart`; search overlay
capped and moved to `sizeOf`; `wallet_tab` converted to
`CustomScrollView` + `SliverList.builder`; splash logo clamped; pointer cursors
on two cards.

**Pass 3 — accessibility and cleanup**: `MouseRegion`/`GestureDetector` →
`Material`/`InkWell` on both category cards; `appLogoSize()` helper shared by
landing + splash; redundant `Builder` removed; `kCompactMaxWidth` deleted (§4);
`dart format` run on four screens.

**Pass 4 — ink-splash and helper consistency**: moved the card fill from the
`Container` onto `Material(color: …)` in `main_category_card.dart` so the
`InkWell` ripple is no longer hidden behind a 25%-opaque layer (matching
`subcategory_card.dart`); hoisted `appLogoSize(context)` to a local in
`landing_screen.dart`, matching `splash_screen.dart`.

**Pass 5 — Task B/C from §3**: converted 9 remaining bare `GestureDetector`
sites to `Material`+`InkWell` across `featured_services_carousel.dart`,
`status_filter_tabs.dart`, `provider/document_image_slot.dart`,
`provider_home_tab.dart`, `request_detail_screen.dart`, `login_screen.dart`,
`customer_registration_screen.dart`, `provider_registration_screen.dart`,
`otp_verification_screen.dart` (one site, the photo-dismiss overlay in
`request_detail_screen.dart`, deliberately left as `GestureDetector` — see
Task B); `auth_card_scaffold.dart` moved to `MediaQuery.paddingOf`; raised the
`pubspec.yaml` SDK floor to `>=3.0.0 <4.0.0`. `dart format`, scoped to each
touched file (not a repo-wide pass), surfaced one new
`curly_braces_in_flow_control_structures` lint in
`provider_registration_screen.dart` from a pre-existing line pushed over the
wrap threshold — fixed with explicit braces.

All five passes verified at `flutter analyze lib test` = 13 (baseline) and
`flutter test` = 17/17.
