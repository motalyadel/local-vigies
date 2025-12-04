// presentation/pages/vendor/vendor_requests_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorRequestsPage extends StatefulWidget {
  const VendorRequestsPage({super.key});

  @override
  State<VendorRequestsPage> createState() => _VendorRequestsPageState();
}

class _VendorRequestsPageState extends State<VendorRequestsPage> {
  late final Stream<List<Map<String, dynamic>>> _requestsStream;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser!.id;
    _requestsStream = Supabase.instance.client
        .from('product_requests')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', userId)
        .order('created_at', ascending: false);
  }

  void forceRefresh() {
    setState(() {}); // Force rebuild complet → recalcule tout
  }

  Future<Map<String, Map<String, dynamic>>> _getConsumersMap() async {
    try {
      final vendorId = Supabase.instance.client.auth.currentUser!.id;
      final requests = await Supabase.instance.client
          .from('product_requests')
          .select('consumer_id')
          .eq('vendor_id', vendorId);

      if (requests.isEmpty) return {};

      final consumerIds = (requests as List)
          .map((r) => r['consumer_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      if (consumerIds.isEmpty) return {};

      final consumers = await Supabase.instance.client
          .from('consumers')
          .select('id, name, phone')
          .inFilter('id', consumerIds);

      return {
        for (var c in consumers) c['id'] as String: c as Map<String, dynamic>
      };
    } catch (e) {
      print("Erreur chargement consommateurs: $e");
      return {};
    }
  }

  Future<void> _updateStatus(String requestId, String status) async {
    await Supabase.instance.client.from('product_requests').update({
      'status': status,
      'responded_at': DateTime.now().toIso8601String()
    }).eq('id', requestId);
  }

  void _callClient(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Color _getStatusColor(String? status) => switch (status) {
        'accepted' => Colors.green,
        'rejected' => Colors.red,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes demandes"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(
              child: Text("Aucune demande pour le moment",
                  style: TextStyle(fontSize: 18)),
            );
          }

          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            future: _getConsumersMap(),
            builder: (context, consumerSnapshot) {
              final consumerMap = consumerSnapshot.data ?? {};

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: requests.length,
                itemBuilder: (_, i) {
                  final r = requests[i];
                  final consumerId = r['consumer_id'] as String?;
                  final consumerData =
                      consumerId != null ? consumerMap[consumerId] : null;

                  final String clientName =
                      consumerData?['name'] ?? 'Client inconnu';
                  final String clientPhone =
                      consumerData?['phone'] ?? 'Non disponible';

                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PRODUIT
                          Text(
                            r['product_name'] ?? 'Produit',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              "${r['quantity']} kg • ${r['price_at_request']} MRU/kg",
                              style: const TextStyle(fontSize: 15)),

                          const SizedBox(height: 12),

                          // CLIENT
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  clientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => _callClient(clientPhone),
                            child: Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  clientPhone,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                              "Adresse: ${r['customer_location'] ?? 'Non précisée'}",
                              style: const TextStyle(fontSize: 14)),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // BOUTON CHAT

                              // BOUTONS ACCEPTER/REFUSER
                              if (r['status'] == 'pending')
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text("Accepter"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: () =>
                                          _updateStatus(r['id'], 'accepted'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text("Refuser"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: () =>
                                          _updateStatus(r['id'], 'rejected'),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // STATUT + DATE
                          Row(
                            children: [
                              Chip(
                                backgroundColor: _getStatusColor(r['status']),
                                label: Text(
                                  (r['status'] ?? 'en attente')
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.chat_bubble, size: 18),
                                label: const Text("Chat"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VendorChatScreen(
                                        consumerId: consumerId!,
                                        consumerName: clientName,
                                        consumerPhone: clientPhone,
                                        onMessagesRead:
                                            forceRefresh, // ← NOUVEAU
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const Spacer(),
                              Text(
                                DateTime.parse(r['created_at'])
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // BOUTONS : CHAT + ACCEPTER/REFUSER
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
}
