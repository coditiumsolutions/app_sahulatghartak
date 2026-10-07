import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/notification_repository.dart';
import '../models/push_event.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/push_notification_service.dart';
import '../utils/active_role_tracker.dart';
import '../utils/notification_router.dart';
import '../utils/update_block.dart';

/// Wires push notifications to the session: registers/unregisters the device
/// token as the user (or active role) changes, keeps the unread badge fresh,
/// and forwards foreground/tap events. Renders [child] untouched. Every
/// failure here is swallowed - notifications must never block the app.
class PushHost extends StatefulWidget {
  const PushHost({super.key, required this.child});
  final Widget child;

  @override
  State<PushHost> createState() => _PushHostState();
}

class _PushHostState extends State<PushHost> with WidgetsBindingObserver {
  final _push = PushNotificationService.instance;
  final _repository = NotificationRepository();
  final _subscriptions = <StreamSubscription<dynamic>>[];

  late final AuthProvider _auth;
  late final NotificationProvider _notifications;

  String? _registeredKey; // "userId:userType:token"
  String? _registeredToken;
  bool _permissionAsked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = context.read<AuthProvider>();
    _notifications = context.read<NotificationProvider>();
    _auth.addListener(_sync);
    activeRoleTracker.addListener(_sync);
    _start();
  }

  Future<void> _start() async {
    try {
      await _push.init();
      _subscriptions
        ..add(_push.events.listen(_onEvent))
        ..add(_push.onTokenRefresh.listen((_) => _sync(force: true)));
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
    _sync();
    _pullRelease();
  }

  /// Pull side of the admin release: the silent push is best effort on iOS,
  /// so a blocked app also asks app config for the latest release time.
  Future<void> _pullRelease() => updateBlock.pullRelease(() async {
        final token = _registeredToken ??
            await _push
                .getToken()
                .timeout(const Duration(seconds: 5), onTimeout: () => null);
        final config = await _repository
            .fetchAppConfig(_push.platform, deviceToken: token)
            .timeout(const Duration(seconds: 5));
        return config.lastUnblockAt;
      });

  void _onEvent(PushEvent event) {
    if (!mounted) return;
    if (event.fromTap) {
      routeForPush(event);
      final id = event.notificationId;
      if (id != null) _notifications.markRead(id);
    } else {
      refreshForPush(context, event);
    }
    _notifications.syncLatest();
  }

  void _sync({bool force = false}) {
    final user = _auth.currentUser;
    if (user == null) {
      activeRoleTracker.reset();
      _notifications.clear();
      _unregister();
      return;
    }
    final userType = activeRoleTracker.userTypeFor(_auth);
    _notifications.bind(userId: user.userId, userType: userType);
    _register(user.userId, userType, force: force);
  }

  Future<void> _register(int userId, String userType,
      {bool force = false}) async {
    // AuthProvider notifies often (loading flags etc.); skip the work when
    // this user/role is already registered with the current token.
    if (!force && _registeredKey == '$userId:$userType:$_registeredToken') {
      return;
    }
    try {
      if (!_permissionAsked) {
        _permissionAsked = true;
        await _push.requestPermission();
      }
      final token = await _push.getToken();
      if (token == null || !mounted) return;
      final key = '$userId:$userType:$token';
      if (!force && key == _registeredKey) return;
      await _repository.registerToken(
          userId: userId,
          userType: userType,
          deviceToken: token,
          platform: _push.platform);
      _registeredKey = key;
      _registeredToken = token;
    } catch (e) {
      debugPrint('Push token registration failed: $e');
    }
  }

  Future<void> _unregister() async {
    final token = _registeredToken;
    _registeredKey = null;
    _registeredToken = null;
    if (token == null) return;
    try {
      await _repository.unregisterToken(token);
    } catch (e) {
      debugPrint('Push token unregister failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notifications.syncLatest();
      updateBlock.syncFromStore().then((_) => _pullRelease());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_sync);
    activeRoleTracker.removeListener(_sync);
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
