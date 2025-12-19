// lib/presentation/providers/notification_controller.dart

import 'package:flutter/foundation.dart';
import 'package:legumes_app/core/services/unread_messages_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationController extends ChangeNotifier {
  int _unreadMessages = 0;
  int _pendingRequests = 0;
  bool _loading = false;

  int get unreadMessages => _unreadMessages;
  int get pendingRequests => _pendingRequests;
  bool get loading => _loading;

  final SupabaseClient _client = Supabase.instance.client;

  NotificationController() {
    // Écoute les changements d'authentification
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Nouvel utilisateur connecté → recharge les notifications
        loadNotifications();
      } else if (event == AuthChangeEvent.signedOut) {
        // Déconnexion → remet à zéro
        _unreadMessages = 0;
        _pendingRequests = 0;
        notifyListeners();
      }
    });

    // Charge au démarrage si déjà connecté
    if (_client.auth.currentUser != null) {
      loadNotifications();
    }
  }

  Future<void> loadNotifications() async {
    if (_client.auth.currentUser == null) {
      _unreadMessages = 0;
      _pendingRequests = 0;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        UnreadMessagesService.getUnreadCountForVendor(),
        _getPendingRequestsCount(),
      ]);

      _unreadMessages = results[0] as int;
      _pendingRequests = results[1] as int;
    } catch (e) {
      print("Erreur chargement notifications: $e");
      _unreadMessages = 0;
      _pendingRequests = 0;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> _getPendingRequestsCount() async {
    final vendorId = _client.auth.currentUser?.id;
    if (vendorId == null) return 0;

    try {
      final response = await _client
          .from('product_requests')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('status', 'pending');

      return response.length;
    } catch (e) {
      print("Erreur comptage demandes pending: $e");
      return 0;
    }
  }

  Future<void> refresh() => loadNotifications();
}