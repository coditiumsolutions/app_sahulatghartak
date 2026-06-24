enum NotificationType { newRequest, quoteAccepted, paymentReceived, accountVerified, system }

extension NotificationTypeX on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.newRequest:
        return 'New Request';
      case NotificationType.quoteAccepted:
        return 'Quote Accepted';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.accountVerified:
        return 'Account Verified';
      case NotificationType.system:
        return 'System Notification';
    }
  }
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String message;
  final DateTime time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}
