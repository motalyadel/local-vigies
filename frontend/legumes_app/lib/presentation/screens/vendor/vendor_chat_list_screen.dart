// presentation/pages/chat/vendor_chat_list_screen.dart

import 'package:flutter/material.dart';
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

  // Marque comme lu + force le refresh immédiat
  Future<void> _markAsReadAndRefresh(String consumerId) async {
    await Supabase.instance.client
        .from('messages')
        .update({'read': true})
        .eq('consumer_id', consumerId)
        .eq('vendor_id', _vendorId)
        .eq('sender_type', 'consumer')
        .eq('read', false);

    // Force le rebuild immédiat → badge disparaît tout de suite
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return _buildEmptyState();
          }

          final conversations = _buildConversations(messages);
          final consumerIds = conversations.keys.toList();

          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: _fetchConsumers(consumerIds),
            builder: (context, consumerSnapshot) {
              final consumerMap = consumerSnapshot.data ?? {};

              // Liste triée par date du dernier message
              final sortedList = conversations.entries.map((e) {
                final consumerId = e.key;
                final conv = e.value;
                final consumer = consumerMap[consumerId];

                return {
                  'consumer_id': consumerId,
                  'name': consumer?['name'] ?? 'Client inconnu',
                  'phone': consumer?['phone'] ?? '',
                  'last_message': conv.lastMessage,
                  'last_time': conv.lastTime,
                  'unread_count': conv.unreadCount,
                };
              }).toList()
                ..sort((a, b) => DateTime.parse(b['last_time'] as String)
                    .compareTo(DateTime.parse(a['last_time'] as String)));

              return ListView.separated(
                itemCount: sortedList.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 80),
                itemBuilder: (context, index) {
                  final item = sortedList[index];
                  final unread = item['unread_count'] as int;
                  final hasUnread = unread > 0;
                  final lastMsg = item['last_message'] as String;
                  final isYou = lastMsg.startsWith("Vous :");

                  return InkWell(
                    onTap: () async {
                      // 1. Marque comme lu → badge disparaît tout de suite
                      await _markAsReadAndRefresh(
                          item['consumer_id'] as String);

                      // 2. Ouvre le chat
                      if (!mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendorChatScreen(
                            consumerId: item['consumer_id'] as String,
                            consumerName: item['name'] as String,
                            consumerPhone: item['phone'] as String,
                          ),
                        ),
                      );

                      // 3. Refresh au retour (nouveau message envoyé ?)
                      if (mounted) setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: hasUnread
                                ? Colors.green.shade700
                                : Colors.green.shade600,
                            child: Text(
                              (item['name'] as String).isNotEmpty
                                  ? (item['name'] as String)[0].toUpperCase()
                                  : "C",
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Nom + dernier message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] as String,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    if (isYou)
                                      const Icon(Icons.done_all,
                                          size: 17, color: Colors.blue),
                                    if (isYou) const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        lastMsg,
                                        style: TextStyle(
                                          fontSize: 14.2,
                                          color: hasUnread
                                              ? Colors.black87
                                              : (isYou
                                                  ? Colors.green.shade700
                                                  : Colors.grey.shade600),
                                          fontWeight: hasUnread
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Heure + badge
                          Column(
                            children: [
                              Text(
                                _formatTime(item['last_time'] as String),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasUnread
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                  fontWeight:
                                      hasUnread ? FontWeight.bold : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (hasUnread)
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  constraints:
                                      const BoxConstraints(minWidth: 24),
                                  child: Text(
                                    unread > 99 ? "99+" : unread.toString(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // TRAITE TOUS LES MESSAGES (client ET vendeur)
  Map<String, _Conversation> _buildConversations(
      List<Map<String, dynamic>> messages) {
    final map = <String, _Conversation>{};

    for (final msg in messages) {
      final consumerId = msg['consumer_id'] as String?;
      if (consumerId == null) continue;

      final isFromVendor = msg['sender_type'] == 'vendor';
      final isRead = msg['read'] == true;
      final text = (msg['text'] as String?)?.trim() ?? '';
      final displayText = text.isEmpty ? "Photo" : text;
      final finalText = isFromVendor ? "Vous : $displayText" : displayText;
      final time = msg['created_at'] as String;

      if (!map.containsKey(consumerId)) {
        map[consumerId] = _Conversation(
          lastMessage: finalText,
          lastTime: time,
          unreadCount: isFromVendor || isRead ? 0 : 1,
        );
      } else {
        final conv = map[consumerId]!;
        conv.lastMessage = finalText;
        conv.lastTime = time;
        if (!isFromVendor && !isRead) {
          conv.unreadCount += 1;
        }
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
    final date = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(date.year, date.month, date.day);

    if (msgDay == today) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    if (msgDay == today.subtract(const Duration(days: 1))) return "Hier";
    return "${date.day}/${date.month}";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 90, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text("Aucune conversation",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("Les messages de vos clients apparaîtront ici",
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _Conversation {
  String lastMessage;
  String lastTime;
  int unreadCount = 0;

  _Conversation(
      {required this.lastMessage,
      required this.lastTime,
      int unreadCount = 0}) {
    this.unreadCount = unreadCount;
  }
}
