# Provider Dashboard drawer removal

**Date:** 2026-08-03
**Why:** The provider dashboard's hamburger-menu `Drawer` (`lib/widgets/provider/provider_app_drawer.dart`) linked to 12 screens. An audit found only **1 of the 12** (Online/Offline Status) was backed by a real API — the rest read/wrote an explicitly-labeled mock repository with no server-side support. The drawer's `openDrawer()` trigger had also stopped working (menu button state was left over from an earlier UI pass), so the other 11 screens were unreachable in-app already. Rather than fix a menu into 11 non-functional pages, the drawer was removed and the one real feature (Online/Offline Status) was folded into the Profile tab's existing "Availability" section.

If a future task needs any of these features for real, this file records what existed, what it looked like, and — critically — which parts were fake so nobody assumes working functionality just because a screen re-appears in git history.

## What was kept

- **Online/Offline Status** — the toggle logic (`lib/utils/provider_availability_helper.dart`, `toggleProviderOnlineStatus()`) and its backing API (`ProviderAvailabilityApiService`, `ProviderDashboardProvider.setOnline()`/`loadAvailabilityStatus()`) are real and documented in `api.txt` (`POST`/`PUT`/`GET /api/provider-avability-status`). This is now surfaced as a live switch in the Profile tab's "Availability" card instead of its own drawer screen (`online_status_screen.dart`, deleted).

## What was removed (all mock, no backend)

Every screen below read and wrote exclusively through `ProviderDashboardProvider`, whose data originates from `ProviderDashboardRepository` (`lib/repositories/provider_dashboard_repository.dart`) — a class explicitly commented:

> "Provides dummy/mock data for the Provider Dashboard. Replace with real API calls when backend endpoints are ready."

None of these had any endpoint in `api.txt`, and no mutating action (send quote, request withdrawal, mark-read, chat send, add/edit/delete schedule slot, toggle sub-service, upload document, create ticket) reached the network — everything was in-memory only and lost on app restart.

| Screen (deleted) | Route constant (deleted) | What it looked like | Backing state |
|---|---|---|---|
| My Quotes | `ProviderRoutes.myQuotes` | List of quotes sent to customers, status pills (pending/accepted/rejected) | `ProviderDashboardProvider.quotes` ← `_repo.getQuotes()` |
| Job History | `ProviderRoutes.jobHistory` | Past completed jobs with date filter chips, ratings | `ProviderDashboardProvider.jobHistory` ← `_repo.getJobHistory()` |
| Wallet | `ProviderRoutes.wallet` | Balance card, transaction list, "Request Withdrawal" button | `ProviderDashboardProvider.walletBalance` / `walletTransactions` / `requestWithdrawal()` |
| Reviews & Ratings | `ProviderRoutes.reviews` | Star rating summary + list of customer reviews | `ProviderDashboardProvider.reviews` / `averageRating` |
| Notifications | `ProviderRoutes.notifications` | Notification feed, unread badge, mark-as-read | `ProviderDashboardProvider.notifications` / `markNotificationRead()` |
| Chat (list + detail) | `ProviderRoutes.chatList` / `chatDetail` (detail wasn't even a registered route — pushed directly) | Thread list + a message screen, fully local | `ProviderDashboardProvider.chatThreads` / `sendChatMessage()` |
| Availability Schedule | `ProviderRoutes.schedule` | Add/edit/delete weekly time slots | `ProviderDashboardProvider.availabilitySlots` / `add/update/deleteAvailabilitySlot()` |
| Services Offered | `ProviderRoutes.servicesOffered` | Checkbox tree of sub-services under the provider's category | `ProviderDashboardProvider.serviceOfferings` / `toggleSubService()` |
| Documents | `ProviderRoutes.documents` | A *second*, fake document upload list (separate from the real one below) | `ProviderDashboardProvider.documents` / `uploadDocument()` |
| Support Center | `ProviderRoutes.support` | Static contact info + fake support ticket list/creation | `ProviderDashboardProvider.supportTickets` / `createSupportTicket()` |
| Settings | `ProviderRoutes.settings` | Change Password / Language / Notification toggle / Privacy / Terms — all no-ops | None (UI stubs only) |

**Important distinction:** the "Documents" screen removed here (`lib/screens/provider/documents/documents_screen.dart`) was a mock duplicate. The *real* provider document upload/verification flow already exists and is untouched, reachable from the Profile tab's "My Documents" button: `ProviderRoutes.verificationDocuments` → `lib/screens/provider/profile/verification_documents_screen.dart`, backed by the real `ProviderDocumentApiService`/`ProviderDocumentProvider` and documented in `api.txt` under "PROVIDER DOCUMENT APIs".

**Settings' one real piece:** Logout (`AuthProvider.logout()`) was real and has already been re-added as a logout icon button in the Profile tab's app bar (done in an earlier pass, before this cleanup) — so no real functionality was lost when `settings_screen.dart` was deleted.

## What was intentionally left alone

`ProviderDashboardProvider`, `ProviderDashboardRepository`, and the mock model classes under `lib/models/provider/` (`quote.dart`, `job.dart`, `wallet_transaction.dart`, `review.dart`, `notification_item.dart`, `chat_message.dart`, `availability_slot.dart`, `service_item.dart`, `document_item.dart`, `support_ticket.dart`) were **not** deleted, because:

- The Home tab's stat cards (Active Bookings, Completed Today, Today's Earnings, Wallet Balance) read `activeJobs`, `jobHistory` (via `completedJobsToday`), `earningsSummary`, and `walletBalance` from this same provider.
- The Requests tab's "Send Quote" action calls `ProviderDashboardProvider.sendQuote()`, which also depends on this mock data.

These are still mock-backed today (same caveat as everything above), but removing them was out of scope for this cleanup — only the drawer and its 11 dead-end screens were removed. If/when a real quotes or earnings API exists, `ProviderDashboardProvider` is the integration point.

## Re-adding a feature later

If you want to bring one of these back for real:
1. Check `api.txt` first — if there's still no endpoint documented, the backend needs to build one before this is worth doing.
2. The original screen code is recoverable from git history prior to this commit (search the commit that references this doc).
3. Replace the relevant `ProviderDashboardRepository` getter(s) with a real `ApiService` call in `ProviderDashboardProvider`, following the pattern already used for Online/Offline Status (`ProviderAvailabilityApiService`) or Requests (`ProviderServiceRequestApiService`).
