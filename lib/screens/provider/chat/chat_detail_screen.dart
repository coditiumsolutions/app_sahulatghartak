import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/chat_message.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

class ChatDetailScreen extends StatefulWidget {
  final String threadId;
  const ChatDetailScreen({super.key, required this.threadId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context, {String? text, MessageType type = MessageType.text}) {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty) return;
    context.read<ProviderDashboardProvider>().sendChatMessage(widget.threadId, messageText, type: type);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final thread = dashboard.chatThreads.firstWhere((t) => t.id == widget.threadId);

    return Scaffold(
      appBar: AppBar(title: Text(thread.customerName), backgroundColor: kPrimaryColor),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: thread.messages.length,
              itemBuilder: (context, index) {
                final message = thread.messages[thread.messages.length - 1 - index];
                return Align(
                  alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: message.isMe ? kPrimaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (message.type == MessageType.image) Icon(Icons.image, size: 16, color: message.isMe ? Colors.white : Colors.black87),
                            if (message.type == MessageType.location) Icon(Icons.location_on, size: 16, color: message.isMe ? Colors.white : Colors.black87),
                            if (message.type != MessageType.text) const SizedBox(width: 4),
                            Flexible(child: Text(message.text, style: TextStyle(color: message.isMe ? Colors.white : Colors.black87))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('hh:mm a').format(message.time), style: TextStyle(color: message.isMe ? Colors.white70 : Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.image, color: kPrimaryColor), onPressed: () => _send(context, text: '📷 Photo', type: MessageType.image)),
                  IconButton(icon: const Icon(Icons.location_on, color: kPrimaryColor), onPressed: () => _send(context, text: '📍 Location shared', type: MessageType.location)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: 'Type a message', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
                      onSubmitted: (_) => _send(context),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send, color: kPrimaryColor), onPressed: () => _send(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
