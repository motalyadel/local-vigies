import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';

class VendorChatScreen extends StatefulWidget {
  final String consumerId;
  final String consumerName;
  final String consumerPhone;

  const VendorChatScreen({
    super.key,
    required this.consumerId,
    required this.consumerName,
    required this.consumerPhone,
  });

  @override
  State<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends State<VendorChatScreen> {
  final List<types.Message> _messages = [];

  late final types.User _vendor;
  late final types.User _consumer;

  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();

    final userId = Supabase.instance.client.auth.currentUser!.id;

    _vendor = types.User(id: userId);
    _consumer = types.User(
      id: widget.consumerId,
      firstName: widget.consumerName,
      metadata: {'phone': widget.consumerPhone},
    );

    _loadMessages();
    _subscribeRealtime();
  }

  // ---------------------------
  // LOAD HISTORY
  // ---------------------------
  Future<void> _loadMessages() async {
    final data = await Supabase.instance.client
        .from('messages')
        .select()
        .eq('vendor_id', _vendor.id)
        .eq('consumer_id', widget.consumerId)
        .order('created_at', ascending: true);

    final messages = data.map<types.TextMessage>(_mapRowToMessage).toList();

    if (mounted) {
      setState(() {
        _messages
          ..clear()
          ..addAll(messages.reversed);
      });
    }

    _markMessagesAsRead();
  }

  // ---------------------------
  // REALTIME
  // ---------------------------
  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('chat_${_vendor.id}_${widget.consumerId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final msg = payload.newRecord;

            if (!_isForThisChat(msg)) return;

            final newMessage = _mapRowToMessage(msg);

            if (mounted) {
              setState(() {
                _messages.insert(0, newMessage);
              });
            }

            if (msg['sender_type'] == 'consumer') {
              _markMessagesAsRead();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final msg = payload.newRecord;

            if (!_isForThisChat(msg)) return;

            final index = _messages.indexWhere(
              (m) => m.id == msg['id'].toString(),
            );

            if (index != -1 && mounted) {
              setState(() {
                _messages[index] =
                    (_messages[index] as types.TextMessage).copyWith(
                  status: types.Status.seen,
                );
              });
            }
          },
        )
        .subscribe();
  }

  bool _isForThisChat(Map<String, dynamic> msg) {
    return msg['vendor_id'] == _vendor.id &&
        msg['consumer_id'] == widget.consumerId;
  }

  // ---------------------------
  // SEND MESSAGE
  // ---------------------------
  Future<void> _handleSendPressed(types.PartialText message) async {
    await Supabase.instance.client.from('messages').insert({
      'text': message.text,
      'sender_type': 'vendor',
      'vendor_id': _vendor.id,
      'consumer_id': widget.consumerId,
      'read': false,
    });
  }

  // ---------------------------
  // MARK AS READ
  // ---------------------------
  Future<void> _markMessagesAsRead() async {
    await Supabase.instance.client
        .from('messages')
        .update({'read': true})
        .eq('vendor_id', _vendor.id)
        .eq('consumer_id', widget.consumerId)
        .eq('sender_type', 'consumer')
        .eq('read', false);
  }

  // ---------------------------
  // MAP DB → CHAT MESSAGE
  // ---------------------------
  types.TextMessage _mapRowToMessage(Map<String, dynamic> row) {
    final isVendor = row['sender_type'] == 'vendor';

    return types.TextMessage(
      id: row['id'].toString(),
      text: row['text'],
      author: isVendor ? _vendor : _consumer,
      createdAt: DateTime.parse(row['created_at']).millisecondsSinceEpoch,
      status: isVendor
          ? types.Status.sent
          : ((row['read'] ?? false)
              ? types.Status.seen
              : types.Status.delivered),
    );
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.consumerName),
              Text(
                '${l10n.phonePrefix}: ${widget.consumerPhone}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _vendor,
          theme: DefaultChatTheme(
            primaryColor: Colors.teal,
            inputBackgroundColor: Colors.white,
            inputTextColor: Colors.black87,
            sentMessageBodyTextStyle: const TextStyle(color: Colors.white),
            receivedMessageBodyTextStyle:
                const TextStyle(color: Colors.black87),
            backgroundColor: const Color(0xFFF1F3F5),
            inputMargin: const EdgeInsets.all(12),
            inputBorderRadius: BorderRadius.circular(30),
            inputElevation: 8,
            inputContainerDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          showUserAvatars: true,
          showUserNames: true,
          emptyState: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.noMessagesYet),
                Text(l10n.startConversation,
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
