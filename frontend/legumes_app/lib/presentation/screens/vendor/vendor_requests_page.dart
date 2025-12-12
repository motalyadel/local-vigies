// presentation/pages/vendor/vendor_requests_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorRequestsPage extends StatefulWidget {
  const VendorRequestsPage({super.key});

  @override
  State<VendorRequestsPage> createState() => _VendorRequestsPageState();
}

class _VendorRequestsPageState extends State<VendorRequestsPage> {
  // ON NE MET PLUS "late" → on initialise directement
  Stream<List<Map<String, dynamic>>> get _requestsStream {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const Stream.empty();
    }

    return Supabase.instance.client
        .from('product_requests')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((request) {
            // Récupère les données du consommateur joint (si Supabase le fait)
            final consumer = request['consumer'] as Map<String, dynamic>?;

            return {
              ...request,
              'consumer_name': consumer?['name'] ?? 'Client inconnu',
              'consumer_phone': consumer?['phone'] ?? 'Non disponible',
            };
          }).toList();
        });
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
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  void _callClient(String? phone) async {
    if (phone == null || phone == 'Non disponible') return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Color _getStatusColor(String? status) => switch (status) {
        'accepted' => Colors.green,
        'rejected' => Colors.red,
        _ => Colors.orange,
      };

  String _getStatusText(String? status, AppLocalizations l10n) =>
      switch (status) {
        'accepted' => l10n.statusAccepted,
        'rejected' => l10n.statusRejected,
        _ => l10n.statusPending,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          title: Text(l10n.myRequests),
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
              return Center(
                  child: Text("${l10n.errorOccurred}: ${snapshot.error}"));
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(l10n.noRequestsYet,
                        style: const TextStyle(fontSize: 18)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              itemBuilder: (context, i) {
                final r = requests[i];
                final String clientName = r['consumer_name'] as String;
                final String clientPhone = r['consumer_phone'] as String;
                final String status = r['status'] as String? ?? 'pending';

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
                        Text(r['product_name'] ?? 'Produit',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(
                            "${r['quantity']} kg • ${r['price_at_request']} MRU/kg"),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(clientName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                        GestureDetector(
                          onTap: () => _callClient(clientPhone),
                          child: Row(children: [
                            const Icon(Icons.phone, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(clientPhone,
                                style: const TextStyle(
                                    color: Colors.green,
                                    decoration: TextDecoration.underline)),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                            "Adresse: ${r['customer_location'] ?? 'Non précisée'}"),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              backgroundColor: _getStatusColor(status),
                              label: Text(_getStatusText(status, l10n),
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            Text(
                                DateFormat('dd/MM HH:mm')
                                    .format(DateTime.parse(r['created_at'])),
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (status == 'pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check, size: 16),
                                label: Text(l10n.accept),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                                onPressed: () =>
                                    _updateStatus(r['id'], 'accepted'),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.close, size: 16),
                                label: Text(l10n.reject),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () =>
                                    _updateStatus(r['id'], 'rejected'),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble),
                            label: Text(l10n.chat),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VendorChatScreen(
                                    consumerId: r['consumer_id'],
                                    consumerName: clientName,
                                    consumerPhone: clientPhone,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}
