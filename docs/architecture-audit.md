# Architecture Audit — Layered (UI / Logic / Data) Best Practices

Audit date: 2026-09-03
Scope: `lib/` (read-only analysis, no code changed)

This audit compares the current project structure against the recommended
MVVM + Repository layering (see `.claude/skills/flutter-apply-architecture-best-practices`):

```
lib/
├── data/        (models, repositories, services)
├── domain/      (clean models, use_cases — optional)
└── ui/
    ├── core/
    └── features/[feature]/{view_models, views}
```

## 1. Current structure (as-is)

```
lib/
├── main.dart                — MultiProvider DI + route table
├── models/                  — flat, mixes API/domain models (some under models/provider/)
├── providers/                — 10 ChangeNotifier classes (acting as ViewModels)
├── repositories/             — exactly ONE file, still returning mock data
├── services/                 — ~15 API/storage service classes (flat, no interfaces)
├── screens/                  — ~30 StatefulWidget/StatelessWidget "pages" (flat + provider/ subtree)
├── widgets/                  — shared + provider/-scoped components
└── utils/                    — helpers, constants, formatters
```

Total: ~120 Dart files, ~8,600 lines in `screens/` alone.

## 2. Layer-by-layer findings

### 2.1 Data layer

- **Services exist and are reasonably well-scoped** (`auth_api_service.dart`,
  `client_address_api_service.dart`, `provider_wallet_api_service.dart`, etc.) — one
  class per resource, each wrapping `http` calls. This part already matches the
  "Service" role in the target architecture.
- **Repository pattern is present in name only.** `lib/repositories/` contains a
  single file, `provider_dashboard_repository.dart`, and its own doc comment says:
  *"Provides dummy/mock data for the Provider Dashboard. Replace with real API
  calls when backend endpoints are ready."* It returns hardcoded lists, not data
  from `ProviderDashboardApiService`-like class, and nothing transforms API
  models into domain models.
- **No repository sits between the other 14 services and their ViewModels.**
  Every other feature (auth, categories, service catalog, client addresses,
  customer service requests, provider bookings, provider documents, provider
  wallet) has its `*Provider` class call the corresponding `*ApiService`
  directly. There is no single-source-of-truth layer, no caching, no
  offline/retry handling, and no seam for swapping/mocking data sources in
  tests.
- **Models are not split into API vs. domain models.** `lib/models/` (and
  `lib/models/provider/`) contains one model per concept (e.g. `job.dart`,
  `client_detail.dart`) that is used simultaneously as the wire format (JSON
  (de)serialization) and the UI-facing type. There's no transformation step,
  so any backend field-naming change propagates straight into the UI layer.
- **Local persistence services are miscategorized as plain `services/`.**
  `deleted_requests_store.dart`, `rejected_bookings_store.dart`,
  `request_passcode_store.dart`, and `session_service.dart` are local-storage
  wrappers (shared prefs / secure storage), architecturally the same kind of
  "Service" as the API clients, but they're informally special-cased inside
  providers (e.g. `CustomerServiceRequestProvider` owns both `_apiService` and
  two separate local stores and manually merges their results) — logic that
  belongs in a Repository.

### 2.2 Logic / Domain layer

- **No `domain/` layer exists at all.** There are no dedicated Use Case classes.
  Given the target architecture marks Use Cases as *optional* (only needed when
  logic is complex or shared across ViewModels), this alone isn't necessarily a
  gap — but see 2.3: because there's no Repository layer either, cross-cutting
  logic (merging deleted-request state with fetched requests, persisting
  passcodes as a side effect of fetch, hiding vs. deleting semantics) currently
  lives directly inside ChangeNotifier providers instead of a Repository or Use
  Case. Example: `CustomerServiceRequestProvider.loadRequests()`
  (`lib/providers/customer_service_request_provider.dart:34`) fetches from the
  API service, loads a hidden-ids store, filters, and persists passcodes — four
  responsibilities in one method, none of which is UI state management.

### 2.3 UI layer

- **Providers are doing ViewModel *and* Repository duties.** Every provider in
  `lib/providers/` (`AuthProvider`, `CustomerServiceRequestProvider`,
  `ProviderWalletProvider`, etc.) directly instantiates its API service(s) as
  private fields (`final AuthApiService _apiService = AuthApiService();`) and
  calls them inline. This is functionally closer to a "fat ViewModel that also
  is the repository" than the target's ViewModel-injected-with-Repository
  pattern. It works, but it means:
  - Providers can't be unit-tested without hitting the real `http`-based
    service (no injected interface/mock seam).
  - Data-shaping logic (e.g. merging/filtering, as above) is duplicated per
    provider instead of centralized once per resource.
- **Screens mix View and ViewModel-adjacent state.** Screens are
  `StatefulWidget`s that hold their own `setState`-managed fields (loading
  flags, fetched entities) *in addition to* reading from `Provider`/`context.read`.
  E.g. `request_detail_screen.dart` (912 lines) keeps a local `_loading`,
  `_error`, `_request` in `State`, calls `setState` directly after awaiting API
  calls via `context.read<CustomerServiceRequestProvider>()`, and separately
  does `context.watch<CustomerServiceRequestProvider>()` for provider-level
  state. This dual-state-management pattern (local State + external
  ChangeNotifier) is a common source of stale-UI / re-render bugs and doesn't
  match the "Views only render what the ViewModel exposes" rule.
- **No `ListenableBuilder`/`AnimatedBuilder` convention** — screens use
  `context.watch<T>()` (via `provider` package) directly in `build()`, which is
  an acceptable alternative in Flutter but is inconsistent with (and typically
  coarser-grained than) the skill's recommended `ListenableBuilder` scoping
  around just the reactive subtree. Not a defect per se, but worth deciding on
  one convention.
- **Very large screen files** indicate View, state, and formatting/business
  logic are colocated: `request_detail_screen.dart` (912 lines),
  `booking_detail_screen.dart` (821 lines), `service_requests_screen.dart`
  (755 lines), `home_screen.dart` (658 lines). These are prime candidates for
  extracting a ViewModel + smaller View components.
- **No feature-based grouping.** `lib/screens/` is a flat list for the
  customer flows (registration, login, service requests, profile, etc.), with
  only the provider-side flows grouped under `screens/provider/{dashboard,
  jobs, notifications, profile, requests, wallet}/`. This is the inverse of
  the target's guidance to group *all* UI by feature; currently only half the
  app follows a feature folder convention, and even that half doesn't have
  matching `view_models/` and `views/` subfolders.
- **`widgets/` is a flat shared-component bucket for customer widgets, with a
  `widgets/provider/` subtree for provider-only ones** — mirrors the same
  asymmetry as `screens/`.

### 2.4 Dependency injection

- DI does exist, via `MultiProvider` in `main.dart:66-78`, registering the 10
  providers app-wide at the root — but since providers construct their own
  services internally rather than receiving them via constructor injection,
  this DI only wires ViewModel-to-widget-tree, not Service/Repository-to-
  ViewModel. There's no `get_it`-style service locator or repository
  registration; adding a Repository layer later will require touching the
  constructor of every provider and this file together.

## 3. Summary of gaps vs. target architecture

| Layer | Target | Current state | Gap |
|---|---|---|---|
| Services | Stateless API/storage wrappers | Present, reasonably clean (`lib/services/`) | Low — mostly matches |
| Repositories | One per resource, transforms API→domain models, owns caching | One file, mock-only, not used by any real feature | High |
| Domain models | Separate from API models | Single model type reused for both | Medium |
| Use cases | Optional, for complex/shared logic | None; that logic lives inside providers | Low-Medium (only matters because Repository layer is missing) |
| ViewModels | `ChangeNotifier`, injected repositories, exposes immutable state | `ChangeNotifier` present, but injects nothing — owns services directly | Medium-High |
| Views | Lean, render ViewModel state only | Several screens (600–900+ lines) hold local `setState` state alongside provider state | Medium-High |
| Project structure | `data/`, `domain/`, `ui/core`+`ui/features/*/{view_models,views}` | `models/`, `providers/`, `repositories/`, `services/`, `screens/`, `widgets/`, `utils/` — flat, type-grouped for everything except provider-role screens/widgets | High (structural) |
| DI | Constructor-injected repositories into ViewModels | Root-level `MultiProvider` of self-contained ViewModels | Medium |

## 4. Detailed action plan

> **Status (2026-09-03):** partly implemented and partly superseded. §5 records
> what shipped. A post-implementation review found that Phase 1 step 2 and the
> step 3 ordering below rest on a false premise, and that Phase 3 step 1 is not
> achievable as written — **§6 is the corrected, current task list**. Read §6
> before starting any work from this section.

Nothing in this section has been implemented — it's a sequencing guide for
future work. Each phase is designed to be shippable on its own (no
"big-bang rewrite"), and later phases depend on earlier ones being in place.
Estimates assume one engineer familiar with the codebase.

### Phase 0 — Scaffolding (no behavior change)

1. Create the target folders so the migration has somewhere to land
   incrementally, without moving everything at once:
   ```
   lib/data/repositories/
   lib/data/models/          (optional — see Phase 4)
   lib/domain/models/        (optional — see Phase 4)
   lib/domain/use_cases/     (optional — see Phase 4)
   ```
   Leave `lib/services/` where it is; it already plays the "Service" role.
2. Add a short `docs/architecture-audit.md`-referencing note in
   `AGENTS.md`/`README.md` (or wherever the team keeps conventions) saying
   new features must follow Repository → ViewModel → View, so the codebase
   doesn't keep growing in the old shape while the migration is in progress.
3. No tests to run yet; this phase is directory/doc only.
   **Effort: ~30 min.**

### Phase 1 — Repository layer, one feature at a time

Order chosen by (a) how many data sources currently get merged ad hoc inside
the provider, and (b) blast radius if something breaks.

1. **`CustomerServiceRequestProvider`** (`lib/providers/customer_service_request_provider.dart`)
   — highest priority, since it already manually merges three data sources
   (`CustomerServiceRequestApiService`, `DeletedRequestsStore`,
   `RequestPasscodeStore`).
   - Create `lib/data/repositories/customer_service_request_repository.dart`.
   - Move `_apiService`, `_passcodeStore`, `_deletedStore` fields and the
     merge/filter logic from `loadRequests()`, `_persistPasscode()`,
     `fetchRequestById()`, `cancelRequest()`, `deleteRequest()` into the
     repository. The repository's public methods should return
     `List<CustomerServiceRequest>` / `CustomerServiceRequest`, already
     filtered and with passcodes persisted as a side effect.
   - `CustomerServiceRequestProvider` becomes a thin ViewModel: takes a
     `CustomerServiceRequestRepository` via constructor, keeps only
     `_requests`, `_loading`, `_saving`, `_error` UI-state fields, and calls
     one repository method per action.
   - Update `main.dart` registration:
     `ChangeNotifierProvider(create: (_) => CustomerServiceRequestProvider(CustomerServiceRequestRepository(...)))`.
   - Write a unit test for the repository's merge/filter logic (previously
     untestable without mocking `http`) — this is the concrete payoff of this
     step.
   **Effort: ~0.5–1 day.**

2. **`ProviderDashboardProvider`** — replace the mock `ProviderDashboardRepository`
   (`lib/repositories/provider_dashboard_repository.dart`) with a real one backed by the
   existing provider-side services (`provider_wallet_api_service.dart`,
   `provider_service_request_api_service.dart`, `provider_document_api_service.dart`,
   etc. — whichever the dashboard actually needs). Delete the mock data once the
   real repository is wired and verified against a real backend response.
   Move the file into `lib/data/repositories/` for consistency.
   **Effort: ~1–2 days** (depends on how many mock methods have real backend
   equivalents already; check `api.txt`/`api.md` per the `use-api-docs` skill
   before starting).

3. **Remaining providers**, in order of provider file size / complexity:
   `ProviderWalletProvider`, `ProviderDocumentProvider`, `ProviderBookingsProvider`,
   `ClientAddressProvider`, `ServiceCatalogProvider`, `ServiceTitleProvider`,
   `CategoryProvider`. Each follows the same recipe as step 1: extract a
   `*Repository` class that owns the corresponding `*ApiService`(s), inject it
   into the provider's constructor, update `main.dart`.
   **Effort: ~0.5 day each ≈ 3.5 days total.**

4. **`AuthProvider`** last — it's the most cross-cutting (session, login,
   registration, OTP, profile) and other providers/screens depend on it being
   stable throughout the migration. Extract `AuthRepository` wrapping
   `AuthApiService`, `ProviderProfileApiService`, `ClientProfileApiService`,
   and `SessionService`.
   **Effort: ~1 day**, plus a regression pass on login/registration/OTP flows
   since this touches the app's most-used path.

**Phase 1 total: ~6–8 days.** Ship each provider's migration as its own PR;
don't batch them, so a regression is easy to bisect.

### Phase 2 — Constructor-injected DI

1. Once Phase 1 lands for a given provider, its `main.dart` registration
   changes from `ChangeNotifierProvider(create: (_) => XProvider())` to
   `ChangeNotifierProvider(create: (_) => XProvider(XRepository(XApiService())))`.
   Do this incrementally per-provider alongside Phase 1, not as a separate
   pass.
2. Once all providers are repository-backed, consider whether a lightweight
   composition root (a single `lib/di.dart` building the service → repository
   → provider graph) is worth it to keep `main.dart` from growing a long
   constructor-argument chain. Not required for correctness — purely
   readability once the graph gets deep.
   **Effort: ~2–4 hours, after Phase 1 is fully done.**

### Phase 3 — Split oversized screens

Target the four screens flagged in §2.3, largest first. For each:

1. **`request_detail_screen.dart`** (912 lines) — remove the local `_loading`/
   `_error`/`_request` `State` fields; drive everything from
   `CustomerServiceRequestProvider` (already the repository-backed ViewModel
   after Phase 1 step 1). Replace the manual `setState()` calls at lines
   ~131–145 and ~164–170 with provider method calls + `context.watch`. Extract
   any pure-presentation sub-widgets (status chips, passcode reveal, action
   button rows) into `lib/widgets/` or a screen-local `_widgets.dart` if truly
   one-off.
2. **`booking_detail_screen.dart`** (821 lines) — same treatment, backed by
   `ProviderBookingsProvider` (Phase 1 step 3).
3. **`service_requests_screen.dart`** (755 lines) — backed by
   `CustomerServiceRequestProvider`.
4. **`home_screen.dart`** (658 lines) — likely touches multiple providers
   (categories, service catalog, featured content); split by concern into
   smaller stateless sub-widgets first, then verify each depends on exactly
   one provider where possible.

Do this only *after* the corresponding provider has its repository (Phase 1),
so the screen split doesn't have to be redone once data access changes
underneath it.
**Effort: ~1–1.5 days per screen ≈ 4–6 days total.**

### Phase 4 — Domain models and use cases (optional, evaluate after Phase 1–3)

1. Re-assess whether splitting API models from domain models
  (`lib/data/models/` vs `lib/domain/models/`) is worth it. Trigger for doing
  this: the backend's JSON shape has changed and broken UI code more than
  once, or a model is doing double duty awkwardly (e.g. nullable fields that
  only make sense for one side). If neither has happened, the current
  single-model approach is a reasonable tradeoff for this app's size — don't
  do this speculatively.
2. Only introduce a `domain/use_cases/` class where a repository method is
   used identically by 2+ ViewModels, or where a single ViewModel method has
   grown complex enough (multiple repository calls + branching) to be worth
   isolating and unit-testing on its own. Candidate today: none observed yet;
   revisit after Phase 1 once repositories exist to call.

### Phase 5 — Feature-folder convention for `screens/` and `widgets/`

1. Decide the convention: mirror what `screens/provider/{dashboard,jobs,
   notifications,profile,requests,wallet}/` already does, applied to the
   customer-facing screens too (e.g. `screens/auth/`, `screens/requests/`,
   `screens/profile/`, `screens/catalog/`).
2. Move files with `git mv` (preserves history) rather than delete+recreate;
   update imports via IDE refactor tooling, not manual find/replace, to avoid
   missed references.
3. Do this last, after Phases 1–3, so files aren't moved twice (once for the
   folder reorg, once for view_model/view splitting).
   **Effort: ~1 day**, mostly mechanical, but budget time for import-path
   fallout across ~120 files.

### Suggested sequencing summary

| Phase | Depends on | Effort | Ships independently? |
|---|---|---|---|
| 0 — Scaffolding | — | ~0.5 day | Yes |
| 1 — Repositories | Phase 0 | ~6–8 days | Yes, per provider |
| 2 — DI wiring | Rolls into Phase 1 | ~2–4 hrs | Yes, per provider |
| 3 — Screen splits | Phase 1 (per feature) | ~4–6 days | Yes, per screen |
| 4 — Domain models/use cases | Phase 1–3, evaluate first | Variable | Yes, if pursued |
| 5 — Feature folders | Phase 1–3 | ~1 day | Yes, but do last |

**Total estimated effort if all phases pursued: ~12–16 engineer-days**,
spread across incremental PRs. Phases 1 and 3 carry the real payoff
(testability, smaller/safer screens); Phase 4 and 5 are lower-urgency polish
and can be deprioritized or skipped if the team decides the current tradeoffs
are acceptable for the app's size.

## 5. Implementation pass 1 (2026-09-03) — Phase 0 + Phase 1 step 1

Given the ~12–16 day total estimate, this pass implements the parts of the
plan that are fully specified and shippable as one self-contained slice:
Phase 0 in full, and Phase 1's first (highest-priority) provider migration as
a worked example for the rest. Phase 1 steps 2–4, Phase 2's composition-root
question, and Phases 3–5 are **not** implemented here — they either depend on
choices (e.g. which provider-side services back the dashboard repository)
that need a decision per-provider, or are large enough to warrant their own
PR per the plan's own sequencing advice ("ship each provider's migration as
its own PR; don't batch them, so a regression is easy to bisect").

### 5.1 Phase 0 — Scaffolding

- Created `lib/data/repositories/`, `lib/domain/models/`, and
  `lib/domain/use_cases/` (the latter two currently hold only a `.gitkeep`
  placeholder — populate per §4 Phase 4's trigger conditions, not
  speculatively).
- Added a note to `AGENTS.md`'s "Adding/changing an API integration" section
  and Project Structure diagram pointing new/migrated features at
  `lib/data/repositories/` instead of having providers call `*ApiService`
  directly, and cross-referenced this document.

### 5.2 Phase 1 step 1 — `CustomerServiceRequestProvider` → Repository

Followed the plan's recipe exactly:

- Added `lib/data/repositories/customer_service_request_repository.dart`
  (`CustomerServiceRequestRepository`), owning `CustomerServiceRequestApiService`,
  `RequestPasscodeStore`, and `DeletedRequestsStore`. All three are
  constructor-injectable (default to real instances) so the class can be
  exercised with fakes in tests. Moved the fetch/hide-filter merge and
  passcode-persistence side effect out of the provider's `loadRequests()` and
  into `fetchByClient()`; `create`, `fetchById`, `cancel`, and `hide` are
  thin pass-throughs that keep the same request-shaping responsibilities the
  provider used to own inline.
- `lib/providers/customer_service_request_provider.dart` is now a thin
  ViewModel: it takes a `CustomerServiceRequestRepository` via an optional
  constructor parameter (defaults to `CustomerServiceRequestRepository()` so
  existing no-arg construction elsewhere still compiles), and keeps only
  `_requests`/`_loading`/`_saving`/`_deletingUid`/`_cancellingUid`/`_error`
  UI-state fields. No public method signature changed, so no call site
  outside the provider needed touching.
- `lib/main.dart` registration updated to
  `ChangeNotifierProvider(create: (_) => CustomerServiceRequestProvider(CustomerServiceRequestRepository()))`,
  making the injection explicit per §4 Phase 2's guidance (done inline with
  the provider's own migration, as the plan recommends, rather than as a
  separate pass).
- Added `test/customer_service_request_repository_test.dart` — 4 unit tests
  covering the previously-untestable merge/filter logic (hidden requests
  excluded from the visible list, passcodes persisted only for visible
  requests, `hide()` delegates correctly), using hand-written fakes that
  subclass `CustomerServiceRequestApiService`/`DeletedRequestsStore`/
  `RequestPasscodeStore` and override their methods — this project has no
  mock-generation package (`mockito`/`mocktail`) installed, so fakes-by-
  subclassing matches the existing test style (see
  `test/session_service_test.dart`'s method-channel mock).
- `AGENTS.md`'s "Customer Service Requests" bullet updated to describe the
  new provider → repository → service/store shape and point at this section
  as the pattern to copy for the remaining providers.

### 5.3 Verification

- `flutter analyze lib test` — clean; same 13 pre-existing `info`-level
  lints as before this pass (`prefer_const_constructors`/
  `use_super_parameters` in files this pass didn't touch), zero new issues.
- `flutter test` — all 12 tests pass (8 pre-existing + 4 new repository
  tests).
- No behavior change from a user's perspective: `CustomerServiceRequestProvider`'s
  public API (`requests`, `loading`, `saving`, `deletingUid`, `cancellingUid`,
  `error`, `loadRequests`, `getStoredPasscode`, `createRequest`,
  `fetchRequestById`, `cancelRequest`, `deleteRequest`) is unchanged, so
  every screen that reads this provider (`ServiceRequestsScreen`,
  `RequestDetailScreen`, etc.) needed no changes.

### 5.4 What's still open

- Phase 1 steps 2–4 (`ProviderDashboardProvider` real-repository swap, the
  remaining 6 providers, `AuthProvider` last) — not started. Step 2 in
  particular needs a decision on which provider-side services back each
  mock method before it can start; flagged in §4 as needing an `api.txt`
  check first, not just a mechanical extraction like step 1 was.
- Phase 2's optional composition-root file (`lib/di.dart`) — not worth doing
  yet with only one provider migrated; revisit once 3–4 are done and
  `main.dart`'s registration block starts getting noisy.
- Phases 3–5 (screen splits, domain models/use cases, feature folders) —
  unstarted, each is its own multi-day slice per §4's own estimates.

## 6. Final task list — corrected and ready to implement

This section supersedes §4's Phase 1 steps 2–3 and Phase 3 step 1. It exists
because a post-implementation review (2026-09-03) traced the claims §4 was
built on and found three of them wrong. Everything below is verified against
the working tree at that date; each task is self-contained, states its own
acceptance check, and is ordered so nothing has to be redone.

**Standing gates for every task**: `flutter analyze lib test` must report no
new issues (13 pre-existing `info` lints are the baseline), and `flutter test`
must stay green. Per the WSL notes in `AGENTS.md`, run both through
`powershell.exe ... -LiteralPath`, not bash `flutter`.

### Task 1 — Make the repository injection required (30 min)

`CustomerServiceRequestProvider` currently takes an *optional positional*
repository that defaults to a real instance:

```dart
CustomerServiceRequestProvider([CustomerServiceRequestRepository? repository])
    : _repository = repository ?? CustomerServiceRequestRepository();
```

§5.2 justified the default as preserving "existing no-arg construction
elsewhere". There is no such call site — `lib/main.dart:76` is the only place
the provider is constructed, and it already passes the repository explicitly.
The default therefore buys nothing and silently re-closes the seam this whole
migration opened: `CustomerServiceRequestProvider()` still compiles and binds
the live `http` service.

- Change to `CustomerServiceRequestProvider({required CustomerServiceRequestRepository repository})`,
  matching the skill's `ProfileViewModel({required UserRepository userRepository})` shape.
- Update `lib/main.dart:76` to the named form.
- Leave `CustomerServiceRequestRepository`'s own optional service/store
  parameters as they are — `main.dart` legitimately constructs it no-arg and
  the tests inject fakes through them.
- **Every subsequent provider migration must use the required-named form.**

*Acceptance:* deleting the argument at the `main.dart` call site is a compile
error.

### Task 2 (Phase 0b) — Delete the dead mock stack (~2 hrs)

**This replaces §4 Phase 1 step 2 entirely.** That step said to "replace the
mock `ProviderDashboardRepository` with a real one backed by the existing
provider-side services", and §5.4 deferred it pending "a decision on which
provider-side services back each mock method". Both assume the mock data is
rendered somewhere. It is not.

Verified by tracing every getter across `lib/screens/` and `lib/widgets/`:
`quotes`, `activeJobs`, `jobHistory`, `earningsSummary`, `walletBalance`,
`walletTransactions`, `reviews`, `notifications`, `chatThreads`,
`availabilitySlots`, `serviceOfferings`, `documents`, `supportTickets`, plus
the derived `completedJobsToday`, `averageRating`, and
`unreadNotificationCount` — **zero UI consumers**. The dashboard's visible
"Average Rating" reads `dashboard.providerDetail?.averageRating`
(`provider_home_tab.dart:63`, real API) and its wallet figure reads
`walletProvider.wallet?.balance` (`:64`, real `ProviderWalletProvider`). All
five provider tabs run entirely on real providers.

So the work is deletion, not integration:

1. Delete `lib/repositories/provider_dashboard_repository.dart` (191 lines)
   and the now-empty `lib/repositories/` directory.
2. Delete the 10 orphan models (332 lines total) whose only importers are that
   repository and `ProviderDashboardProvider`: `quote.dart`,
   `chat_message.dart`, `support_ticket.dart`, `review.dart`,
   `notification_item.dart`, `service_item.dart`, `earnings_summary.dart`,
   `availability_slot.dart`, `wallet_transaction.dart`, `job.dart`.
   Keep `provider_detail.dart`, `service_request.dart`, `service_booking.dart`,
   `provider_wallet.dart`, `provider_documents.dart`,
   `availability_status.dart` — all real.
3. In `lib/providers/provider_dashboard_provider.dart`: delete the `_repo`
   field, the 13 assignments in the constructor (leaving the constructor
   removable entirely), and the dead fields/getters/mutation methods spanning
   roughly lines 136–276, plus `completedJobsToday` at the end and the
   corresponding imports. What must remain: `providerDetail`,
   `profileLoading`, `profileError`, `loadProviderDetail`,
   `updateProviderDetail`, and the availability + incoming-requests members.
4. Delete the empty `lib/database/` directory (leftover from the removed
   legacy SQLite stack).
5. `AGENTS.md` has already been corrected to describe this stack as dead —
   after deletion, drop the "Dead mock scaffolding" section and the related
   caveats in Project Structure and Important Notes.

*Acceptance:* `flutter analyze` clean, `flutter test` green, app builds and the
provider dashboard renders identically (no tab reads this data today, so there
should be no visible change whatsoever). Expected diff: ~700 lines removed,
zero added.

*Do this before Task 3* — it shrinks the largest provider (320 lines) by
roughly half, so the later dashboard migration has far less to move.

### Task 3 — `ProviderBookingsProvider` → Repository (~0.5 day)

**Promoted from §4 Phase 1 step 3**, where it was buried mid-list behind
`ProviderWalletProvider`. §4's own stated criterion (a) is "how many data
sources currently get merged ad hoc inside the provider" — and this provider
merges `ServiceBookingApiService` with `RejectedBookingsStore`
(`provider_bookings_provider.dart:50-53`) and maintains a persisted
`_rejectedSeenCount` badge. That is the same shape that correctly made
`CustomerServiceRequestProvider` step 1, and it backs the two largest
provider-side screens.

Follow the §5.2 recipe exactly, with Task 1's required-named injection:

- Create `lib/data/repositories/provider_bookings_repository.dart` owning both
  the API service and the store.
- Move into it: the fetch + rejected-bookings merge from `loadBookings()`, the
  seen-count load/save behind `markRejectedSeen()`, and the `respond()` /
  status-update pass-throughs.
- Keep `_bookings`, `_loading`, `_updatingUid`, `_error`, `_providerUid`, and
  the `unviewedRejectedCount` computation in the ViewModel — that last one is
  presentation logic, not data access.
- Preserve every public signature so `requests_tab.dart`, `jobs_tab.dart`,
  `booking_detail_screen.dart`, and `rejected_requests_screen.dart` need no
  changes.
- Add `test/provider_bookings_repository_test.dart` covering the API+rejected
  merge and the seen-count round-trip, using subclass fakes (no mock package
  in this project — see `AGENTS.md`).

### Task 4 — `ProviderDashboardProvider` → Repository (~0.5 day)

After Task 2 this is a small, purely mechanical extraction over three real
services (`ProviderProfileApiService`, `ProviderAvailabilityApiService`,
`ProviderServiceRequestApiService`) — no `api.txt` investigation needed, which
is what §4 step 2 wrongly budgeted 1–2 days for.

### Task 5 — Remaining providers (~0.5 day each ≈ 3 days)

§4 step 3 claimed to order these "by provider file size / complexity" but led
with the smallest provider in the repo. Corrected order, actually descending:

| Provider | Lines | Notes |
|---|---|---|
| `ProviderDocumentProvider` | 243 | multipart upload + re-download logic |
| `ClientAddressProvider` | 127 | plain CRUD |
| `CategoryProvider` | 49 | eager-loads in constructor |
| `ServiceTitleProvider` | 44 | plain CRUD |
| `ServiceCatalogProvider` | 43 | eager-loads in constructor |
| `ProviderWalletProvider` | 33 | single call; do last, lowest value |

### Task 6 — `AuthProvider` → Repository (~1 day + regression pass)

Unchanged from §4 Phase 1 step 4, and still correctly last. Wrap
`AuthApiService`, `ProviderProfileApiService`, `ClientProfileApiService`, and
`SessionService`. Budget a manual pass over login, registration, OTP, forgot/
reset password, account deletion, and dashboard switching — this is the app's
most-used path and the one with the least automated coverage.

### Task 7 — Prerequisite before any Phase 3 screen split (~2 hrs)

**§4 Phase 3 step 1 is not achievable as written.** It says to remove
`request_detail_screen.dart`'s local `_request`/`_loading`/`_error` `State`
fields and "drive everything from `CustomerServiceRequestProvider`". The
provider has nowhere to put that state: it exposes only a *list*, and
`fetchRequestById` merges a refetched request into it **only "if present
there"** (`customer_service_request_provider.dart:100-106`). A detail screen
opened for a request that isn't in `_requests` would have no backing state at
all. `RequestDetailScreen` also seeds itself from `widget.request`.

Before splitting either detail screen, add explicit selection state to the
ViewModel — `selectedRequest`, `detailLoading`, `detailError`, and a
`selectRequest(int uid)` command that populates them and clears on dispose —
then have the View render only those. The identical gap exists in
`ProviderBookingsProvider.fetchBookingById` for `booking_detail_screen.dart`;
fix both the same way.

Only after this does §4 Phase 3's line-count reduction work become safe.

### Task 8 — Close the repository test gap (~15 min)

`CustomerServiceRequestRepository.fetchById()` persists a passcode as a side
effect (`customer_service_request_repository.dart:75-79`), but no test covers
it — §5.2 names passcode persistence as one of the two behaviors the
extraction was meant to make testable, and only the `fetchByClient` path is
asserted. Add a fifth test using the existing `_FakeApiService` (override
`fetchById`) and `_FakePasscodeStore`.

### Revised sequencing

| Task | Depends on | Effort | Ships alone? |
|---|---|---|---|
| 1 — Required injection | §5 (done) | 30 min | Yes |
| 2 — Delete dead mock stack | — | ~2 hrs | Yes |
| 8 — Test gap | §5 (done) | 15 min | Yes |
| 3 — Bookings repository | 1, 2 | ~0.5 day | Yes |
| 4 — Dashboard repository | 2 | ~0.5 day | Yes |
| 5 — Remaining 6 providers | 1 | ~3 days | Yes, per provider |
| 6 — Auth repository | 5 | ~1 day | Yes |
| 7 — Detail-state prerequisite | 3 | ~2 hrs | Yes |
| Phase 3 screen splits (§4) | 7 | ~4–6 days | Yes, per screen |
| Phases 4–5 (§4) | all above | deferred | — |

Tasks 1, 2, and 8 total under three hours and can land as a single PR. The
corrected repository work (Tasks 3–6) is **~5 days rather than §4's 6–8**,
because Task 2 removes work that §4 had budgeted as integration.

## 7. Implementation pass 2 (2026-09-03) — §6 Tasks 1, 2, 3, 4, 5, 7, 8

Implemented every §6 task except Task 6 (`AuthProvider`). Verified after each
task with `flutter analyze lib test` (clean, same 13 pre-existing `info`
lints throughout) and `flutter test` (green throughout, growing from 12 to
17 tests). Deletions in Task 2 required explicit user confirmation per this
session's tooling (destructive-action gate); confirmed and proceeded.

### 7.1 Task 1 — Required-named injection

`CustomerServiceRequestProvider`'s constructor changed from
`([CustomerServiceRequestRepository? repository])` to
`({required CustomerServiceRequestRepository repository})`. `lib/main.dart`
updated to the named form. Every provider migrated in this pass (§7.3–§7.5)
used the required-named form from the start, so this pattern is now
consistent across all seven newly-migrated providers plus the one from pass 1.

### 7.2 Task 2 — Deleted the dead mock dashboard stack

Deleted, after explicit user confirmation:
- `lib/repositories/provider_dashboard_repository.dart` and the now-empty
  `lib/repositories/` directory.
- 11 orphaned `lib/models/provider/` model files: the 10 §6 named
  (`quote.dart`, `chat_message.dart`, `support_ticket.dart`, `review.dart`,
  `notification_item.dart`, `service_item.dart`, `earnings_summary.dart`,
  `availability_slot.dart`, `wallet_transaction.dart`, `job.dart`) plus
  **`document_item.dart`, which §6 missed** — verified by grep that its only
  importers were the same repository and provider being deleted/rewritten,
  so it was orphaned by the same deletion and removed too.
- The empty `lib/database/` directory (already empty pre-deletion, a leftover
  from the earlier-removed legacy SQLite stack).

`ProviderDashboardProvider` rewritten to keep only the real methods §6 listed
(`providerDetail`, `profileLoading`, `profileError`, `loadProviderDetail`,
`updateProviderDetail`, plus the availability and incoming-requests members)
— see §7.4 for its subsequent repository extraction in the same pass.

`AGENTS.md` updated: removed the "Dead mock scaffolding — pending deletion"
section entirely (it described data that no longer exists), and the stale
cross-references to it in the Provider Dashboard section, Project Structure,
and Important Notes.

### 7.3 Task 3 — `ProviderBookingsRepository`

Added `lib/data/repositories/provider_bookings_repository.dart`, owning
`ServiceBookingApiService` and `RejectedBookingsStore`. Moved the
fetch+rejected-merge from `loadBookings()` and the `respond(accept: false)`
side effect of persisting a rejected booking into the repository; kept
`_bookings`/`_loading`/`_updatingUid`/`_error`/`_providerUid` and the derived
`unviewedRejectedCount` (presentation logic) in the now-thin
`ProviderBookingsProvider`. `lib/main.dart` updated to
`ProviderBookingsProvider(repository: ProviderBookingsRepository())`. Added
`test/provider_bookings_repository_test.dart` — 4 tests covering the merge,
`respond(accept: false)` persisting to the store, `respond(accept: true)` not
touching it, and the seen-count round-trip.

### 7.4 Task 4 — `ProviderDashboardRepository`

Added `lib/data/repositories/provider_dashboard_repository.dart` (new file,
same class name as the just-deleted mock one, new location and real
implementation), wrapping the three already-real services
(`ProviderProfileApiService`, `ProviderAvailabilityApiService`,
`ProviderServiceRequestApiService`) with no merging — as §6 predicted, this
was mechanical once Task 2 removed the dead half. `ProviderDashboardProvider`
reduced to UI state only, `lib/main.dart` updated to
`ProviderDashboardProvider(repository: ProviderDashboardRepository())`.

### 7.5 Task 5 — Remaining 6 providers

All six migrated to the same required-named-injection, thin-ViewModel shape,
each with a matching `lib/data/repositories/*_repository.dart`:

- **`ProviderDocumentProvider`** → `ProviderDocumentRepository` — the one
  provider in this batch with real logic to move, not just a pass-through:
  `fetchDocuments`/`uploadDocuments` (via `ProviderDocumentApiService`),
  `resolveUrl` (relative path → full URL), and the raw `http.get` +
  temp-file-write used to re-download an already-uploaded image when the
  upload endpoint needs all three slots resent but only one was replaced.
  `ImagePicker`, the freshly-picked `File?` fields, and all
  loading/progress/error UI state stayed in the provider — those are
  presentation state, not data access.
- **`ClientAddressProvider`** → `ClientAddressRepository` — plain CRUD
  pass-through (fetch/create/update/delete), no merging.
- **`CategoryProvider`** → `CategoryRepository` — single-call pass-through.
  Kept the constructor's `scheduleMicrotask(fetchCategories)` eager-load
  (with its existing comment explaining why it's deferred) in the provider,
  since it's UI-lifecycle timing, not data access.
- **`ServiceTitleProvider`** → `ServiceTitleRepository` — single-call
  pass-through; kept the `_requestId` stale-response-guard in the provider
  (it's about which UI state to apply, not what data to fetch).
- **`ServiceCatalogProvider`** → `ServiceCatalogRepository` — single-call
  pass-through; moved the `displayOrder` sort into the repository's
  `fetchServices()` (data-shaping, same reasoning as the passcode-persistence
  side effect in `CustomerServiceRequestRepository` from pass 1), leaving the
  provider's `fetchServices()` a plain assignment.
- **`ProviderWalletProvider`** → `ProviderWalletRepository` — single-call
  pass-through, done last as §6 specified (lowest value).

`lib/main.dart` updated for all six registrations; grepped for any other
construction site of these providers (tests, screens) before changing the
constructors — none existed, so no call site outside `main.dart` needed
touching. `AGENTS.md`'s Architecture Overview, Project Structure, and
"Adding an API integration" sections updated to describe every provider
except `AuthProvider` as repository-backed.

### 7.6 Task 7 — Detail-screen selection-state prerequisite

Added to both `CustomerServiceRequestProvider` and `ProviderBookingsProvider`
(same shape in each): `selectedRequest`/`selectedBooking`,
`detailLoading`, `detailError`, a `selectRequest(int uid)` /
`selectBooking(int uid, int providerUid)` command that fetches via the
existing `fetchRequestById`/`fetchBookingById` (reusing their list-merge
behavior) and populates the new fields, and a `clearSelection()` method for
the future detail screen to call from `dispose()`.

**This is scaffolding only** — purely additive, no existing method signature
changed, and `RequestDetailScreen`/`BookingDetailScreen` were not touched, so
they still seed themselves from the navigation-argument copy and keep their
own local `State` exactly as before. §6 Task 7's own text frames it as a
prerequisite ("only after this does §4 Phase 3's line-count reduction work
become safe"), not the screen split itself — the screen split remains
unstarted, tracked below.

### 7.7 Task 8 — Passcode-persistence test gap

Added a fifth test to `test/customer_service_request_repository_test.dart`:
`fetchById persists the fetched request's passcode`, using the existing
`_FakeApiService` (added a `fetchById` override) and `_FakePasscodeStore`.

### 7.8 Verification

- `flutter analyze lib test` — clean after every task in this pass; same 13
  pre-existing `info`-level lints throughout, zero new issues at any point.
- `flutter test` — green throughout; 12 → 17 tests (4 new repository tests
  for bookings, 1 new passcode test for customer requests). `widget_test.dart`
  (`App builds without crashing`) exercises the full `MultiProvider` tree in
  `main.dart`, so it caught any registration/constructor mismatch across all
  nine repository-wiring changes in this pass.
- No behavior change from a user's perspective for any of the seven
  providers touched — every public method signature was preserved, so no
  screen needed changes (verified by grepping each provider's public API
  surface against `lib/screens/` and `lib/widgets/` usage before and after).

### 7.9 What's still open

- **§6 Task 6 — `AuthProvider` → `AuthRepository`.** Deliberately not
  attempted in this pass. Unlike every other provider migrated here, Task 6
  explicitly calls for "a manual pass over login, registration, OTP, forgot/
  reset password, account deletion, and dashboard switching" against a live
  backend — this is the app's most-used path with the least automated
  coverage, and that regression pass cannot be done from this environment
  (no running emulator/device session in this pass). Do not attempt the
  extraction without also budgeting that manual verification.
- **Phase 3 screen splits** (`request_detail_screen.dart`,
  `booking_detail_screen.dart`, `service_requests_screen.dart`,
  `home_screen.dart`) — unstarted. §7.6's selection-state addition is the
  prerequisite Task 7 called for; the actual `State`-field removal and
  `ListenableBuilder`/`context.watch` rewiring in each screen is separate
  work, not started here.
- **Phases 4–5** (domain models/use cases, feature-folder convention) —
  unstarted, per §4's own "evaluate first" / "do last" guidance.
