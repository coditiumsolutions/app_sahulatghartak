import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  static const routeName = '/provider/chat';
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final threads = context.watch<ProviderDashboardProvider>().chatThreads;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat'), backgroundColor: kPrimaryColor),
      body: threads.isEmpty
          ? const Center(child: Text('No conversations yet.'))
          : ListView.separated(
              itemCount: threads.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final thread = threads[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: kPrimaryColor, child: Text(thread.customerName[0], style: const TextStyle(color: Colors.white))),
                  title: Text(thread.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(thread.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('hh:mm a').format(thread.lastMessageTime), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      if (thread.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('${thread.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatDetailScreen(threadId: thread.id))),
                );
              },
            ),
    );
  }
}
