// presentation/pages/vendor/vendor_requests_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VendorRequestsPage extends StatefulWidget {
  const VendorRequestsPage({super.key});

  @override
  State<VendorRequestsPage> createState() => _VendorRequestsPageState();
}

class _VendorRequestsPageState extends State<VendorRequestsPage> {
  Stream<List<Map<String, dynamic>>> get _requestsStream {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return Supabase.instance.client
        .from('product_requests')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((requests) async {
          // 1. Récupérer tous les product_id uniques
          final productIds = requests
              .map((r) => r['product_id'] as String?)
              .where((id) => id != null)
              .toSet()
              .toList();

          // 2. Récupérer toutes les photos en UNE SEULE requête
          Map<String, String?> productImages = {};
          if (productIds.isNotEmpty) {
            final productsResponse = await Supabase.instance.client
                .from('products')
                .select('id, image_url')
                .inFilter('id', productIds);

            productImages = {
              for (var p in productsResponse)
                p['id'] as String: p['image_url'] as String?
            };
          }

          // 3. Récupérer les infos clients (comme avant)
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

          // 4. Joindre tout
          return requests.map((r) {
            final consumerId = r['consumer_id'] as String?;
            final consumerData =
                consumerId != null ? consumerMap[consumerId] : null;

            final productId = r['product_id'] as String?;
            final productImage =
                productId != null ? productImages[productId] : null;

            return {
              ...r,
              'consumer_name': consumerData?['name'] ?? 'Client inconnu',
              'consumer_phone': consumerData?['phone'] ?? 'Non disponible',
              'product_image_url': productImage,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.myRequests,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Colors.teal, strokeWidth: 5));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 100, color: Colors.red[300]),
                    const SizedBox(height: 24),
                    Text(l10n.errorOccurred,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text("${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 120, color: Colors.grey[400]),
                    const SizedBox(height: 32),
                    Text(l10n.noRequestsYet,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                    const SizedBox(height: 16),
                    Text("Vos clients vous contacteront bientôt !",
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: requests.length,
            itemBuilder: (context, i) {
              final r = requests[i];
              final String clientName = r['consumer_name'] as String;
              final String clientPhone = r['consumer_phone'] as String;
              final String status = r['status'] as String? ?? 'pending';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Produit
                      Row(
                        children: [
                          // Photo du produit demandé (si disponible dans la table products)
                          // Photo du produit (préchargée, pas de FutureBuilder)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: r['product_image_url'] != null &&
                                    (r['product_image_url'] as String)
                                        .isNotEmpty
                                ? Image.network(
                                    r['product_image_url'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.teal),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                          Icons.shopping_bag_rounded,
                                          size: 32,
                                          color: Colors.teal),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                        Icons.shopping_bag_rounded,
                                        size: 32,
                                        color: Colors.teal),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['product_name'] ?? 'Produit',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(
                                    "${r['quantity']} kg • ${r['price_at_request']} MRU/kg",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Client
                      Row(children: [
                        const Icon(Icons.person_rounded,
                            size: 28, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(clientName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
                      ]),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _callClient(clientPhone),
                        child: Row(children: [
                          const Icon(Icons.phone_rounded,
                              size: 26, color: Colors.green),
                          const SizedBox(width: 12),
                          Text(clientPhone,
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline)),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            size: 26, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                l10n.addressLabel(r['customer_location'] ??
                                    l10n.notSpecified),
                                style: const TextStyle(fontSize: 15))),
                      ]),
                      const SizedBox(height: 24),

                      // Statut + Date + Bouton Chat
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
                          Text(
                              DateFormat('dd MMM HH:mm')
                                  .format(DateTime.parse(r['created_at'])),
                              style: TextStyle(color: Colors.grey[600])),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.chat_rounded, size: 20),
                            label: Text(l10n.chat),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20))),
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
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Boutons Accepter / Refuser
                      if (status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_rounded),
                                label: Text(l10n.accept,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20))),
                                onPressed: () =>
                                    _updateStatus(r['id'], 'accepted'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.cancel_rounded),
                                label: Text(l10n.reject,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20))),
                                onPressed: () =>
                                    _updateStatus(r['id'], 'rejected'),
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
      ),
    );
  }
}
