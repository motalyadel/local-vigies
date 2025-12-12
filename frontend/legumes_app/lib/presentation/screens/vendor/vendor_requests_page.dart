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
  // Stream avec jointure manuelle du consommateur (nom + téléphone)
  Stream<List<Map<String, dynamic>>> get _requestsStream {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return Supabase.instance.client
        .from('product_requests')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((requests) async {
          final consumerIds = requests
              .map((r) => r['consumer_id'] as String?)
              .where((id) => id != null)
              .toSet()
              .toList();

          Map<String, Map<String, dynamic>> consumerMap = {};

          if (consumerIds.isNotEmpty) {
            final consumersResponse = await Supabase.instance.client
                .from('consumers')
                .select('id, name, phone')
                .inFilter('id', consumerIds);

            consumerMap = {
              for (var c in consumersResponse)
                c['id'] as String: c as Map<String, dynamic>
            };
          }

          return requests.map((r) {
            final consumerId = r['consumer_id'] as String?;
            final consumerData =
                consumerId != null ? consumerMap[consumerId] : null;

            return {
              ...r,
              'consumer_name': consumerData?['name'] ?? 'Client inconnu',
              'consumer_phone': consumerData?['phone'] ?? 'Non disponible',
            };
          }).toList();
        });
  }

  Future<void> _updateStatus(String requestId, String status) async {
    await Supabase.instance.client.from('product_requests').update({
      'status': status,
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  void _callClient(String? phone) async {
    if (phone == null || phone == 'Non disponible' || phone.isEmpty) return;
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
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
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
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
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
                      Row(children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(clientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ]),
                      GestureDetector(
                        onTap: () => _callClient(clientPhone),
                        child: Row(children: [
                          const Icon(Icons.phone, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(clientPhone,
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  fontSize: 15)),
                        ]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.addressLabel(
                            r['customer_location'] ?? l10n.notSpecified),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      // STATUT + DATE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            backgroundColor: _getStatusColor(status),
                            label: Text(_getStatusText(status, l10n),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble, size: 18),
                            label: Text(l10n.chat),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
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
                          const Spacer(),
                          Text(
                            DateFormat('dd/MM HH:mm')
                                .format(DateTime.parse(r['created_at'])),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // BOUTONS ACCEPTER / REFUSER
                      if (status == 'pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 16),
                              label: Text(l10n.accept),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () =>
                                  _updateStatus(r['id'], 'accepted'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.close, size: 16),
                              label: Text(l10n.reject),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () =>
                                  _updateStatus(r['id'], 'rejected'),
                            ),
                          ],
                        ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
