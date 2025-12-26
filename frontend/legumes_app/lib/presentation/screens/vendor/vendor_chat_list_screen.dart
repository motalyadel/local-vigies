// presentation/pages/chat/vendor_chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorChatListScreen extends StatefulWidget {
  const VendorChatListScreen({super.key});

  @override
  State<VendorChatListScreen> createState() => _VendorChatListScreenState();
}

class _VendorChatListScreenState extends State<VendorChatListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final String _vendorId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', _vendorId)
        .order('created_at', ascending: false);
  }

  void _refreshUnreadCount() {
    if (mounted) setState(() {});
  }

  Future<void> _markAsReadAndRefresh(String consumerId) async {
    await Supabase.instance.client
        .from('messages')
        .update({'read': true})
        .eq('consumer_id', consumerId)
        .eq('vendor_id', _vendorId)
        .eq('sender_type', 'consumer')
        .eq('read', false);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.messagesTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<Map<String, _Conversation>>(
          stream: _messagesStream
              .map((messages) => _groupMessagesByConsumer(messages)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.teal));
            }
      
            if (snapshot.hasError) {
              return Center(
                  child: Text("${l10n.errorOccurred}: ${snapshot.error}"));
            }
      
            final conversations = snapshot.data ?? {};
      
            if (conversations.isEmpty) {
              return _buildEmptyState(l10n);
            }
      
            return FutureBuilder<Map<String, Map<String, dynamic>>>(
              future: _fetchConsumers(conversations.keys.toList()),
              builder: (context, consumerSnapshot) {
                final consumerMap = consumerSnapshot.data ?? {};
      
                final sortedConversations = conversations.entries.toList()
                  ..sort((a, b) {
                    final timeA =
                        DateTime.tryParse(a.value.lastTime) ?? DateTime(1970);
                    final timeB =
                        DateTime.tryParse(b.value.lastTime) ?? DateTime(1970);
                    return timeB.compareTo(timeA);
                  });
      
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedConversations.length,
                  itemBuilder: (context, i) {
                    final entry = sortedConversations[i];
                    final consumerId = entry.key;
                    final conv = entry.value;
                    final consumerData = consumerMap[consumerId];
      
                    final String clientName =
                        consumerData?['name'] ?? l10n.unknownClient;
                    final String clientPhone = consumerData?['phone'] ?? '';
      
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            clientName.isNotEmpty
                                ? clientName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                        title: Text(
                          clientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        subtitle: Text(
                          conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(conv.lastTime),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            if (conv.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  conv.unreadCount > 99
                                      ? '99+'
                                      : conv.unreadCount.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          await _markAsReadAndRefresh(consumerId);
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VendorChatScreen(
                                consumerId: consumerId,
                                consumerName: clientName,
                                consumerPhone: clientPhone,
                                // onMessagesRead: _refreshUnreadCount,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 90, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(l10n.noConversations,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(l10n.messagesWillAppearHere,
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Map<String, _Conversation> _groupMessagesByConsumer(
      List<Map<String, dynamic>> messages) {
    final Map<String, _Conversation> map = {};

    for (final msg in messages) {
      final consumerId = msg['consumer_id'] as String;
      final isFromVendor = msg['sender_type'] == 'vendor';
      final isRead = msg['read'] as bool? ?? true;
      final text = msg['text'] as String;
      final time = msg['created_at'] as String;

      final displayText = isFromVendor
          ? "${AppLocalizations.of(context)!.youPrefix} $text"
          : text;

      map.putIfAbsent(
        consumerId,
        () => _Conversation(lastMessage: displayText, lastTime: time),
      );

      final conv = map[consumerId]!;
      final messageDate = DateTime.parse(time);

      if (DateTime.parse(conv.lastTime).isBefore(messageDate)) {
        conv.lastMessage = displayText;
        conv.lastTime = time;
      }

      if (!isFromVendor && !isRead) {
        conv.unreadCount += 1;
      }
    }

    return map;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchConsumers(
      List<String> ids) async {
    if (ids.isEmpty) return {};
    final res = await Supabase.instance.client
        .from('consumers')
        .select('id, name, phone')
        .inFilter('id', ids);
    return {for (var c in res) c['id'] as String: c};
  }

  String _formatTime(String iso) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);

    if (msgDay == today) {
      return DateFormat('HH:mm').format(date);
    }
    if (msgDay == today.subtract(const Duration(days: 1)))
      return l10n.yesterday;
    return DateFormat('dd/MM').format(date);
  }
}

class _Conversation {
  String lastMessage;
  String lastTime;
  int unreadCount = 0;

  _Conversation({
    required this.lastMessage,
    required this.lastTime,
  });
}
