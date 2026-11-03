import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_screen.dart';
import 'frosted_icon_button.dart';

/// Header bell with an unread badge that opens the inbox. Renders nothing for
/// guests (no session, so no inbox).
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.select<AuthProvider, bool>((a) => a.isLoggedIn)) {
      return const SizedBox.shrink();
    }
    final unread =
        context.select<NotificationProvider, int>((n) => n.unreadCount);

    return FrostedIconButton(
      tooltip: 'Notifications',
      onPressed: () =>
          Navigator.of(context).pushNamed(NotificationsScreen.routeName),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_none_rounded,
            color: Colors.white, size: 23),
      ),
    );
  }
}
