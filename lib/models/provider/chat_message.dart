enum MessageType { text, image, location }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final bool isMe;
  final DateTime time;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.isMe,
    required this.time,
  });
}

class ChatThread {
  final String id;
  final String customerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<ChatMessage> messages;

  const ChatThread({
    required this.id,
    required this.customerName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.messages,
  });
}
