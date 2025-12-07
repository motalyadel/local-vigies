// presentation/pages/chat/vendor_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:legumes_app/data/models/product_model.dart';
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

      final List<types.Message> loaded = [];

      for (var msg in response) {
        final text = (msg['text'] as String?)?.trim() ?? '[Message vide]';
        final createdAt = DateTime.tryParse(msg['created_at'] as String? ?? '')
                ?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;

        final isFromVendor = msg['sender_type'] == 'vendor';

        loaded.add(types.TextMessage(
          author: isFromVendor ? _vendor : _consumer,
          createdAt: createdAt,
          id: msg['id'].toString(),
          text: text,
        ));
      }

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
        .stream(primaryKey: ['id'])
        .eq('consumer_id', widget.consumerId)
        // .eq('vendor_id', _vendor.id)
        .listen((_) {
          _loadMessages();
          _markMessagesAsRead(); // Re-marque au cas où
        });
  }

  void _handleSendPressed(types.PartialText message) async {
    if (message.text.trim().isEmpty) return;

    final tempMessage = types.TextMessage(
      author: _vendor,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message.text.trim(),
    );

    setState(() {
      _messages = [tempMessage, ..._messages];
    });

    try {
      await Supabase.instance.client.from('messages').insert({
        'text': message.text.trim(),
        'sender_type': 'vendor',
        'vendor_id': _vendor.id,
        'consumer_id': widget.consumerId,
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == tempMessage.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Échec de l'envoi"), backgroundColor: Colors.red),
        );
      }
    }
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
      debugPrint("Erreur marquage comme lu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
              "Tél: ${widget.consumerPhone}",
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _messages.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Aucun message", style: TextStyle(fontSize: 18)),
                  Text("Commencez la conversation !",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Chat(
              messages: _messages,
              onSendPressed: _handleSendPressed,
              user: _vendor,
              theme: const DefaultChatTheme(
                primaryColor: Colors.green,
                inputBackgroundColor: Colors.green,
                sentMessageBodyTextStyle: TextStyle(color: Colors.white),
                receivedMessageBodyTextStyle: TextStyle(color: Colors.black87),
                backgroundColor: Color(0xFFF1F3F5),
              ),
              showUserAvatars: true,
              showUserNames: true,
            ),
    );
  }
}
