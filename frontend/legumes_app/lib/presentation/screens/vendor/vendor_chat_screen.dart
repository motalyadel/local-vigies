// presentation/pages/chat/vendor_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorChatScreen extends StatefulWidget {
  final String consumerId;
  final String consumerName;
  final String consumerPhone;
  final VoidCallback? onMessagesRead;

  const VendorChatScreen({
    super.key,
    required this.consumerId,
    required this.consumerName,
    required this.consumerPhone,
    this.onMessagesRead,
  });

  @override
  State<VendorChatScreen> createState() => _VendorChatScreenState();
}

class _VendorChatScreenState extends State<VendorChatScreen> {
  List<types.Message> _messages = [];
  late final types.User _vendor;
  late final types.User _consumer;

  @override
  void initState() {
    super.initState();
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    _vendor = types.User(id: currentUserId);
    _consumer = types.User(
      id: widget.consumerId,
      firstName: widget.consumerName,
      metadata: {'phone': widget.consumerPhone},
    );

    _markMessagesAsRead();
    _loadMessages();
    _listenToRealtime();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('vendor_id', _vendor.id)
          .eq('consumer_id', widget.consumerId)
          .order('created_at', ascending: true);

      final List<types.Message> loaded = response.map<types.TextMessage>((msg) {
        final isFromVendor = msg['sender_type'] == 'vendor';
        return types.TextMessage(
          author: isFromVendor ? _vendor : _consumer,
          createdAt: DateTime.parse(msg['created_at']).millisecondsSinceEpoch,
          id: msg['id'].toString(),
          text: msg['text'] as String,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _messages = loaded.reversed.toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement messages: $e");
    }
  }

  void _listenToRealtime() {
    Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id']).listen((data) {
      final filtered = data.where((msg) =>
          (msg['vendor_id'] == _vendor.id &&
              msg['consumer_id'] == widget.consumerId) ||
          (msg['consumer_id'] == widget.consumerId &&
              msg['vendor_id'] == _vendor.id));

      if (filtered.isNotEmpty) {
        _loadMessages();
        _markMessagesAsRead();
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'read': true})
          .eq('consumer_id', widget.consumerId)
          .eq('vendor_id', _vendor.id)
          .eq('sender_type', 'consumer')
          .eq('read', false);

      widget.onMessagesRead?.call();
    } catch (e) {
      debugPrint("Erreur marquage messages lus: $e");
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    final tempMessage = types.TextMessage(
      author: _vendor,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message.text,
    );

    setState(() {
      _messages = [tempMessage, ..._messages];
    });

    try {
      await Supabase.instance.client.from('messages').insert({
        'text': message.text,
        'sender_type': 'vendor',
        'vendor_id': _vendor.id,
        'consumer_id': widget.consumerId,
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.messageSendFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.consumerName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "${l10n.phonePrefix}: ${widget.consumerPhone}",
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.noMessagesYet,
                      style: const TextStyle(fontSize: 18)),
                  Text(l10n.startConversation,
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _vendor,
              theme: DefaultChatTheme(
                primaryColor: Colors.green,
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
    );
  }
}
