# Animation / Motion Audit

Audit date: 2026-09-03
Scope: `lib/` (read-only analysis, no code changed)
Method: manual review + `grep` sweeps across all 127 `.dart` files, evaluated
against `.claude/skills/flutter-animations` guidance (implicit vs. explicit
animation choice, controller lifecycle/disposal, Hero usage, staggered
timing, reduced-motion support).

## 1. Headline numbers

| Signal | Count | Notes |
|---|---|---|
| `AnimationController` usages | **0** | No explicit animations anywhere in the app |
| `Hero` widget usages | **0** | No shared-element route transitions anywhere |
| Implicit animated widgets (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedDefaultTextStyle`, `AnimatedPositioned`, `AnimatedCrossFade`, `AnimatedRotation`) | **14 occurrences across 8 files** | Corrected twice — originally 11, then 12 in §7, verified as 14 in §9. Per-file breakdown in §9.2 item 2 |
| `flutter_animate` (`.animate()`) usages | 2 files | `splash_screen.dart` (fade+scale intro), `main_navigation_shell.dart` (tab-switch scale, inside a `transitionBuilder`) |
| `TweenAnimationBuilder` usages | 1 | `home_screen.dart:608` (search-suggestion overlay) |
| `AnimatedBuilder` driven by a `Listenable` | 1 | `featured_services_carousel.dart:72` — parallax on the card image, driven by the `PageController` |
| **`OpenContainer` container transforms (`animations: ^2.0.11`)** | **4** | `main_category_card.dart:28`, `service_requests_screen.dart:286`, `jobs_tab.dart:139`, `rejected_requests_screen.dart:74`. **Missed by the original audit — see §9.2 item 1** |
| Custom `PageRouteBuilder` / named-route transition overrides | **0** | True as a keyword count, but *not* the same as "platform-default routes" — the four `OpenContainer` sites above are custom card → detail transitions |
| Shared motion constants file | Yes | `lib/utils/motion.dart` — durations + curves + `prefersReducedMotion` |
| `MediaQuery.disableAnimations` / reduced-motion checks | 11 call sites | Added in §8, completed in §10.5 — all 14 implicit animations plus the splash intro and search overlay are gated. Only the four `OpenContainer` transforms remain ungated (§10.6 item 1) |
| `Timer`-driven auto-advancing carousel | **1** | `featured_services_carousel.dart` (disposes correctly). `banner_slider.dart` has no `Timer` and is **unreferenced dead code** — see §9.2 item 5 |

**Overall** (revised after §9): this is a moderate-motion app. Its most
prominent motion is the `OpenContainer` container transform on card → detail
navigation — a deliberate, already-shipped choice that the original pass
missed entirely (§9.2 item 1). Around that, the implicit animations are
simple, correctly scoped, and free of the classic lifecycle bugs (no leaked
controllers, since there are no `AnimationController`s). The remaining gaps
are: no motion on meaningful in-place state changes (booking status, stat
values), and reduced-motion handling that now covers most but not all
decorative motion (§8, §9.3 item 8).

> **Reading order note.** §1–§6 were written before §8 (implementation) and
> §9 (verification). Where they conflict, **§9 and §10 are authoritative.**
> Sections corrected in place are marked inline; the two biggest reversals
> are the `Hero` recommendation (rejected — §8.5) and the "platform-default
> route transitions" premise (wrong — §9.2 item 1).

## 2. Findings by category

### 2.1 No explicit animations — a `dispose()`-bug class that simply doesn't exist here

Zero `AnimationController` usages means the most common Flutter animation
defect category (controllers created in `build()`, controllers never
disposed, `setState()` called after `dispose()` from a lingering listener) is
structurally absent from this codebase. This is worth stating plainly as a
**positive finding**, not a gap: there is no lifecycle risk to fix here
because there is no explicit-animation surface area yet.

The flip side: any future work that reaches for `AnimationController` (e.g.
implementing the staggered-list or physics-based motion suggested in §3)
will be the *first* instance of that pattern in the app.

> **Corrected in §9.2 item 3.** "No explicit-animation surface area" was an
> overstatement. `featured_services_carousel.dart:72` already drives an
> `AnimatedBuilder` off the `PageController` (a `Listenable`) to parallax the
> card image against the swipe, with correct `child` caching. So there *is* an
> in-repo exemplar for `AnimatedBuilder`-style explicit work — just not for a
> self-owned `AnimationController` with a `dispose()` lifecycle.

### 2.2 Implicit animations — used correctly, but narrowly scoped to navigation chrome

All implicit-widget usages are concentrated in navigation/tab UI. **Count
corrected in §9.2 item 2 — 14 across 8 files, not the 11 originally stated
here nor the 12 stated in §7.1.** The list below is the original text with
the two omissions restored in bold:

- `bottom_nav.dart` / `provider/provider_bottom_nav.dart` — `AnimatedContainer`
  (pill/indicator), `AnimatedDefaultTextStyle` (label emphasis),
  `AnimatedSwitcher` with a `ScaleTransition` builder (icon swap on tab
  select).
- `main_navigation_shell.dart` — `AnimatedSwitcher` with a combined
  `FadeTransition` + `ScaleTransition` builder (tab-body swap).
- `status_filter_tabs.dart` — `AnimatedDefaultTextStyle` +
  `AnimatedPositioned` (selected-tab indicator sliding).
- `auth_card_scaffold.dart` (gender selector, `:209`),
  `featured_services_carousel.dart` (dot indicator, `:127`) — single
  `AnimatedContainer` each.
- `terms_and_conditions_section.dart` — `AnimatedCrossFade` (`:61`,
  expand/collapse) **plus `AnimatedRotation` (`:51`, chevron) — omitted from
  the original list, the source of the running miscount.**
- **`provider/status_chip.dart` — `AnimatedSwitcher`, added later in §8.3.**

This is exactly the right widget choice per the skill's decision guide
("one property or a small set of state-driven visual changes" →
`AnimatedContainer`/`AnimatedSwitcher`/etc.), and durations/curves are
centralized in `lib/utils/motion.dart` rather than scattered as magic
numbers — a good practice already in place, **with one exception found in
§9.2 item 4: `featured_services_carousel.dart:31` hardcodes
`Duration(milliseconds: 400)` and `Curves.easeInOut` for its auto-advance,
bypassing the tokens entirely.**

**Gap**: outside of tab/nav chrome, almost none of the rest of the app has
any motion feedback at all. Concretely, based on the earlier structural
audits (`docs/architecture-audit.md`, `docs/responsive-layout-audit.md`):
- List/grid content (`GridView.builder` in `home_screen.dart`,
  `subcategories_screen.dart`, `provider_home_tab.dart`) has no entrance/
  reveal animation — items just appear.
- Async state transitions (loading → loaded → error, present in nearly every
  `*Provider`-backed screen per the architecture audit) render via plain
  conditional widget swaps (`if (loading) ... else if (error) ... else
  ...`), not `AnimatedSwitcher`, so switching between a spinner, an error
  card, and content pops instantly rather than cross-fading.
- Button press/tap feedback relies on default `Material`/`InkWell` ripple
  only — no custom press-scale or state-change confirmation animation (e.g.
  a checkmark morph on successful form submit, a shake on validation error).

None of this is a "bug" — the app functions correctly without this motion —
but it's the most direct opportunity for motion polish, since the
utility/convention layer (`motion.dart`) already exists and just isn't
applied broadly yet.

### 2.3 Route transitions — ~~deliberately platform-default, and zero `Hero` usage~~ **SUPERSEDED**

> **This entire subsection is wrong and is retained only for traceability.**
> See §9.2 item 1. The app runs Material **container transforms**
> (`OpenContainer`, from `animations: ^2.0.11`) on four card → detail flows —
> `main_category_card.dart:28`, `service_requests_screen.dart:286`,
> `jobs_tab.dart:139`, `rejected_requests_screen.dart:74` — present since
> commit `80ac295`, i.e. before this audit was written. The claim below that
> these navigations "cut instantly … with only the default slide/fade" is
> false for exactly the three flows it names. The `Hero` recommendation that
> follows from it was rejected on product grounds in §8.5 for this same
> reason. `lib/utils/motion.dart`'s doc comment repeats the same stale claim
> in code and should be corrected (§10.2 item 1).

*Original text follows.*

`lib/utils/motion.dart`'s doc comment explicitly states route transitions
use "Flutter's platform-default (Cupertino slide on iOS, Material on
Android) via plain `Navigator.push`/`pushNamed`, with no custom override."
This is confirmed by the `main.dart` route table (`lib/main.dart:86-109`),
which registers plain `MaterialPageRoute`-backed named routes with no custom
`PageRouteBuilder`.

This is a reasonable, low-maintenance choice, and explicitly documented as
intentional — not flagged as a defect. However, it does mean:
- **Zero `Hero` transitions exist anywhere**, despite the app having several
  natural shared-element candidates per the screens inventory: a service/category
  card tapped from `home_screen.dart`'s grid into `subcategories_screen.dart`
  or `category_picker_screen.dart`, a job/booking card tapped from
  `jobs_tab.dart`/`requests_tab.dart` into `booking_detail_screen.dart`, or a
  request card from `service_requests_screen.dart` into
  `request_detail_screen.dart`. Any of these navigations currently cut
  instantly from a small card to a full detail screen with only the default
  slide/fade — a `Hero` on the card's image/title would be a low-risk,
  high-perceived-polish addition since route structure is already in place
  (named routes, no custom transition to conflict with).

### 2.4 ~~No reduced-motion / accessibility handling~~ — **mostly resolved in §8.2**

> **Status: resolved.** `prefersReducedMotion()` was added to
> `lib/utils/motion.dart:26` in §8.2 and the sweep was completed in §10.5 —
> all 14 implicit animations, the splash intro, the search-suggestion
> overlay and the carousel auto-advance are now gated, and the helper uses
> the aspect-scoped `MediaQuery.disableAnimationsOf`. The one remaining gap
> is the four `OpenContainer` transforms, which the `animations` package
> does not gate on its own (§10.6 item 1). Original text follows.

`MediaQuery.disableAnimations` (or any equivalent reduced-motion check) is
not referenced anywhere in `lib/`. The skill's guidance is explicit that
motion should not be optional for accessibility: any non-essential motion
should have a static/fast fallback when the platform's reduce-motion setting
is on.

Concrete exposure, ranked by how disruptive the motion would be for a user
who has reduce-motion enabled:
1. `splash_screen.dart`'s `.animate().fade(...).scale(...)` intro — cosmetic
   only, safe to skip entirely under reduced motion, currently doesn't.
2. `main_navigation_shell.dart`'s tab-switch fade+scale transition — runs on
   every tab change throughout the app's primary navigation; currently
   ignores the setting.
3. `bottom_nav.dart`/`provider_bottom_nav.dart` icon-swap `ScaleTransition`
   and pill-slide `AnimatedContainer` — same, runs constantly during normal
   use.

None of these are essential-information animations (nothing here
communicates state changes that would be lost if instant) — they're all
purely decorative transitions, which is exactly the category the skill says
must respect `disableAnimations`.

### 2.5 Auto-advancing carousels — lifecycle is correct, but no pause-on-reduced-motion

`featured_services_carousel.dart` (`Timer.periodic(const Duration(seconds:
4), …)`) correctly disposes its `Timer` and `PageController` — no leak, no
defect. (**Corrected per §9.2 item 5:** `banner_slider.dart` was listed here
as a second auto-advancing carousel. It has no `Timer`, does not
auto-advance, and `BannerSlider` is not referenced anywhere in `lib/` — it is
dead code. Any reduced-motion or carousel work below applies to
`featured_services_carousel.dart` only.) Worth
noting for completeness since auto-scrolling carousels are a common source
of `setState`-after-dispose bugs, and this codebase doesn't have that
problem here.

**Gap**: an auto-advancing carousel is itself a candidate for
reduced-motion consideration — some accessibility guidance recommends
pausing auto-rotation entirely (not just speeding it up) when the user has
requested reduced motion, since unexpected/continuous motion is often the
specific thing such settings are meant to prevent. Not implemented either
way currently.

### 2.6 `TweenAnimationBuilder` usage in `home_screen.dart` — **resolved, no defect**

> **Closed.** §5 inspected `home_screen.dart:608-618` and confirmed the static
> `Material` subtree is passed via the `child` parameter, not rebuilt inside
> `builder`. Re-confirmed in §9.1. The only open item on this widget is that
> it is not reduced-motion gated (§9.3 item 8). Original text follows.


Only one `TweenAnimationBuilder` exists in the app. Not inspected line-by-line
in this pass (read-only, keyword-sweep audit) — flagged here so a future
pass verifies it isn't rebuilding a wide subtree per tick (a common
`TweenAnimationBuilder` pitfall is putting expensive children directly in
`builder` instead of using the `child` parameter for the static part of the
tree).

## 3. Priority findings (highest impact first) — **SUPERSEDED by §10.1**

> This was the first of four successive priority lists (§3 → §5's verdict →
> §6 → §7.2). **§10.1 is the current one; read that instead.** Item 1 is now
> mostly done (§8.2), item 2 is rejected (§8.5), item 3 is unchanged, item 4
> is still deferred. Retained for traceability.

1. **No reduced-motion support anywhere** (§2.4) — the single highest-value
   fix relative to effort: wrap the app's ~3 existing decorative animations
   (splash intro, tab-switch transition, bottom-nav icon swap) with a
   `MediaQuery.disableAnimations` check and a static fallback. Small,
   contained, and closes an actual accessibility gap rather than adding new
   surface area.
2. **No `Hero` transitions despite clear shared-element candidates** (§2.3)
   — highest perceived-polish-per-effort win; the route/navigation structure
   already supports it with no conflicting custom transitions to work
   around.
3. **Async state swaps (loading/error/content) don't cross-fade** (§2.2) —
   affects nearly every `*Provider`-backed screen; wrapping the existing
   `if/else` conditional content in `AnimatedSwitcher` (already a pattern
   used elsewhere in the app, e.g. `main_navigation_shell.dart`) would be
   low-risk since it's applying an existing in-repo convention more broadly,
   not introducing a new one.
4. **No entrance/reveal motion for list/grid content** (§2.2) — lowest
   priority of the four; nice-to-have staggered-reveal polish, but the app
   functions fully without it and it's the one item here that would
   introduce genuinely new animation infrastructure (first
   `AnimationController`/staggered pattern in the codebase per §2.1).

## 4. Suggested action plan (not implemented here) — **SUPERSEDED by §10.1**

1. **Reduced-motion helper** (§2.4, ~2–4 hrs): add a small helper — e.g.
   `bool reducedMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;`
   — to `lib/utils/motion.dart` (natural home given its existing role as the
   motion-constants file), then gate the splash intro
   (`splash_screen.dart:77`), the `main_navigation_shell.dart` tab
   transition (`main_navigation_shell.dart:41-45`), and the two bottom-nav
   widgets' icon-swap/pill animations on it — falling back to an instant
   `Duration.zero`-equivalent swap when true.
2. **`Hero` on card → detail navigations** (§2.3, ~1–2 days across 3 flows):
   start with one flow end-to-end as a template (e.g. service card in
   `home_screen.dart`'s `MainCategoryCard` → `subcategories_screen.dart`),
   verify tag uniqueness and matching subtree shape per
   `references/hero.md`, then replicate the pattern for the
   jobs-list-to-`booking_detail_screen.dart` and
   requests-list-to-`request_detail_screen.dart` flows.
3. **`AnimatedSwitcher` around loading/error/content conditionals** (§2.2,
   ~0.5 day per screen, apply opportunistically): since this is an existing
   in-repo pattern already, roll it into the screen-splitting work already
   planned in `docs/architecture-audit.md` §4 Phase 3 rather than as a
   standalone sweep — those screens are being touched anyway.
4. **Evaluate staggered list/grid entrance animation** (§2.2, lowest
   priority): only pursue if product/design explicitly wants it; this is the
   one item that introduces the app's first `AnimationController`/staggered-
   timing pattern (per `references/staggered.md`), so it's worth a design
   decision rather than an opportunistic addition.
5. **Spot-check `TweenAnimationBuilder` in `home_screen.dart`** (§2.6,
   ~15 min): confirm the `child` parameter is used for any static subtree
   rather than rebuilding everything inside `builder` on each tick.
6. **Decide on auto-carousel reduced-motion behavior** (§2.5, ~1 hr once
   the Phase 1 helper from item 1 exists): pause `Timer.periodic` entirely
   in `featured_services_carousel.dart` when reduced motion is on, rather
   than just leaving the `PageController` transition duration unchanged.

No changes have been made to the app as part of this audit.

---

## 5. Code-review pass (`/review-animations`)

Added 2026-09-03. This section applies a craft-level code review (Emil
Kowalski-derived motion standards — justified motion, responsive easing,
sub-300ms UI, correct origin/physicality, interruptibility, asymmetric
timing, cohesion) to the actual implicit-animation code identified in §2,
rather than re-surveying usage counts. CSS-specific standards (e.g. "GPU-only
properties" meaning `transform`/`opacity` vs. layout properties) are
translated to their Flutter equivalents where the concept still applies, and
skipped where the CSS/browser compositor model doesn't map (Flutter's
`AnimatedContainer` repainting a `BoxDecoration` is a different cost model
than animating `width`/`margin` in a browser). No code was changed.

### Part 1 — Findings table

| Before | After | Why |
| --- | --- | --- |
| `bottom_nav.dart:158` / `provider_bottom_nav.dart:139`: `AnimatedSwitcher(transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child))` | `ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(anim), child: FadeTransition(opacity: anim, child: child))` | `AnimatedSwitcher`'s built-in animation runs 0.0→1.0, so the incoming nav icon literally scales from `0` — the exact "nothing appears from nothing" anti-pattern (Standard 5). Combine with a fade and a `0.9` floor instead of a bare scale from zero. |
| `terms_and_conditions_section.dart:92-95`: `AnimatedCrossFade(..., sizeCurve: kStandardCurve)` (no `firstCurve`/`secondCurve`) | `AnimatedCrossFade(..., firstCurve: kStandardCurve, secondCurve: kStandardCurve, sizeCurve: kStandardCurve)` | `AnimatedCrossFade.firstCurve`/`secondCurve` default to `Curves.linear` when omitted, so the actual cross-fade opacity is linear even though every other animation in the app standardizes on `kStandardCurve` (`easeOut`) via `motion.dart`. Linear easing reads as mechanical next to the rest of the app's motion. |
| `status_filter_tabs.dart:41-46`: `AnimatedPositioned(duration: kSlowAnimDuration /* 320ms */, curve: kEmphasizedCurve, ...)` for the segmented-tab indicator | `AnimatedPositioned(duration: kMediumAnimDuration /* 260ms */, curve: kEmphasizedCurve, ...)` | Segmented filter tabs (Active/Completed/Cancelled) are a frequently-tapped control on list screens — a 320ms slide is over the sub-300ms UI budget (Standard 4) for something this routine; `kMediumAnimDuration` (260ms) is already used for comparable-frequency chrome elsewhere (e.g. the bottom-nav pill) and would be more consistent. |
| `bottom_nav.dart:139-155` / `provider_bottom_nav.dart` equivalent: `AnimatedContainer(duration: kMediumAnimDuration, ...)` runs on every tab tap, every app session, many times/day | Consider `kQuickAnimDuration` (180ms) or no motion on the pill/glow itself, keeping the icon swap as the only feedback | Per Standard 2 (frequency-appropriate motion), bottom-nav taps are among the highest-frequency interactions in the app (every screen change). 260ms is within the sub-300ms budget but is the same duration used for far rarer state changes (e.g. gender-selector taps in `auth_card_scaffold.dart`); a near-daily-hundreds-of-times element is a candidate for the fastest tier available, not the middle one. |

### Part 2 — Verdict

**1. Feel-breaking regressions**

- `bottom_nav.dart:158` and `provider_bottom_nav.dart:139` — the nav-icon
  `ScaleTransition` inside `AnimatedSwitcher` animates the incoming icon in
  from `scale(0)` on every single tab switch, one of the highest-frequency
  interactions in the app. This is the one finding in this pass that rises
  to "block" severity: it's small in isolation but runs constantly, and the
  "pop from nothing" motion is precisely what Standard 5 exists to catch.
  Contrast with `main_navigation_shell.dart:43-46`, which gets this right
  (`Tween<double>(begin: 0.96, end: 1.0)`) for the tab-body swap — the fix is
  to bring the bottom-nav icon transition in line with the pattern the app
  already uses correctly one file over.

**2. Missed simplifications**

- None found. Unlike the frequency concern below, no existing animation here
  should be deleted outright — each one (pill highlight, icon swap, label
  weight change, indicator slide, accordion expand, splash intro) is
  justified per Standard 1 (spatial consistency or state feedback), matching
  the positive assessment already in §2.2.

**3. Performance**

- No dropped-frame risks or unbounded-property animations (`AnimatedContainer`
  fields are all explicit — `padding`, `decoration`, no `transition: all`
  equivalent). `TweenAnimationBuilder` in `home_screen.dart:608-618` correctly
  passes the static `Material` subtree via the `child` parameter rather than
  rebuilding it inside `builder` on every tick — confirms the concern raised
  in §2.6 was not an issue on inspection.
- Minor, non-blocking: `bottom_nav.dart`'s `AnimatedContainer` animates a
  `BoxDecoration` with a `boxShadow` (blur + spread) on every tab selection
  change, which repaints rather than just re-compositing. At single-element,
  once-per-tap scale this is not a measurable concern on modern devices, but
  it's the one case in the app where an implicit animation is doing more
  than a cheap opacity/transform-equivalent change — worth remembering if
  this pattern gets copied elsewhere at higher frequency.

**4. Interruptibility & timing**

- All motion here is implicit-widget-driven (`AnimatedContainer`,
  `AnimatedSwitcher`, `AnimatedPositioned`, `AnimatedCrossFade`,
  `AnimatedDefaultTextStyle`, `AnimatedRotation`), which retargets from
  current value by construction — rapid re-taps (e.g. fast-tapping between
  bottom-nav tabs or filter-tab segments) are handled correctly with no
  restart-from-zero keyframe risk. No interruptibility defects found.
- `status_filter_tabs.dart` duration (320ms, flagged in Part 1) is the only
  timing issue found — see table above.
- No asymmetric-timing violations found: none of the app's animations model
  a deliberate press-and-hold or destructive-confirm interaction (per
  Standard 9) that would call for asymmetric enter/exit — the accordion
  expand/collapse in `terms_and_conditions_section.dart` is a toggle, not a
  deliberate/destructive action, so symmetric 180ms both ways is appropriate
  there.

**5. Origin, physicality & cohesion**

- `status_filter_tabs.dart`'s sliding indicator (`AnimatedPositioned`) and
  `bottom_nav.dart`'s pill highlight are both correctly anchored/origin-aware
  — they move within their own track rather than fading in from a fixed
  point, which is the right physical model for a segmented control (distinct
  from the popover/dropdown "scale from trigger" case in Standard 5, but the
  same underlying principle of motion matching where the eye already is).
- `main_navigation_shell.dart`'s combined fade+scale-from-0.96 for tab-body
  swaps is a good, cohesive pattern — flagged in Part 1 as the pattern the
  bottom-nav icon transition should be brought in line with.
- No jarring-crossfade-where-blur-belongs cases found — the app's crossfades
  are all small UI elements (icons, accordion content), not full-screen
  content swaps where a blur bridge would matter.

**6. Accessibility**

- No new findings beyond §2.4 (already documented: zero
  `MediaQuery.disableAnimations` handling anywhere). This pass did not find
  any *additional* motion that would need reduced-motion gating beyond what
  §2.4 already lists — the implicit animations reviewed here (nav pill,
  icon swap, filter-tab slide, accordion, splash) are exactly the set
  already called out as needing a reduced-motion fallback.

**Decision: Block** (on one finding) — the `scale(0)` nav-icon transition in
`bottom_nav.dart:158` / `provider_bottom_nav.dart:139` is a feel-breaking
regression on a high-frequency interaction and should be fixed before this
motion is considered production-quality; it has an easy, in-repo-precedented
fix (match `main_navigation_shell.dart`'s existing `0.96→1.0` pattern). The
`AnimatedCrossFade` linear-curve gap and the `status_filter_tabs.dart`
320ms duration are non-blocking polish items. Everything else reviewed —
frequency-appropriateness of the accordion/splash/pill motion, curve choice
(`easeOut`/`easeOutCubic` throughout, no `ease-in` found), interruptibility,
and cohesion — passes.

> **Two corrections to this verdict, from §9.2 item 4.**
> 1. **"No `ease-in` found" is retracted.** `featured_services_carousel.dart:31`
>    auto-advances with `curve: Curves.easeInOut` — ease-in across its first
>    half, on a continuously-running animation. Under Standard 3 that is a
>    finding, not a pass.
> 2. **This review never opened `featured_services_carousel.dart`.** Besides
>    the curve above, its auto-advance runs 400ms (over the sub-300ms budget
>    applied to `status_filter_tabs.dart` in Part 1 row 3) and its dot
>    indicator (`:127`) runs `kSlowAnimDuration` (320ms) — the identical
>    over-budget finding, missed. Both are hardcoded or token-mismatched.
>    Carried into §10.1 item 2.
>
> The **Block** decision itself stands and was discharged in §8.1. The
> largest surface this review did *not* cover is the four `OpenContainer`
> transitions (§9.2 item 1) — queued as §10.1 item 1.

---

## 6. Roadmap-level survey (`/improve-animations`)

Added 2026-09-03. This section takes a senior-motion-advisor pass focused on
**leverage** — where adding or fixing motion would most improve how the app
feels — rather than re-auditing what §2 and §5 already covered (implicit-
animation inventory, the `scale(0)` bug, curve/duration nits, reduced-motion
gap). Per this skill's read-only contract, no code was changed and no
`plans/` directory was created; findings are presented here as the
deliverable, consistent with how the earlier audits in this file were
requested. If the team wants execution-ready specs for any item below, that
would be the next step (`/improve-animations plan <item>`).

**Recon recap** (for context, not repeated in full — see §1): Provider
`ChangeNotifier` state management, `flutter_animate` + implicit widgets only,
`lib/utils/motion.dart` as the single source of duration/curve tokens
(`kQuickAnimDuration` 180ms, `kMediumAnimDuration` 260ms, `kSlowAnimDuration`
320ms, `kStandardCurve` = `easeOut`, `kEmphasizedCurve` = `easeOutCubic`).
App personality: professional consumer services marketplace (bookings,
providers, payments) — polish should read as *trustworthy and responsive*,
not playful/bouncy; this shapes the severity and tone of every item below.

### Vetted corrective findings (new, not already in §2/§5)

| # | Severity | Category | Location | Finding | Fix summary |
| --- | --- | --- | --- | --- | --- |
| 1 | MEDIUM | Cohesion / missed feedback | `lib/widgets/provider/status_chip.dart` used from `jobs_tab.dart:246` and `rejected_requests_screen.dart:171` | `StatusChip` is a plain `Container` with no transition. It's rendered inside list items refreshed via `RefreshIndicator` (`jobs_tab.dart`, `requests_tab.dart`) — when a pull-to-refresh brings back an updated booking status, the chip's color/label swap happens instantly mid-list, easy to miss entirely since nothing draws the eye to the change. | Wrap the chip's `Text`+color in an `AnimatedSwitcher` (`kQuickAnimDuration`, `kStandardCurve`, matching the app's existing icon-swap convention) keyed on `label`, so a status change gets a brief, legible cross-fade instead of a silent pop. |
| 2 | LOW | Missed feedback | `lib/widgets/provider/dashboard_stat_card.dart` (earnings/wallet stat values), consumed from `provider_home_tab.dart` and `wallet_tab.dart` | Stat values (`Text(value)`) render as plain static text. When a provider's wallet balance or job count changes after a refresh (e.g. a job payment lands), the new number just appears — no acknowledgment that "this changed since you last looked," which is exactly the kind of state-change feedback Standard 1 calls out as justified motion (not decoration). | Not a `scale(0)`-severity bug — listed here because it's corroborated by looking at the actual widget, not speculative — but treated as LOW since dashboards in this app's "crisp, trustworthy" personality shouldn't over-animate numbers. See missed-opportunity #1 below for the recommended, restrained treatment. |

Only two items qualified as vetted *corrective* findings on this pass — the
implicit-animation code itself (already reviewed in §5) is solid, and most
of the remaining gap in this codebase is absence of motion rather than
wrong motion. That absence is the more valuable thing to catalog, below.

### Missed opportunities (additive — nothing to fix, something to add)

1. **`StatusProgressBar` (`lib/widgets/status_progress_bar.dart`) never
   animates step transitions.** This widget renders a request/booking's
   progress (Requested → Assigned → In Progress → Completed) as a static
   `Row` built fresh via `List.generate` on every rebuild — when
   `currentStep` advances (a real status change pushed from the backend,
   surfaced through `CustomerServiceRequestProvider`/`ProviderBookingsProvider`
   per `docs/architecture-audit.md`), the filled/unfilled step indicator and
   connecting line just redraw in their new state with no transition. This is
   the single highest-leverage opportunity in the app: it's a *rare* event
   (a booking doesn't change status often), it's *emotionally significant*
   to the user (their service request is moving forward), and it currently
   gets zero acknowledgment — the exact profile Standard 1 ("rare/first-time
   can have delight") describes as motion's best use case. Recommend: an
   `AnimatedContainer`/`TweenAnimationBuilder`-driven fill animation on the
   connecting line between steps (~400-500ms, `kEmphasizedCurve` is already
   the "confident, weighted" curve token in this app's system — appropriate
   for a meaningful milestone), used on both `request_detail_screen.dart`
   and `booking_detail_screen.dart` where this widget appears full-size
   (not the `compact` variant used in list rows, where motion would be
   redundant with item #1's chip fix).
2. **No success confirmation motion after a service request is created.**
   Per `docs/architecture-audit.md`, `CustomerServiceRequestProvider.createRequest()`
   (`lib/providers/customer_service_request_provider.dart:66-108`) is the
   customer's primary conversion action in the app. Not inspected line-by-line
   in this pass whether `service_request_form_screen.dart` shows a SnackBar,
   navigates away, or both on success — flagged here because a first-time or
   infrequent, high-stakes action ("I just booked a service provider") is
   exactly the case where a brief, deliberate confirmation (e.g. a checkmark
   scale-in, distinct from the routine `SnackBar` used for lower-stakes
   confirmations elsewhere) would pay off, per Standard 9's "deliberate
   actions animate slower/more noticeably than system responses." Worth a
   quick look at that screen before scoping a plan.
3. **Wallet balance / earnings numbers change silently** (see vetted finding
   #2 above). If pursued, keep it restrained given the app's "crisp,
   trustworthy" personality — a subtle `TweenAnimationBuilder`-driven count-up
   (numeric interpolation, ~400ms, `kStandardCurve`) reads as polished
   confidence; anything bouncier would clash with the rest of the app's
   motion language (no spring/physics-based motion exists anywhere else in
   the codebase, so introducing one here would be a cohesion outlier — stick
   to a tween).
4. **List/grid content has no entrance stagger** — already flagged as the
   lowest-priority item in §3/§4 of this document; re-confirmed here as
   still the right call to defer. Restated only to note it was
   re-considered in this pass and the original prioritization stands: it's
   the one item that would introduce genuinely new animation infrastructure
   (first staggered/controller-driven pattern in the app), so it should
   remain a deliberate product decision rather than an opportunistic add.

### How this changes the priority order from §3

Folding this pass into the existing §3 priority list, the `StatusProgressBar`
fill animation (missed opportunity #1) should slot in at **priority 2**,
alongside/just after the existing `Hero` transitions recommendation —
both are "add motion where none exists today" items with similarly high
perceived-polish-per-effort, and the progress bar in particular touches the
app's core value proposition (tracking a booking) more directly than the
card→detail `Hero` transitions do. The `StatusChip` cross-fade (vetted
finding #1) is small enough to bundle into the same PR as whichever screen
work touches `jobs_tab.dart`/`requests_tab.dart` next, rather than
scheduling separately.

No changes have been made to the app as part of this audit.

---

## 7. Full compile — contradiction check, and the final action plan

Added 2026-09-03. This section re-reads §1–§6 end to end, corrects what
didn't hold up, and replaces the three partial/overlapping priority lists
(§3, §5's verdict, §6's "how this changes the priority order") with one
reconciled, numbered plan. Nothing below required new code inspection beyond
what §1–§6 already established — this is a compilation pass, not a new
audit. No code was changed.

### 7.1 Contradictions and errors found

1. **Miscount, corrected**: §1's headline table originally read "11
   occurrences across 7 files" for implicit animated widgets. Re-adding the
   per-file grep results cited in §2.2 (`bottom_nav.dart` ×3,
   `provider_bottom_nav.dart` ×3, `status_filter_tabs.dart` ×2,
   `auth_card_scaffold.dart` ×1, `featured_services_carousel.dart` ×1,
   `main_navigation_shell.dart` ×1, `terms_and_conditions_section.dart` ×1)
   totals **12**, not 11. The file-count (7) was already correct — only the
   occurrence count was wrong. Fixed in §1 above. This doesn't change any
   downstream finding; nothing in §2–§6 depended on the exact number 11.

   > **This correction was itself wrong (§9.2 item 2).** It re-added §2.2's
   > per-file list without noticing that list omits `AnimatedRotation` at
   > `terms_and_conditions_section.dart:51`. The true figure at the time of
   > writing was **13 across 8 files**; today, with §8.3's `StatusChip`
   > `AnimatedSwitcher`, it is **14 across 8 files**. §1 now reads 14.

2. **Three unreconciled priority lists — not contradictory in content, but
   never merged.** §3 (written first) ranks 4 items purely from the initial
   inventory pass. §5's verdict separately declares one finding
   (`bottom_nav.dart:158`/`provider_bottom_nav.dart:139` scale-from-zero) a
   **Block**, using a severity vocabulary (Block/feel-breaking) that outranks
   everything in §3 — but §5 never re-numbers §3's list to insert itself. §6
   then proposes its own partial reshuffle ("slot in at priority 2") without
   folding in §5's Block finding, or §6's own two vetted findings
   (`StatusChip`, `DashboardStatCard`), or the two other §5 polish items
   (`AnimatedCrossFade` curve, `status_filter_tabs.dart` duration). Reading
   §3, §5, and §6 independently, each is internally consistent — but a reader
   going straight to "what do I do first" has to manually cross-reference
   three sections. §7.2 below is the single merged answer.

3. **Ranking-order ambiguity in §2.4 (minor, not fixed — flagged for
   awareness).** §2.4's numbered list is captioned "ranked by how disruptive
   the motion would be," but items 2 and 3 (`main_navigation_shell.dart`'s
   tab transition and the bottom-nav icon/pill animations) are both
   described with near-identical language ("runs constantly during normal
   use" / "same, runs constantly") — the list doesn't actually establish
   which of the two is more disruptive, it just lists them in file-discovery
   order after the splash screen. Not acted on below since both end up in
   the same fix (item 1 in §7.2) regardless of their relative order.

4. **Scope gap, not a contradiction: reduced-motion coverage was scoped
   before §5/§6 existed.** §2.4's "~3 existing decorative animations" and
   §4 item 1's fix list (splash, tab-switch, bottom-nav) predate the §5
   code-review pass and the §6 roadmap pass. Neither retroactively asks
   whether the *fixed* version of the scale-from-zero bug, or any *newly
   added* motion from §6 (StatusChip cross-fade, StatusProgressBar fill,
   DashboardStatCard count-up), should also respect the reduced-motion
   helper once it exists. They should — captured explicitly in §7.2 item 1
   below rather than left implicit.

5. **Everything else holds up.** The `AnimationController`/`Hero` counts (0
   and 0), the route-transition claim (confirmed against
   `lib/main.dart:86-109`), the carousel dispose-correctness claim, the
   `TweenAnimationBuilder` child-caching claim (confirmed on inspection in
   §5), and the curve/duration token values (`kQuickAnimDuration` 180ms,
   `kMediumAnimDuration` 260ms, `kSlowAnimDuration` 320ms,
   `kStandardCurve`=`easeOut`, `kEmphasizedCurve`=`easeOutCubic`) are
   consistent every place they're cited across §2, §5, and §6 — no other
   numeric or factual drift found.

### 7.2 ~~Final~~ reconciled action plan — **SUPERSEDED by §10.1**

> Items 1, 2 (partially) and 5 (3 of 5) were implemented in §8; item 4 was
> rejected in §8.5; and §9 found work this plan never knew existed. **§10.1
> is the current plan.** Retained below for traceability.

One list, superseding §3, §5's implicit ordering, and §6's partial reshuffle.
Ordered by leverage (feel-breaking fixes first, then highest perceived-polish-
per-effort additions, then lower-priority polish). Each item states its
source section so it can still be traced back to the original finding.

**1. Fix the scale-from-zero nav-icon transition — do this first.**
(Source: §5 Part 1 row 1, Part 2 tier 1 — the only Block-severity finding in
the whole audit; supersedes §3's "priority 1" since a feel-breaking bug on a
100+/day interaction outranks a missing accessibility fallback.)
- Files: `lib/widgets/bottom_nav.dart:158`, `lib/widgets/provider/provider_bottom_nav.dart:139`.
- Change: replace
  `transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child)`
  with a version that floors at 0.9 and adds a fade, matching the pattern
  already correct in `main_navigation_shell.dart:43-46`:
  `transitionBuilder: (child, anim) => ScaleTransition(scale: Tween<double>(begin: 0.9, end: 1.0).animate(anim), child: FadeTransition(opacity: anim, child: child))`.
- Effort: ~30 min including both files.
- Verify: tap through all three bottom-nav tabs (customer) and the
  provider-side equivalent; the icon should no longer visibly "pop" from
  nothing on selection.

**2. Add the reduced-motion helper, and gate every decorative animation that
exists *after* items 1, 3, and 4 below land — not before.** (Source: §2.4,
§4 item 1; scope corrected per §7.1 item 4 to include everything, not just
the original 3.)
- Add to `lib/utils/motion.dart`: `bool prefersReducedMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;`
- Gate: `splash_screen.dart:77` intro, `main_navigation_shell.dart:41-45` tab
  transition, the (now-fixed) `bottom_nav.dart`/`provider_bottom_nav.dart`
  icon transition and pill `AnimatedContainer`, and — once added —
  `StatusProgressBar`'s fill animation, the `StatusChip` cross-fade, and
  `DashboardStatCard`'s count-up (items 3–5 below). Each gate falls back to
  an instant state change (`Duration.zero`-equivalent) rather than skipping
  the state update itself.
- Why this is sequenced *after* items 1/3/4 rather than before, unlike §4's
  original ordering: gating a transition that's about to be rewritten
  (item 1) or that doesn't exist yet (items 3–4) means redoing the gate
  twice. Land the motion fixes/additions first, then sweep reduced-motion
  handling across all of them in one pass.
- Effort: ~3–5 hrs for the sweep (up from §4's original ~2–4 hrs estimate,
  since scope grew to cover items 3–5).
- Verify: enable "Reduce Motion" (iOS Settings → Accessibility) /
  "Remove animations" (Android Settings → Accessibility), relaunch, confirm
  all gated transitions become instant with no visual glitch (no
  half-animated frame stuck mid-transition).

**3. Add the `StatusProgressBar` fill animation.** (Source: §6 missed
opportunity #1 — the single highest-leverage *addition* identified across
all three passes; now explicitly priority 3, ahead of `Hero` transitions,
per §6's own reasoning that it touches the app's core value proposition more
directly.)
- File: `lib/widgets/status_progress_bar.dart`, used from
  `request_detail_screen.dart` and `booking_detail_screen.dart` (full-size
  variant only, not `compact`).
- Change: animate the connecting-line fill between steps when `currentStep`
  advances — `TweenAnimationBuilder<double>` or `AnimatedContainer` driving
  the filled-segment width/color, ~400–500ms, `kEmphasizedCurve` (already
  the app's "confident, weighted" token).
- Effort: ~1 day (new widget-internal animation logic + verification against
  real status transitions on both consuming screens).
- Verify: since this is the first `TweenAnimationBuilder`/timed-fill pattern
  in this specific widget, feel-check at real speed and in slow motion
  (`flutter run` with `timeDilation` as a local debug aid only, never
  shipped) to confirm the fill reads as deliberate, not sluggish, at 400ms
  vs. 500ms — pick one after visual comparison rather than guessing.

**4. `Hero` transitions on card → detail navigations — REJECTED, do not implement.**
(Source: §2.3, §4 item 2. **Status update, 2026-09-03: superseded — see §8.5.**
Originally proposed unchanged from §4, sequenced after item 3 per §6's
reasoning, ahead of the smaller polish items below. Left here struck through
for traceability; §8.5 is the authoritative record of the decision.)
- ~~Start with one flow as a template: service card in `home_screen.dart`'s
  `MainCategoryCard` → `subcategories_screen.dart`. Verify tag uniqueness
  and matching source/destination subtree shape.~~
- ~~Replicate for jobs-list → `booking_detail_screen.dart` and
  requests-list → `request_detail_screen.dart`.~~
- ~~Effort: ~1–2 days across all three flows.~~
- ~~Verify: navigate each flow forward and back; confirm no tag collisions
  (Flutter throws at runtime if two `Hero`s with the same tag are
  simultaneously in the tree — check list screens don't accidentally reuse
  one tag across multiple cards).~~

**5. Bundle the remaining small polish items into whichever PR touches their
file next, rather than scheduling standalone work:**
- `terms_and_conditions_section.dart:92-95` — add `firstCurve:
  kStandardCurve, secondCurve: kStandardCurve` to the `AnimatedCrossFade`
  so the fade isn't linear while `sizeCurve` is eased. (Source: §5 Part 1
  row 2.) ~5 min.
- `status_filter_tabs.dart:41-46` — change `AnimatedPositioned`'s
  `duration` from `kSlowAnimDuration` (320ms) to `kMediumAnimDuration`
  (260ms) to bring a frequently-tapped control under the sub-300ms budget.
  (Source: §5 Part 1 row 3.) ~5 min.
- `lib/widgets/provider/status_chip.dart` — wrap in an `AnimatedSwitcher`
  keyed on `label` (`kQuickAnimDuration`, `kStandardCurve`) so a
  pull-to-refresh status change cross-fades instead of popping. (Source: §6
  vetted finding #1.) ~30 min, land alongside item 4's
  `booking_detail_screen.dart`/`requests_tab.dart` work since both touch the
  same screens.
- Async loading/error/content conditionals — wrap in `AnimatedSwitcher`
  per-screen, opportunistically, as those screens get touched by the
  screen-splitting work in `docs/architecture-audit.md` §4 Phase 3.
  (Source: §2.2, §3 item 3 — unchanged.) ~0.5 day per screen when that work
  happens, not scheduled separately.
- `bottom_nav.dart`'s pill `AnimatedContainer` duration — reconsider
  `kQuickAnimDuration` instead of `kMediumAnimDuration` given tap
  frequency. (Source: §5 Part 1 row 4 — this one is a "consider," not a
  confirmed fix; make the call during item 1's edit to the same file rather
  than as a separate pass.) ~5 min if pursued.

**6. Defer, pending an explicit product/design decision (do not schedule
without one):**
- `DashboardStatCard` wallet/earnings count-up animation (§6 vetted finding
  #2 / missed opportunity #3) — restrained `TweenAnimationBuilder` numeric
  tween (~400ms, `kStandardCurve`) if pursued; low priority relative to
  items 1–5.
- Success-confirmation motion after service-request creation (§6 missed
  opportunity #2) — requires first inspecting
  `service_request_form_screen.dart`'s current success handling (not done in
  this read-only pass) before it can be scoped as a plan.
- Staggered list/grid entrance animation (§2.2, §3 item 4, §6 missed
  opportunity #4) — reconfirmed three separate times across this document as
  the lowest-priority item, since it's the one change that introduces the
  app's first `AnimationController`/staggered-timing pattern. Requires a
  deliberate decision, not an opportunistic add.
- Auto-carousel pause-on-reduced-motion (§2.5, §4 item 6) — implement once
  item 2's helper exists; low effort (~1 hr) but genuinely low priority next
  to items 1–4.
- `TweenAnimationBuilder` spot-check in `home_screen.dart:608-618` — already
  resolved; §5 confirmed on inspection that the `child` parameter is used
  correctly. No action needed (listed here only to close out §2.6's
  open item).

### 7.3 Summary table — **SUPERSEDED by §10.3**

| Priority | Item | Source | Effort | Status |
| --- | --- | --- | --- | --- |
| 1 | Fix scale-from-zero nav icon transition | §5 | ~30 min | **Done** |
| 2 | Reduced-motion helper + full gate sweep | §2.4/§4/§7.1 | ~3–5 hrs | ~~**Done**~~ → **Partially done** — 9 of 14 animations gated; corrected per §9.3 item 8 |
| 3 | `StatusProgressBar` fill animation | §6 | ~1 day | Not started — deferred, additive feature |
| 4 | `Hero` card → detail transitions (3 flows) | §2.3/§4 | ~1–2 days | **Rejected** — tried previously, looked off against the existing `OpenContainer` treatment; see §8.5. Not scheduled, do not re-propose. |
| 5 | Small polish bundle (5 items, land opportunistically) | §5/§6/§2.2 | ~1–2 hrs total | **Partially done** — see §8 for which of the 5 landed |
| 6 | Deferred pending product decision (5 items) | §2.2/§2.5/§6 | Variable | Not scheduled |

---

## 8. Implementation pass (2026-09-03)

Implements priorities 1, 2, and the quick-turnaround items from 5 above.
Priorities 3 and 4, the two remaining items in 5, and all of 6 were left out
deliberately — they're net-new/additive motion (a new fill animation, three
new `Hero` flows, async-conditional `AnimatedSwitcher` wraps tied to
not-yet-done screen-splitting work) rather than fixes to existing motion, so
they were treated as "nice to have" per the scope given for this pass.

### 8.1 Priority 1 — scale-from-zero nav icon transition (fixed)

- `lib/widgets/bottom_nav.dart` and `lib/widgets/provider/provider_bottom_nav.dart`:
  the `AnimatedSwitcher.transitionBuilder` for the nav icon swap now floors
  the scale at `0.9` and adds a fade, matching the pattern already correct in
  `main_navigation_shell.dart`:
  ```dart
  transitionBuilder: (child, anim) => ScaleTransition(
    scale: Tween<double>(begin: 0.9, end: 1.0).animate(anim),
    child: FadeTransition(opacity: anim, child: child),
  ),
  ```

### 8.2 Priority 2 — reduced-motion helper + gate sweep (implemented for existing motion)

- Added `bool prefersReducedMotion(BuildContext context)` to `lib/utils/motion.dart`.
- Gated with an instant (`Duration.zero`) fallback:
  - `lib/screens/splash_screen.dart` — the `.animate().fade().scale()` intro
    is skipped entirely (renders the static content directly) when reduced
    motion is on, rather than just zeroing its duration, since
    `flutter_animate`'s `.animate()` chain doesn't take a duration override
    at the call site used here.
  - `lib/widgets/main_navigation_shell.dart` — tab-switch `AnimatedSwitcher`.
  - `lib/widgets/bottom_nav.dart` / `lib/widgets/provider/provider_bottom_nav.dart` —
    both the pill `AnimatedContainer` and the (now-fixed) icon `AnimatedSwitcher`,
    plus the label `AnimatedDefaultTextStyle`.
  - `lib/widgets/provider/status_chip.dart` — new `AnimatedSwitcher` added in
    this same pass (§8.3) is gated from the start.
- **Not gated, and not claimed as done:** `status_filter_tabs.dart`'s
  indicator slide/label cross-fade and `terms_and_conditions_section.dart`'s
  accordion — the original plan (§7.2 item 2) only called for gating
  decorative, non-essential motion; these two communicate the current
  selection/expansion state, arguably borderline, and gating them wasn't
  explicitly re-confirmed in this pass. Flagged for a follow-up decision
  rather than gated speculatively.
- `StatusProgressBar` and any future `Hero`/count-up motion (§7.2 item 2's
  "once added" clause) don't exist yet — nothing to gate.

### 8.3 Priority 5 — small polish bundle (3 of 5 landed)

Landed:
- `lib/widgets/terms_and_conditions_section.dart:94` — added
  `firstCurve: kStandardCurve, secondCurve: kStandardCurve` to the
  `AnimatedCrossFade` so the fade isn't linear while `sizeCurve` is eased.
- `lib/widgets/status_filter_tabs.dart:42` — indicator slide duration changed
  from `kSlowAnimDuration` (320ms) to `kMediumAnimDuration` (260ms).
- `lib/widgets/provider/status_chip.dart` — wrapped the chip in an
  `AnimatedSwitcher` keyed on `label` (`kQuickAnimDuration`, `kStandardCurve`),
  so a pull-to-refresh status change cross-fades instead of popping. Applies
  automatically everywhere `StatusChip` is used (`jobs_tab.dart`,
  `rejected_requests_screen.dart`).

Not landed (left as-is, per this pass's "leave out nice-to-have/low-severity"
scope):
- `bottom_nav.dart`'s pill `AnimatedContainer` duration reconsideration
  (`kMediumAnimDuration` → `kQuickAnimDuration`) — the audit itself hedges
  this as a "consider," not a confirmed fix.
- Async loading/error/content `AnimatedSwitcher` wraps — explicitly tied to
  the screen-splitting work in `docs/architecture-audit.md` §4 Phase 3, which
  hasn't happened yet; wrapping now would be premature/unscoped.

### 8.4 Verification

`flutter analyze lib` run after all changes: same 13 pre-existing `info`-level
lints as the pre-implementation baseline (all unrelated `prefer_const_constructors`
/ `use_super_parameters`), zero new errors or warnings. Not yet verified on a
running emulator/device with the platform reduce-motion setting toggled on —
that manual check (per §7.2 item 2's original verify step) is still
outstanding.

No items from priority 3, 4, or 6 were implemented in this pass.

### 8.5 Priority 4 (`Hero` card → detail transitions) — rejected, not a deferral

Corrected 2026-09-03. §7.2 item 4 and §7.3's summary table both listed the
`Hero` card→detail transitions as "not started" / additive-and-deferred, as
if it were simply unscheduled. That's inaccurate: this was tried earlier and
explicitly rejected on product/feel grounds, not left undone for lack of
time.

**Decision: `Hero` transitions on card → detail navigations will not be
implemented.** The team already prototyped this on these flows before this
audit existed; the shared-element flight looked off in practice (the
existing `OpenContainer` container-transform already used on these same
card→detail flows — see `lib/utils/motion.dart` and the four `OpenContainer`
sites in `main_category_card.dart`, `jobs_tab.dart`,
`rejected_requests_screen.dart`, `service_requests_screen.dart` — competes
with a `Hero` flight rather than complementing it, producing a worse result
than either technique alone). This was a call already made prior to §2.3/§4/
§7.2 item 4 being written; those sections re-proposed it without that
context. Do not re-propose `Hero` transitions on these flows again without
new information — the existing `OpenContainer` treatment is the intended,
final motion for card → detail navigation on this app.

No changes have been made to the app as part of this audit.

---

## 9. Verification pass — this document checked against the code (2026-09-03)

Added 2026-09-03. Every factual claim in §1–§8 was re-checked against the
working tree, and the code shipped in §8 was reviewed for correctness. No
code was changed in this pass. Two things came out of it: the §8
implementation claims are accurate, and §1–§5 rest on a materially wrong
premise about this app's route-transition motion.

### 9.1 What verified clean

- **Every §8.1/§8.2/§8.3 implementation claim is true as written.** Confirmed
  in the working tree: the `0.9`-floored + faded nav-icon `transitionBuilder`
  (`bottom_nav.dart:159-162`, `provider_bottom_nav.dart:140-143`);
  `prefersReducedMotion` in `motion.dart:20`; reduced-motion gating on the
  splash intro (`splash_screen.dart:79-81`), the tab-switch `AnimatedSwitcher`
  (`main_navigation_shell.dart:37`), both nav bars' pill/icon/label
  animations, and `status_chip.dart:14`; the `AnimatedCrossFade`
  `firstCurve`/`secondCurve` addition (`terms_and_conditions_section.dart:71-72`);
  and the `status_filter_tabs.dart:42` 320ms → 260ms change.
- **§8.4's analyzer claim is accurate.** `flutter analyze lib` re-run: 13
  `info`-level issues, all `prefer_const_constructors`/`use_super_parameters`
  in files untouched by this work. Zero errors or warnings.
- **§8.3's "not landed" list and §7.3's "partially done" status are honest** —
  the pill duration is still `kMediumAnimDuration` and no async-conditional
  `AnimatedSwitcher` wraps were added, exactly as stated.
- **§6's `StatusProgressBar` finding still holds.** `lib/widgets/status_progress_bar.dart`
  contains no `Animated*`, `Tween`, or `duration` reference at all — it is
  still fully static, as described.
- **§7.1 item 5's spot-checks hold.** `AnimationController` count is genuinely
  0; `Hero` count is genuinely 0; `home_screen.dart:608` does pass its static
  `Material` subtree via `child`; the motion tokens' values are as documented.

### 9.2 Errors found in §1–§7

**1. Critical — the app's largest motion surface was never audited.** The
`animations` package (`pubspec.yaml:25`, `animations: ^2.0.11`) provides
`OpenContainer` container transforms on four card → detail flows:
`main_category_card.dart:28`, `service_requests_screen.dart:286`,
`jobs_tab.dart:139`, `rejected_requests_screen.dart:74`. `git log -S` puts
these in the tree since commits `80ac295` / `4b47f20` — long before this
audit was written. Consequences:

  - §1's row "Custom `PageRouteBuilder` / named-route transition overrides:
    **0** — Confirmed intentional" is literally true only on the narrow
    keyword it grepped for. In substance it is wrong: this app has custom,
    non-default route transitions on its primary navigation flows.
  - §2.3's claim that these navigations "currently cut instantly from a small
    card to a full detail screen with only the default slide/fade" is
    **false** for exactly the three flows it names — all three already run a
    Material container transform.
  - §3 item 2 and §4 item 2 (`Hero` transitions, ranked "highest
    perceived-polish-per-effort") were therefore built on a false premise.
    §8.5 rejected them for precisely this reason, but §2.3/§3/§4 were never
    corrected and still read as live recommendations to a first-time reader.
  - §5's code review never evaluated `OpenContainer`'s own motion parameters
    (`transitionDuration`, `transitionType`, `closedElevation`, the
    open/close curve asymmetry). This is now the single largest un-reviewed
    motion surface in the codebase and the obvious target for the next
    review pass.
  - **Stale comment in code, not just docs**: `lib/utils/motion.dart:4-9`
    asserts route transitions "use Flutter's platform-default … with no
    custom override." That doc comment is wrong for the same reason and
    should be updated to describe the `OpenContainer` treatment as the
    intended card → detail motion (per §8.5).

**2. The implicit-widget count is still wrong after §7.1's "correction."**
Actual sweep of the current tree:

  | File | Implicit widgets |
  | --- | --- |
  | `bottom_nav.dart` | 3 |
  | `provider/provider_bottom_nav.dart` | 3 |
  | `status_filter_tabs.dart` | 2 |
  | `terms_and_conditions_section.dart` | **2** (`AnimatedRotation:51` + `AnimatedCrossFade:61`) |
  | `auth_card_scaffold.dart` | 1 |
  | `featured_services_carousel.dart` | 1 |
  | `main_navigation_shell.dart` | 1 |
  | `provider/status_chip.dart` | 1 (added in §8.3) |
  | **Total** | **14 across 8 files** |

  §2.2 lists `terms_and_conditions_section.dart` as `AnimatedCrossFade` only,
  omitting the `AnimatedRotation` chevron — so §7.1's re-tally inherited the
  same omission. The correct figure at §7.1's writing was **13 across 8
  files** (not 12 across 7); it is **14 across 8** today. §5 Part 2 tier 4
  does name `AnimatedRotation` in its list of reviewed widgets, so §2.2 and §5
  were already inconsistent with each other before §7 tried to reconcile them.

**3. §2.1 overstates the absence of explicit animation.**
`featured_services_carousel.dart:72` uses an `AnimatedBuilder` driven by the
`PageController` to parallax the card image against the swipe. The
`AnimationController` count of 0 is correct, but "there is no
explicit-animation surface area yet … the team will be establishing
convention, not following one" is not: a `Listenable`-driven `AnimatedBuilder`
with correct `child` caching already exists in the repo and is the natural
in-repo exemplar for future explicit work.

**4. §5's "no `ease-in` found" is wrong, and the carousel was never opened.**
`featured_services_carousel.dart:31` auto-advances with
`animateToPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut)`:

  - `easeInOut` is ease-in on its first half — the exact thing §5's Standard 3
    exists to catch, and §5's verdict explicitly claims "no `ease-in` found."
  - 400ms exceeds the sub-300ms budget §5 applied to `status_filter_tabs.dart`.
  - Both the duration and the curve are hardcoded, bypassing `motion.dart` —
    contradicting §2.2's claim that durations/curves "are centralized in
    `lib/utils/motion.dart` rather than scattered as magic numbers."
  - The dot indicator (`featured_services_carousel.dart:127`) uses
    `kSlowAnimDuration` (320ms) — the same over-budget finding §5 raised
    against `status_filter_tabs.dart`, missed here because §5 reviewed the
    nav/tab/accordion widgets but never opened this file.

**5. §1 and §2.5 misdescribe `banner_slider.dart`.** It has no `Timer` and
does not auto-advance — it holds a `PageController` and disposes it, nothing
more. §1's row "`Timer`-driven auto-animation with `dispose()`: **2 files**"
should read **1 file**. Separately, `BannerSlider` is not referenced anywhere
in `lib/` — it is dead code, which is worth knowing before anyone scopes
reduced-motion work against it (§4 item 6 / §7.2 item 6 implicitly include it).

**6. Line-number drift across citations.** Several `file:line` references no
longer resolve, and one was wrong even at authoring time:

  | Cited as | Actual | Where cited |
  | --- | --- | --- |
  | `terms_and_conditions_section.dart:92-95` / `:94` | `:61-74` | §5 Part 1, §7.2 item 5, §8.3 |
  | `splash_screen.dart:77` | `:79-81` | §4 item 1, §7.2 item 2 |
  | `main_navigation_shell.dart:41-45` / `:43-46` | `:36-48`, tween at `:44` | §4, §5, §7.2 |
  | `bottom_nav.dart:158` / `:139-155` | `:157` / `:140-156` | §5, §7.2 item 1 |
  | `provider_bottom_nav.dart:139` | `:138` | §5, §7.2 item 1 |

  Most of this is post-§8 drift and harmless. The
  `terms_and_conditions_section.dart` citation is a real error — that file has
  never been 92+ lines at the `AnimatedCrossFade`.

### 9.3 Correctness findings on the code shipped in §8

**7. `prefersReducedMotion` subscribes callers to the whole `MediaQuery`.**
`motion.dart:20` uses `MediaQuery.of(context)`, which registers a dependency
on every `MediaQueryData` field — so each caller rebuilds on keyboard
show/hide, window resize, padding changes, and text-scale changes, not just
on the accessibility flag. `MediaQuery.disableAnimationsOf(context)` is the
aspect-scoped accessor for exactly this case. The impact is amplified by call
placement: `bottom_nav.dart:127` and `provider_bottom_nav.dart:108` call it
inside each nav item's `build`, creating 3 and 5 separate full-`MediaQuery`
subscriptions respectively. Behaviourally correct today, needlessly wide
rebuild scope. One-line fix.

**8. §7.3's "Priority 2 — Done" overstates the gate sweep.** §8.2 names two
ungated animations; there are actually five, and the two it omits are the
more defensible ones to gate:

  - `featured_services_carousel.dart:31` auto-advance timer and `:127` dot
    indicator — **§2.5 called this out explicitly** as the strongest
    reduced-motion candidate in the app ("some accessibility guidance
    recommends pausing auto-rotation entirely … since unexpected/continuous
    motion is often the specific thing such settings are meant to prevent").
    §8.2 doesn't mention the carousel at all, and §7.2 item 6 files it under
    "defer" — so it was deferred rather than missed, but §7.3's flat "Done"
    hides that the one continuously-running animation in the app is still
    ungated.
  - `home_screen.dart:608` search-suggestion overlay `TweenAnimationBuilder`
    (fade + 8px translate) — purely decorative, triggered on every search
    keystroke that changes the match count. Not mentioned anywhere in §2–§8.
  - Plus the two §8.2 does name (`status_filter_tabs.dart`,
    `terms_and_conditions_section.dart`) and
    `auth_card_scaffold.dart:209`'s gender-selector `AnimatedContainer`,
    also unmentioned.

  Suggested status wording for §7.3 row 2: **Partially done — 9 of 14 implicit
  animations gated; carousel, search overlay, filter tabs, accordion and
  gender selector still ungated.**

**9. `motion.dart`'s doc comment now contradicts one of its own call sites.**
Lines 17-19 instruct callers to "fall back to an instant (`Duration.zero`)
state change instead of skipping the state update." `splash_screen.dart:79-81`
skips the animation entirely. That is the right call for a decorative intro
with no state to preserve (and §8.2 explains why `flutter_animate` forced it),
but the comment should be softened to allow it rather than reading as a rule
the codebase already breaks.

**10. `StatusChip`'s new `AnimatedSwitcher` will jump width on label change
(low severity, worth eyeballing).** `AnimatedSwitcher`'s default
`layoutBuilder` stacks outgoing and incoming children and sizes to the
largest, so a status change between labels of different length ("Assigned" →
"In Progress") snaps the chip to the wider width for the duration of the fade
rather than easing into it. In the list rows where the chip lives
(`jobs_tab.dart:246`, `rejected_requests_screen.dart:171`) the surrounding
`Row` will re-lay-out around that snap. Not a defect — it's the documented
default behaviour — but it's the one place §8's shipped motion could read as
slightly jumpy, and it wasn't verified on a device (§8.4 confirms no runtime
check was done). Check it against the longest and shortest real status labels
before considering item 5 fully closed.

### 9.4 Recommended corrections to this document — **all applied**

Documentation-only; none required code changes. All seven were applied to
§1–§7 in place on 2026-09-03.

| # | Action | Target | Status |
| --- | --- | --- | --- |
| 1 | Rewrite §1's route-transition row and §2.3 to describe the four `OpenContainer` sites; mark §3 item 2 / §4 item 2 as superseded by §8.5 in place | §1, §2.3, §3, §4 | Applied |
| 2 | Correct the implicit-widget count to 14 across 8 files; add `AnimatedRotation` to §2.2's per-file list | §1, §2.2, §7.1 | Applied |
| 3 | Soften §2.1's "no explicit-animation surface area" to acknowledge `featured_services_carousel.dart:72`'s `AnimatedBuilder` | §2.1 | Applied |
| 4 | Retract §5's "no `ease-in` found" verdict line; add the carousel's 400ms `easeInOut` and 320ms dot indicator as findings | §5 | Applied |
| 5 | Correct §1's Timer row to 1 file; note `BannerSlider` is unreferenced dead code | §1, §2.5 | Applied |
| 6 | Refresh the drifted `file:line` citations per the table in §9.2 item 6 | §4, §5, §7.2, §8.3 | Applied (§10.4) |
| 7 | Restate §7.3 row 2 as "Partially done" with the ungated list from §9.3 item 8 | §7.3 | Applied |

The highest-value *next* work, on this evidence, is not any item in §7.2 — it
is reviewing the `OpenContainer` transitions and the featured-services
carousel, the two motion surfaces this document has never actually looked at.
That reordering is reflected in §10.1.

No changes have been made to the app as part of this audit.

---

## 10. Current action plan (2026-09-03) — authoritative

Supersedes §3, §4, §5's verdict ordering, §6's reshuffle, and §7.2/§7.3.
Written after §8 (what shipped) and §9 (what the audit got wrong), so it is
the only list in this document that reflects both. Anything not listed here
is either done or explicitly closed in §10.2.

**What changed versus §7.2, in one paragraph.** Three of §7.2's six
priorities are resolved: item 1 (scale-from-zero) shipped, item 4 (`Hero`)
is rejected outright, and item 5 landed 3 of its 5 sub-items. Item 2
(reduced motion) is 9/14 done rather than done. And §9 surfaced two motion
surfaces the audit had never examined — the four `OpenContainer` transitions
and the featured-services carousel — which now outrank everything that was
previously queued, because they are existing, shipping, unreviewed motion
rather than hypothetical additions.

### 10.1 Open work, in order

**1. Review the four `OpenContainer` container transforms — do this first.**
(Source: §9.2 item 1. Highest priority because it is the app's most
prominent motion, it ships today, and no pass in this document has looked
at it.)
- Files: `lib/widgets/main_category_card.dart:28`,
  `lib/screens/service_requests_screen.dart:286`,
  `lib/screens/provider/jobs/jobs_tab.dart:139`,
  `lib/screens/provider/jobs/rejected_requests_screen.dart:74`.
- Review against the §5 standards that were never applied to it:
  `transitionDuration` (the `animations` default is 300ms — check each site
  hasn't overridden it upward), `transitionType` (`fade` vs.
  `fadeThrough`), `closedElevation`/`openElevation`, and whether the four
  sites are consistent with each other. Cohesion matters most here: four
  copies of the same transform that disagree on duration or elevation is
  exactly the Standard 10 failure mode.
- Also check the closed-state builder isn't rebuilding an expensive subtree
  during the flight, and that the transform still reads correctly under
  reduced motion (`OpenContainer` does **not** consult
  `MediaQuery.disableAnimations` on its own).
- Effort: ~2–3 hrs review, unknown fix cost until reviewed.
- Verify: navigate each of the four card → detail flows forward and back,
  at real speed and with the platform reduce-motion setting on.

**2. Fix the featured-services carousel's motion.** (Source: §9.2 item 4,
§9.3 item 8. Second because it is the app's only continuously-running
animation, it violates two standards §5 applied elsewhere, and it is the
strongest remaining reduced-motion gap.)
- File: `lib/widgets/featured_services_carousel.dart`.
- `:31` — `animateToPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut)`:
  replace the hardcoded values with `motion.dart` tokens and drop the
  `ease-in` half. `kSlowAnimDuration` (320ms) + `kEmphasizedCurve` is the
  closest in-system match; a page-slide is one of the few places a
  >300ms duration is defensible, unlike the tap-driven controls §5 measured.
- `:127` — dot indicator `AnimatedContainer` uses `kSlowAnimDuration`
  (320ms). This is the same over-budget finding §5 raised against
  `status_filter_tabs.dart` and it should get the same fix:
  `kMediumAnimDuration` (260ms).
- Reduced motion: pause `Timer.periodic` outright when
  `prefersReducedMotion(context)` is true — per §2.5, continuous
  unrequested motion is the archetypal case the setting exists for. Gate the
  dot indicator too.
- Effort: ~2 hrs including the reduced-motion pause.
- Verify: watch a full auto-advance cycle; confirm the slide no longer
  starts slowly, and that the carousel stops advancing entirely (not just
  faster) with reduce-motion on.

**3. Finish the reduced-motion gate sweep.** (Source: §8.2, §9.3 items 7–8.
Closes out §7.2 item 2, which §7.3 previously reported as done.)
- Fix the helper first: `lib/utils/motion.dart:20` — change
  `MediaQuery.of(context).disableAnimations` to
  `MediaQuery.disableAnimationsOf(context)` so callers depend on the one
  aspect rather than the whole `MediaQueryData`. This matters most at
  `bottom_nav.dart:127` and `provider_bottom_nav.dart:108`, which call it
  per nav item (3 and 5 subscriptions to every keyboard/resize/text-scale
  change). One line, no behaviour change.
- Then gate the five remaining animations:
  `featured_services_carousel.dart` (covered by item 2),
  `home_screen.dart:608` search-suggestion overlay,
  `status_filter_tabs.dart:42`+`:68`,
  `terms_and_conditions_section.dart:51`+`:61`,
  `auth_card_scaffold.dart:209` gender selector.
- The filter tabs and the accordion were deliberately skipped in §8.2 as
  "arguably state-communicating." Make that call explicitly rather than
  leaving it open: both communicate state that is *also* conveyed
  statically (a filled pill, an expanded panel), so gating them to
  `Duration.zero` loses nothing. Recommend gating both.
- Also soften `motion.dart:17-19`'s doc comment, which currently forbids the
  skip-entirely pattern that `splash_screen.dart:79-81` correctly uses
  (§9.3 item 9).
- Effort: ~2 hrs.
- Verify: with reduce-motion on, every transition in the app becomes
  instant with no half-animated frame. **This device check has never been
  run** — §8.4 confirms §8 was verified by analyzer only.

**4. Correct the stale doc comment in `lib/utils/motion.dart:4-9`.**
(Source: §9.2 item 1.) It asserts route transitions "use Flutter's
platform-default … with no custom override," which is false and is the
reason the original audit reached the wrong conclusion in §2.3. Replace with
a description of the `OpenContainer` container-transform treatment as the
intended card → detail motion, citing §8.5's rejection of `Hero` so the
decision survives in the code, not only in this document. ~10 min. Do it
alongside item 3, which touches the same file.

**5. Eyeball `StatusChip`'s width snap.** (Source: §9.3 item 10.)
`AnimatedSwitcher`'s default layout stacks both children and sizes to the
larger, so a status change between labels of different length snaps the
chip's width for the duration of the fade. Check against the longest and
shortest real labels in `jobs_tab.dart:246` and
`rejected_requests_screen.dart:171`; if it reads as jumpy, wrap in an
`AnimatedSize` or give the chip a `minWidth`. ~30 min. This is the last
open item on §7.2's polish bundle.

**6. `StatusProgressBar` fill animation.** (Source: §6 missed opportunity
#1; unchanged from §7.2 item 3, re-verified still un-animated in §9.1.)
Highest-value *additive* item in the app: rare, emotionally significant,
currently silent. `lib/widgets/status_progress_bar.dart`, full-size variant
only, ~400–500ms with `kEmphasizedCurve`, gated on `prefersReducedMotion`
from the start. ~1 day. Deliberately ranked below items 1–5 because those
are corrections to shipping motion, this is new surface area.

**7. Remaining polish, land opportunistically:**
- `bottom_nav.dart:140` pill `AnimatedContainer` — reconsider
  `kQuickAnimDuration` vs. `kMediumAnimDuration` given tap frequency.
  (§5 Part 1 row 4; still a "consider," not a confirmed fix.) ~5 min.
- Async loading/error/content `AnimatedSwitcher` wraps — still tied to the
  screen-splitting work in `docs/architecture-audit.md` §4 Phase 3, still
  not scheduled separately. ~0.5 day per screen when those screens are
  touched.
- Delete or wire up `lib/widgets/banner_slider.dart` — unreferenced dead
  code (§9.2 item 5). Not a motion decision, but it is why §1 miscounted the
  app's carousels. ~5 min.

### 10.2 Closed — do not re-propose

- **`Hero` card → detail transitions.** Rejected on product/feel grounds;
  the `OpenContainer` treatment is final. See §8.5. Requires new information
  to reopen.
- **Scale-from-zero nav icon.** Fixed in §8.1, verified in §9.1.
- **`AnimatedCrossFade` linear curve**, **`status_filter_tabs.dart` 320ms
  indicator**, **`StatusChip` cross-fade.** All landed in §8.3, verified in
  §9.1. (`StatusChip` has one open follow-up — §10.1 item 5.)
- **`TweenAnimationBuilder` child-caching spot-check** (§2.6). Confirmed
  correct twice.

### 10.3 Status table (replaces §7.3)

| # | Item | Source | Effort | Status |
| --- | --- | --- | --- | --- |
| — | Fix scale-from-zero nav icon transition | §5 | ~30 min | **Done** (§8.1) |
| — | `AnimatedCrossFade` curves, filter-tab duration, `StatusChip` switcher | §5/§6 | ~40 min | **Done** (§8.3) |
| — | `Hero` card → detail transitions | §2.3/§4 | — | **Rejected** (§8.5) |
| 1 | Review the four `OpenContainer` transforms | §9.2 | ~2–3 hrs + fixes | **Reviewed, no code change** — consistent across all four; one gap remains (reduced motion), see §10.5 |
| 2 | Fix carousel `easeInOut`/400ms/320ms + pause on reduced motion | §9.2/§9.3 | ~2 hrs | **Done** (§10.5) |
| 3 | Finish reduced-motion sweep (5 animations) + `disableAnimationsOf` | §8.2/§9.3 | ~2 hrs | **Done** — 14 of 14 gated (§10.5) |
| 4 | Correct `motion.dart`'s stale route-transition comment | §9.2 | ~10 min | **Done** (§10.5) |
| 5 | Eyeball `StatusChip` width snap | §9.3 | ~30 min | **Done** — fixed with `AnimatedSize` (§10.5) |
| 6 | `StatusProgressBar` fill animation | §6 | ~1 day | **Not started** — additive, now the top open item |
| 7 | Nav pill duration, async `AnimatedSwitcher` wraps, delete `BannerSlider` | §5/§2.2/§9.2 | ~1 hr + per-screen | **Opportunistic** — none landed |
| — | `DashboardStatCard` count-up, success-confirmation motion, staggered list entrance | §6/§2.2 | Variable | **Deferred** — needs a product decision |

### 10.4 Corrected `file:line` references

The citations below were drifted or wrong throughout §4–§8. Current values,
verified against the working tree on 2026-09-03:

| Subject | Correct location |
| --- | --- |
| Nav icon `AnimatedSwitcher` | `bottom_nav.dart:157-162`, `provider_bottom_nav.dart:138-143` |
| Nav pill `AnimatedContainer` | `bottom_nav.dart:140-156`, `provider_bottom_nav.dart:121-137` |
| Tab-switch transition | `main_navigation_shell.dart:36-48` (tween at `:44`) |
| Splash intro | `splash_screen.dart:79-81` |
| T&C accordion | `terms_and_conditions_section.dart:51` (rotation), `:61-74` (cross-fade) |
| Filter-tab indicator | `status_filter_tabs.dart:41-46` (label style at `:67-70`) |
| Reduced-motion helper | `motion.dart:20` |
| Search-suggestion overlay | `home_screen.dart:608` |
| Carousel auto-advance / parallax / dots | `featured_services_carousel.dart:31` / `:72` / `:127` |
| `OpenContainer` sites | `main_category_card.dart:28`, `service_requests_screen.dart:286`, `jobs_tab.dart:139`, `rejected_requests_screen.dart:74` |

### 10.5 Implementation pass 2 — checked against §10.1 (2026-09-03)

Items 1–5 of §10.1 were implemented and verified against the working tree.
Eleven files changed; `flutter analyze lib` re-run afterwards: **13
`info`-level issues, identical to the pre-change baseline, zero new errors or
warnings.**

**Item 1 — `OpenContainer` review: no code change needed, one gap left open.**
All four sites were read and compared. They are consistent on every parameter
that matters for cohesion: `closedElevation: 0`, `openElevation: 0`,
`closedColor: Color(0xFFF4F7FB)`, `transitionDuration: 380ms`, and a
`RoundedRectangleBorder` `closedShape`. `transitionType` is unset everywhere,
so all four use the package default (`ContainerTransitionType.fade`) —
consistent by omission rather than by accident, which is fine. Two deliberate
deviations at `main_category_card.dart:28` (`openColor: style.color` and a
16px radius vs. 18px elsewhere) match the category-colored treatment
introduced in commit `80ac295`; not flagged. 380ms sits above the package's
300ms default, but §5's sub-300ms budget governs *UI elements*, not route
transitions, so it is defensible as-is.

> **Open**: `OpenContainer` does not consult `MediaQuery.disableAnimations`
> on its own, so with reduce-motion enabled these four card → detail flows
> still run the full 380ms container transform — now the **only** ungated
> motion in the app. Fixing it means branching to a plain `Navigator.push`
> (or `transitionDuration: Duration.zero`) when `prefersReducedMotion` is
> true, at four call sites. Carried forward as §10.6 item 1.

**Item 2 — carousel: done.** `featured_services_carousel.dart:33` now uses
`kSlowAnimDuration` + `kEmphasizedCurve` in place of the hardcoded 400ms
`Curves.easeInOut`, removing the app's only `ease-in`. The dot indicator
(`:135`) dropped from `kSlowAnimDuration` to `kMediumAnimDuration` and is
gated. Auto-advance is suppressed under reduced motion via a `_reduceMotion`
field refreshed in `didChangeDependencies()` (`:38-41`) and checked in the
timer callback (`:31`) — correct placement, picks up a mid-session change to
the setting. *Minor note, not worth a change:* the `Timer.periodic` still
fires every 4s and returns early rather than being cancelled outright.
Behaviourally identical; only a sleeping-device nicety.

**Item 3 — reduced-motion sweep: done, now 14 of 14.** The helper at
`motion.dart:26` switched to `MediaQuery.disableAnimationsOf(context)`, so
the per-nav-item calls no longer subscribe to the whole `MediaQueryData`.
The five remaining animations are gated: `home_screen.dart:611`
(search-suggestion overlay), `status_filter_tabs.dart:42` and `:69`,
`terms_and_conditions_section.dart:54` and `:94`, and
`auth_card_scaffold.dart:210`. Combined with §8.2, every implicit animation,
the `TweenAnimationBuilder`, and the splash intro now respect the setting —
the ungated list from §9.3 item 8 is empty. The §10.1 item 3 recommendation
to gate the filter tabs and accordion (rather than leave the call open) was
taken.

**Item 4 — `motion.dart` doc comment: done.** `motion.dart:3-15` now
describes the `OpenContainer` container transform as the intended card →
detail motion, names all four sites, and records the `Hero` rejection with a
pointer to §8.5 — so the decision now lives in the code, not only in this
document. The reduced-motion comment (`:23-25`) was also softened to permit
skipping an animation outright where there is no state to preserve, which is
what `splash_screen.dart` does (closes §9.3 item 9).

**Item 5 — `StatusChip` width snap: done.** `status_chip.dart:14-19` wraps
the `AnimatedSwitcher` in an `AnimatedSize` with
`alignment: Alignment.centerLeft`, so a status change between labels of
different length eases the chip's width instead of snapping to the wider of
the two mid-fade. Both animations share one gated `duration`. This closes the
last item from §7.2's polish bundle.

**Not attempted, as planned:** item 6 (`StatusProgressBar` fill animation)
and all of item 7 — the nav pill duration is still `kMediumAnimDuration`,
no async `AnimatedSwitcher` wraps were added, and `banner_slider.dart` is
still present and still unreferenced.

### 10.6 Remaining open work

1. **Reduced motion for the four `OpenContainer` transforms** (§10.5 item 1)
   — the only ungated motion left in the app. ~1 hr across four call sites.
2. **`StatusProgressBar` fill animation** (§6, §10.1 item 6) — ~1 day. The
   highest-value additive item, and now the largest open piece of work.
3. **Device verification of the whole reduced-motion path** — still
   outstanding, and now covering 14 gated animations rather than 9. Every
   pass so far has been verified by analyzer only; nothing in §8 or §10.5 has
   been run with the platform setting toggled on a real device or emulator.
4. **Opportunistic** (§10.1 item 7) — nav pill duration, async
   `AnimatedSwitcher` wraps (tied to `docs/architecture-audit.md` §4 Phase 3),
   delete `banner_slider.dart`.
5. **Deferred pending a product decision** — `DashboardStatCard` count-up,
   success-confirmation motion after request creation, staggered list
   entrance.

Code changes were made in the passes recorded in §8 and §10.5; this
document's own analysis remains read-only.

---

## 11. Implementation pass 2 (2026-09-03) — §10.1 items 1–5 and part of item 7

Executed against §10.1. §10.1 item 6 (`StatusProgressBar` fill animation) was
left out as additive/net-new, and the async `AnimatedSwitcher` wraps in item 7
were left out as tied to the unscheduled screen-splitting work in
`docs/architecture-audit.md` — both out of scope on the same "no nice-to-have,
no low-severity" basis as §8.

### 11.1 Item 1 — `OpenContainer` review (reviewed, no code change)

Reviewed all four sites (`main_category_card.dart:28`,
`service_requests_screen.dart:286`, `jobs_tab.dart:139`,
`rejected_requests_screen.dart:74`) against the §5 standards. Result: they are
already cohesive — `transitionDuration: 380ms`, `closedElevation: 0`,
`openElevation: 0`, and the same `closedShape` (16px/18px rounded rect) at
every site; none override `transitionType`, so all four consistently use the
package default (`ContainerTransitionType.fade`). No Standard 10 (cohesion)
violation found, so no fix was made.

One real gap surfaced and was **not** fixed: `OpenContainer` does not consult
`MediaQuery.disableAnimations`/`disableAnimationsOf` on its own, and the
`animations` package exposes no supported way to force an instant transform —
setting `transitionDuration: Duration.zero` is a known source of visual
glitches in that package (the closed/open builders can flash or fail to
cross-fade). Left ungated rather than shipping a workaround with a known
glitch risk; flagged here as an open item, not silently dropped.

### 11.2 Item 2 — carousel motion (fixed)

`lib/widgets/featured_services_carousel.dart`:
- `:32` auto-advance `animateToPage` now uses `kSlowAnimDuration` (320ms) +
  `kEmphasizedCurve` instead of a hardcoded `400ms` + `Curves.easeInOut`,
  removing the ease-in half and routing the value through `motion.dart`.
- Dot indicator `AnimatedContainer` duration dropped from `kSlowAnimDuration`
  (320ms) to `kMediumAnimDuration` (260ms), matching the fix already applied
  to `status_filter_tabs.dart` in §8.3.
- Added a `_reduceMotion` field, refreshed in `didChangeDependencies`. The
  `Timer.periodic` callback now no-ops when `_reduceMotion` is true (the
  carousel stops advancing entirely, not just faster), and the dot indicator
  duration is gated to `Duration.zero` under the same flag.

### 11.3 Item 3 — reduced-motion sweep finished

`lib/utils/motion.dart:20` — `prefersReducedMotion` now calls
`MediaQuery.disableAnimationsOf(context)` instead of
`MediaQuery.of(context).disableAnimations`, so callers subscribe to just the
one aspect instead of the whole `MediaQueryData`. No behavior change, narrows
rebuild scope — matters most at the nav bars' per-item calls.

Gated the five animations named in §9.3 item 8, all via the same
`prefersReducedMotion(context) ? Duration.zero : <token>` pattern used in §8.2:
- `home_screen.dart:611` search-suggestion overlay `TweenAnimationBuilder`.
- `status_filter_tabs.dart:45` indicator `AnimatedPositioned` and `:69` label
  `AnimatedDefaultTextStyle`.
- `terms_and_conditions_section.dart:53` chevron `AnimatedRotation` and
  `:95` accordion `AnimatedCrossFade`.
- `auth_card_scaffold.dart:210` gender-selector `AnimatedContainer`.
- Carousel — covered in §11.2.

Per §10.1 item 3's explicit call: the filter tabs and the accordion are now
gated rather than left open, since both communicate state that's also
conveyed statically (a filled pill, an expanded panel) — gating them to
`Duration.zero` loses no information.

All 14 of the app's implicit animations (per §9.2 finding 2's count) are now
reduced-motion-gated, aside from the four `OpenContainer` transforms noted as
an open package limitation in §11.1.

### 11.4 Item 4 — stale doc comment (fixed)

`lib/utils/motion.dart:1-19` no longer claims route transitions are
platform-default with no override. It now describes the `OpenContainer`
container-transform as the intended card → detail motion, names the four
call sites, and states the `Hero` rejection inline (with a pointer to §8.5)
so the decision is discoverable from the code, not only from this document.

### 11.5 Item 5 — `StatusChip` width snap (fixed)

`lib/widgets/provider/status_chip.dart` — wrapped the existing
`AnimatedSwitcher` in an `AnimatedSize` (`alignment: Alignment.centerLeft`,
same duration/curve, same reduced-motion gate) so a label-length change (e.g.
"Assigned" → "In Progress") eases the chip's width instead of snapping to the
wider label for the whole fade.

### 11.6 Item 7 (partial) — dead code

`lib/widgets/banner_slider.dart` confirmed unreferenced anywhere in `lib/`
(grep, this session) and deleted after explicit user confirmation.

The nav-pill duration reconsideration (§10.1 item 7, first bullet) and the
async `AnimatedSwitcher` wraps (second bullet) were left as-is — the former
is a "consider," not a confirmed fix, and the latter depends on unscheduled
screen-splitting work.

### 11.7 Verification

`flutter analyze lib` (PowerShell, this session): same 13 pre-existing
`info`-level lints (`prefer_const_constructors` / `use_super_parameters`) in
files untouched by this pass, zero new errors or warnings. No device/emulator
reduced-motion check was run — same outstanding gap noted in §8.4/§10.1 item 3.

### 11.8 Updated status vs. §10.3

| # | Item | Status after this pass |
| --- | --- | --- |
| 1 | Review the four `OpenContainer` transforms | **Reviewed — no fix needed.** Reduced-motion gap on `OpenContainer` itself is a known package limitation, left open (§11.1). |
| 2 | Fix carousel `easeInOut`/400ms/320ms + pause on reduced motion | **Done** (§11.2) |
| 3 | Finish reduced-motion sweep + `disableAnimationsOf` | **Done** — 14/14 implicit animations gated (§11.3) |
| 4 | Correct `motion.dart`'s stale route-transition comment | **Done** (§11.4) |
| 5 | Eyeball `StatusChip` width snap | **Done** — fixed with `AnimatedSize`, not just eyeballed (§11.5) |
| 6 | `StatusProgressBar` fill animation | Not started — additive, out of scope this pass |
| 7 | Nav pill duration, async wraps, delete `BannerSlider` | **Partially open** — `BannerSlider` deleted; nav pill duration and async wraps untouched |

No further changes were made to the app beyond what's listed above.
