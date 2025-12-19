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
  // Liste des statuts possibles
  final List<String> _statuses = [
    'pending',
    'accepted',
    'rejected',
    'in_delivery',
    'completed',
  ];

  // Couleurs associées à chaque statut
  Color _getStatusColor(String? status) {
    return switch (status) {
      'pending' => Colors.orange,
      'accepted' => Colors.green,
      'rejected' => Colors.red,
      'in_delivery' => Colors.blue,
      'completed' => Colors.purple,
      _ => Colors.grey,
    };
  }

  // Texte localisé du statut
  String _getStatusText(String? status, AppLocalizations l10n) {
    return switch (status) {
      'pending' => l10n.statusPending,
      'accepted' => l10n.statusAccepted,
      'rejected' => l10n.statusRejected,
      'in_delivery' => l10n.statusInDelivery,
      'completed' => l10n.statusCompleted,
      _ => l10n.statusUnknown,
    };
  }

  // Mise à jour du statut avec logique intelligente
  Future<void> _updateStatus(String requestId, String oldStatus, String newStatus) async {
    final Map<String, dynamic> updateData = {'status': newStatus};

    // On met à jour responded_at seulement si on passe de pending à autre chose
    if (oldStatus == 'pending' && newStatus != 'pending') {
      updateData['responded_at'] = DateTime.now().toIso8601String();
    }

    try {
      await Supabase.instance.client
          .from('product_requests')
          .update(updateData)
          .eq('id', requestId);

      // Optionnel : déclencher une notification push ou in-app pour le consumer
      // Tu peux ajouter un trigger Supabase ou un appel API ici
      print('Statut mis à jour : $newStatus pour la demande $requestId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingStatus)),
        );
      }
    }
  }

  void _callClient(String? phone) async {
    if (phone == null || phone == 'Non disponible' || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Stream<List<Map<String, dynamic>>> get _requestsStream {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return Supabase.instance.client
        .from('product_requests')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', userId)
        .order('created_at', ascending: false)
        .asyncMap((requests) async {
          final productIds = requests
              .map((r) => r['product_id'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          final Map<String, String?> productImages = {};
          if (productIds.isNotEmpty) {
            final productsResponse = await Supabase.instance.client
                .from('products')
                .select('id, image_url')
                .inFilter('id', productIds);

            productImages.addAll({
              for (var p in productsResponse) p['id'] as String: p['image_url'] as String?
            });
          }

          final consumerIds = requests
              .map((r) => r['consumer_id'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          final Map<String, Map<String, dynamic>> consumerMap = {};
          if (consumerIds.isNotEmpty) {
            final consumersResponse = await Supabase.instance.client
                .from('consumers')
                .select('id, name, phone')
                .inFilter('id', consumerIds);

            consumerMap.addAll({
              for (var c in consumersResponse) c['id'] as String: c
            });
          }

          return requests.map((r) {
            final consumerId = r['consumer_id'] as String?;
            final consumerData = consumerId != null ? consumerMap[consumerId] : null;
            final productImage = r['product_id'] != null ? productImages[r['product_id']] : null;

            return {
              ...r,
              'consumer_name': consumerData?['name'] ?? 'Client inconnu',
              'consumer_phone': consumerData?['phone'] ?? 'Non disponible',
              'product_image_url': productImage,
            };
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            l10n.myRequests,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
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
                child: CircularProgressIndicator(color: Colors.teal, strokeWidth: 5),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 100, color: Colors.red[300]),
                      const SizedBox(height: 24),
                      Text(l10n.errorOccurred, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text("${snapshot.error}", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
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
                      Icon(Icons.inbox_rounded, size: 120, color: Colors.grey[400]),
                      const SizedBox(height: 32),
                      Text(l10n.noRequestsYet, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Text(l10n.noRequestsYet, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final r = requests[index];
                final status = r['status'] as String?;
                final clientName = r['consumer_name'] as String;
                final clientPhone = r['consumer_phone'] as String;
                final productImageUrl = r['product_image_url'] as String?;

                final bool isFinalStatus = status == 'rejected' || status == 'completed';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image produit + infos client
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: productImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: productImageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: Colors.grey[300]),
                                      errorWidget: (_, __, ___) => const Icon(Icons.image, size: 50),
                                    )
                                  : Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.image)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _callClient(clientPhone),
                                    child: Text(
                                      clientPhone,
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(l10n.addressLabel(r['customer_location'] ?? l10n.notSpecified)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Statut actuel + Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              backgroundColor: _getStatusColor(status),
                              label: Text(
                                _getStatusText(status, l10n),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM HH:mm').format(DateTime.parse(r['created_at'])),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Bouton Chat
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_rounded),
                            label: Text(l10n.chat),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
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

                        const SizedBox(height: 16),

                        // Sélecteur de statut (seulement si pas terminé)
                        if (!isFinalStatus)
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: InputDecoration(
                              labelText: l10n.updateStatus,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            items: _statuses.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(_getStatusText(s, l10n)),
                              );
                            }).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null && newStatus != status) {
                                _updateStatus(r['id'].toString(), status ?? 'pending', newStatus);
                              }
                            },
                          ),

                        if (isFinalStatus)
                          Center(
                            child: Text(
                              l10n.requestFinalized,
                              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}