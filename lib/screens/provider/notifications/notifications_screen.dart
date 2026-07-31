import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/notification_item.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/provider/notifications';
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.newRequest:
        return Icons.inbox;
      case NotificationType.quoteAccepted:
        return Icons.check_circle;
      case NotificationType.paymentReceived:
        return Icons.attach_money;
      case NotificationType.accountVerified:
        return Icons.verified;
      case NotificationType.system:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final notifications = dashboard.notifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: kPrimaryColor),
      body: notifications.isEmpty
          ? const Center(child: Text('No notifications.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  color: notification.isRead ? null : kPrimaryColor.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: kPrimaryColor.withValues(alpha: 0.15), child: Icon(_iconFor(notification.type), color: kPrimaryColor)),
                    title: Text(notification.type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(notification.message),
                    trailing: Text(DateFormat('hh:mm a').format(notification.time), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    onTap: () => dashboard.markNotificationRead(notification.id),
                  ),
                );
              },
            ),
    );
  }
}
