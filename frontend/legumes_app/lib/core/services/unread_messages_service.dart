// lib/core/services/unread_messages_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class UnreadMessagesService {
  static Future<int> getUnreadCountForVendor() async {
    try {
      final vendorId = Supabase.instance.client.auth.currentUser?.id;
      if (vendorId == null) return 0;

      final response = await Supabase.instance.client
          .from('messages')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('sender_type', 'consumer')
          .eq('read', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Pour le consommateur (si tu veux plus tard)
  static Future<int> getUnreadCountForConsumer(String consumerId) async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('id')
          .eq('consumer_id', consumerId)
          .eq('sender_type', 'vendor')
          .eq('read', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }
}