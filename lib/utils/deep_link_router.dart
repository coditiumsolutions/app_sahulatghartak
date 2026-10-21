import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/push_event.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/provider/verification_pending_screen.dart';
import 'active_role_tracker.dart';
import 'notification_router.dart';
import 'provider_routes.dart';

/// What a tapped `https://sahulatghartak.com/...` link should open.
enum DeepLinkKind { home, request, booking, notifications }

class DeepLink {
  final DeepLinkKind kind;
  final int? id;
  const DeepLink(this.kind, [this.id]);

  @override
  bool operator ==(Object other) =>
      other is DeepLink && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

const _allowedHosts = {'sahulatghartak.com', 'www.sahulatghartak.com'};

/// Maps a link to a [DeepLink], or null when it is not ours (other scheme or
/// host). Everything on our host that is not an `/app/...` target (the
/// marketing pages `/home-maintenance`, `/specialized-services`,
/// `/property-and-legal-services`, `/Home/DownloadApp`, `/`, and any unknown
/// path) becomes [DeepLinkKind.home], so a link never errors. The link is never
/// trusted for access: ids are opaque and the API still authorises.
DeepLink? parseDeepLink(Uri uri) {
  if (uri.scheme != 'https') return null;
  if (!_allowedHosts.contains(uri.host.toLowerCase())) return null;

  final segments = uri.pathSegments
      .where((s) => s.isNotEmpty)
      .map((s) => s.toLowerCase())
      .toList();
  if (segments.isEmpty) return const DeepLink(DeepLinkKind.home);

  if (segments.first == 'app') {
    final rest = segments.skip(1).toList();
    if (rest.length == 1 && rest.first == 'notifications') {
      return const DeepLink(DeepLinkKind.notifications);
    }
    if (rest.length == 2) {
      final id = int.tryParse(rest[1]);
      if (id != null) {
        if (rest[0] == 'requests') return DeepLink(DeepLinkKind.request, id);
        if (rest[0] == 'bookings') return DeepLink(DeepLinkKind.booking, id);
      }
    }
    return const DeepLink(DeepLinkKind.home);
  }

  // Marketing pages and anything unrecognised both open Home.
  return const DeepLink(DeepLinkKind.home);
}

/// Receives App Links / Universal Links and routes them with the same
/// navigator and role rules as push taps.
///
/// A link that arrives before the first real screen is up (cold start, or
/// while the splash is still resolving the session) is held and routed by
/// [routeColdStartLink], the same way `takeInitialEvent()` works for pushes.
class DeepLinkRouter {
  DeepLinkRouter._();
  static final DeepLinkRouter instance = DeepLinkRouter._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;
  bool _ready = false;
  Uri? _pending;

  /// Never throws: a link problem must not stop the app from starting.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _subscription = _appLinks.uriLinkStream.listen(_onLink, onError: (_) {});
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _onLink(initial);
    } catch (e) {
      debugPrint('Deep link init failed: $e');
    }
  }

  void _onLink(Uri uri) {
    if (!_ready) {
      // The initial link can arrive from both getInitialLink() and the
      // stream; keeping only the latest holds it once.
      _pending = uri;
      return;
    }
    handle(uri);
  }

  /// Call once the session is resolved and the first real screen is showing.
  /// Routes the held link (if any) and starts routing later ones directly.
  Future<void> routeColdStartLink() async {
    _ready = true;
    final uri = _pending;
    _pending = null;
    if (uri != null) await handle(uri);
  }

  Future<void> handle(Uri uri) async {
    try {
      final link = parseDeepLink(uri);
      if (link == null) return;
      await _route(link);
    } catch (e) {
      debugPrint('Deep link routing failed: $e');
    }
  }

  Future<void> _route(DeepLink link) async {
    final nav = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (nav == null || context == null) return;

    final auth = context.read<AuthProvider>();
    // Logged out: the splash/landing flow already owns the screen. A protected
    // screen must never open from a link.
    if (!auth.isLoggedIn) return;

    switch (link.kind) {
      case DeepLinkKind.request:
        // Requests belong to the client side of the account.
        if (activeRoleTracker.userTypeFor(auth) != 'Client') {
          return _goHome(nav);
        }
        await routeForPush(PushEvent(
            type: 'deep_link',
            screen: 'request_details',
            requestId: link.id,
            fromTap: true));
      case DeepLinkKind.booking:
        if (auth.role != 'Provider') return _goHome(nav);
        await routeForPush(PushEvent(
            type: 'deep_link',
            screen: 'my_bookings',
            bookingId: link.id,
            fromTap: true));
      case DeepLinkKind.notifications:
        // routeForPush's default sends customers to Home; the inbox itself is
        // shared by both roles, so open it directly.
        nav.pushNamed(ProviderRoutes.notifications);
      case DeepLinkKind.home:
        _goHome(nav);
    }
  }

  /// Back to the root screen the account landed on (customer shell, provider
  /// dashboard or the pending-verification page), so each role keeps its own
  /// "home" without repeating the entry-gate rules here.
  void _goHome(NavigatorState nav) {
    const roots = {
      HomeScreen.routeName,
      ProviderRoutes.dashboard,
      VerificationPendingScreen.routeName,
    };
    nav.popUntil(
        (route) => route.isFirst || roots.contains(route.settings.name));
  }

  @visibleForTesting
  void dispose() {
    _subscription?.cancel();
  }
}

/// Convenience for the splash, next to `routeColdStartPush()`.
Future<void> routeColdStartLink() =>
    DeepLinkRouter.instance.routeColdStartLink();
