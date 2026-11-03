import 'package:flutter/material.dart';
import '../widgets/frosted_icon_button.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../models/push_event.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';
import '../utils/date_time_formatter.dart';
import '../utils/notification_router.dart';
import '../utils/provider_routes.dart';
import '../widgets/provider/provider_tab_header.dart';

/// Shared notification inbox for both roles; shows the active role's inbox
/// (see [NotificationProvider.bind]).
class NotificationsScreen extends StatefulWidget {
  static const routeName = ProviderRoutes.notifications;
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().loadInbox();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  void _open(AppNotification n) {
    context.read<NotificationProvider>().markRead(n.id);
    routeForPush(PushEvent(
      type: n.type,
      screen: n.screen,
      bookingId: n.bookingUid,
      requestId: n.requestUid,
      notificationId: n.id,
      fromTap: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'Notifications',
        subtitle: provider.unreadCount > 0
            ? '${provider.unreadCount} unread'
            : 'You are all caught up',
        leading: FrostedBackButton(onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: provider.unreadCount > 0
            ? FrostedSurface(
                onTap: provider.markAllRead,
                child: const Text('Mark all read',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              )
            : null,
      ),
      body: _body(provider),
    );
  }

  Widget _body(NotificationProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.items.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load notifications',
        subtitle: provider.error!,
        action: TextButton(
            onPressed: provider.loadInbox, child: const Text('Retry')),
      );
    }
    if (provider.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadInbox,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _Message(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle:
                  'Updates on your requests and bookings will show up here.',
            ),
          ],
        ),
      );
    }

    final items = provider.items;
    return RefreshIndicator(
      onRefresh: provider.loadInbox,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length + (provider.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()));
          }
          return _NotificationTile(
              notification: items[i], onTap: () => _open(items[i]));
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  static IconData _icon(String type) => switch (type) {
        'job_assigned' => Icons.work_outline_rounded,
        'booking_accepted' => Icons.check_circle_outline_rounded,
        'job_unavailable' => Icons.block_rounded,
        'provider_reassigning' => Icons.sync_rounded,
        'booking_cancelled' => Icons.cancel_outlined,
        'job_started' => Icons.play_circle_outline_rounded,
        'job_completed' => Icons.task_alt_rounded,
        'app_update' => Icons.system_update_rounded,
        _ => Icons.notifications_none_rounded,
      };

  /// Colour-codes by meaning: new work blue, success green, in progress teal,
  /// attention amber, negative red.
  static Color _color(String type) => switch (type) {
        'job_assigned' => providerBrandBlue,
        'booking_accepted' || 'job_completed' => const Color(0xFF16A34A),
        'job_started' => const Color(0xFF0D9488),
        'provider_reassigning' => const Color(0xFFD97706),
        'booking_cancelled' || 'job_unavailable' => const Color(0xFFDC2626),
        'app_update' => const Color(0xFF7C3AED),
        _ => providerBrandBlue,
      };

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final color = _color(notification.type);
    final radius = BorderRadius.circular(16);

    return Material(
      color: unread
          ? Color.alphaBlend(color.withValues(alpha: 0.09), Colors.white)
          : Colors.white,
      elevation: unread ? 2 : 0,
      shadowColor: color.withValues(alpha: 0.35),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
                color: unread
                    ? color.withValues(alpha: 0.45)
                    : const Color(0xFFE6EBF2)),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                      width: 5, color: unread ? color : Colors.transparent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                                color: unread
                                    ? color
                                    : color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(_icon(notification.type),
                                color: unread
                                    ? Colors.white
                                    : color.withValues(alpha: 0.7),
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Titles may begin with an emoji; plain Text
                                    // renders it, so show it exactly as received.
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                            fontSize: 14.5,
                                            height: 1.3,
                                            fontWeight: unread
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: unread
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF475569)),
                                      ),
                                    ),
                                    if (unread)
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 8, top: 1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: color,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: const Text('NEW',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(notification.body,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: unread
                                            ? const Color(0xFF334155)
                                            : Colors.grey[600],
                                        height: 1.35)),
                                const SizedBox(height: 6),
                                Text(
                                  // createdAt is UTC; formatLocalDateTime
                                  // converts to the device's local time.
                                  formatLocalDateTime(
                                      notification.createdAt, kDatePattern,
                                      includeTime: true),
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: unread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: unread ? color : Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  const _Message(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: kPrimaryColor),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2233))),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, color: Colors.grey[600], height: 1.4)),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
