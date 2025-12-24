// presentation/pages/vendor/vendor_requests_page.dart

import 'package:cached_network_image/cached_network_image.dart';
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
  final List<String> _statuses = [
    'pending',
    'accepted',
    'rejected',
    'in_delivery',
    'completed',
  ];

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

  // Mise à jour du statut + déduction du stock si passage à in_delivery
  Future<void> _updateStatus(String requestId, String oldStatus,
      String newStatus, int quantityRequested, String productId) async {
    final Map<String, dynamic> updateData = {'status': newStatus};

    if (oldStatus == 'pending' && newStatus != 'pending') {
      updateData['responded_at'] = DateTime.now().toIso8601String();
    }

    // Cas spécial : passage à in_delivery → déduire du stock
    if (newStatus == 'in_delivery' && oldStatus != 'in_delivery') {
      try {
        // 1. Récupérer le stock actuel du produit
        final productResponse = await Supabase.instance.client
            .from('products')
            .select('quantity')
            .eq('id', productId)
            .single();

        final currentStock =
            (productResponse['quantity'] as num?)?.toInt() ?? 0;

        if (currentStock < quantityRequested) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.insufficientStock ??
                    "Stock insuffisant pour cette commande"),
                backgroundColor: Colors.red,
              ),
            );
          }
          return; // On arrête ici, pas de changement de statut
        }

        // 2. Mettre à jour le stock
        await Supabase.instance.client.from('products').update(
            {'quantity': currentStock - quantityRequested}).eq('id', productId);

        // 3. Mettre à jour le statut de la demande
        await Supabase.instance.client
            .from('product_requests')
            .update(updateData)
            .eq('id', requestId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.stockUpdatedSuccessfully ??
                      "Stock mis à jour et commande en livraison"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.errorUpdatingStock ??
                        "Erreur lors de la mise à jour du stock")),
          );
        }
        return;
      }
    } else {
      // Tous les autres changements de statut (hors in_delivery)
      try {
        await Supabase.instance.client
            .from('product_requests')
            .update(updateData)
            .eq('id', requestId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.errorUpdatingStatus)),
          );
        }
      }
    }
  }

  // Mise à jour du stream pour inclure quantity_requested
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
              for (var p in productsResponse)
                p['id'] as String: p['image_url'] as String?
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

            consumerMap.addAll(
                {for (var c in consumersResponse) c['id'] as String: c});
          }

          return requests.map((r) {
            final consumerId = r['consumer_id'] as String?;
            final consumerData =
                consumerId != null ? consumerMap[consumerId] : null;
            final productImage =
                r['product_id'] != null ? productImages[r['product_id']] : null;

            return {
              ...r,
              'quantity_requested': r['quantity'] ?? 0,
              'consumer_name': consumerData?['name'] ?? 'Client inconnu',
              'consumer_phone': consumerData?['phone'] ?? 'Non disponible',
              'product_image_url': productImage,
            };
          }).toList();
        });
  }

  void _callClient(String? phone) async {
    if (phone == null || phone == 'Non disponible' || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(l10n.myRequests,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
              return Center(child: Text(l10n.errorOccurred));
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 120, color: Colors.grey[400]),
                    const SizedBox(height: 32),
                    Text(l10n.noRequestsYet,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final r = requests[index];
                final status = r['status'] as String? ?? 'pending';
                final clientName = r['consumer_name'] as String;
                final clientPhone = r['consumer_phone'] as String;
                final productImageUrl = r['product_image_url'] as String?;
                final int quantityRequested =
                    (r['quantity_requested'] as num?)?.toInt() ?? 1;
                final String productId = r['product_id'] as String;

                final bool isFinalStatus =
                    status == 'rejected' || status == 'completed';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                      placeholder: (_, __) =>
                                          Container(color: Colors.grey[300]),
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.image, size: 50),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(clientName,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _callClient(clientPhone),
                                    child: Text(
                                      clientPhone,
                                      style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.shopping_basket,
                                          size: 20, color: Colors.teal),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.quantityRequested.replaceAll(
                                            '@qty',
                                            quantityRequested.toString()),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(l10n.addressLabel(
                                      r['customer_location'] ??
                                          l10n.notSpecified)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_rounded),
                            label: Text(l10n.chat),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 0, 164, 190),
                                foregroundColor: Colors.white),
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
                        if (!isFinalStatus)
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: InputDecoration(
                              labelText: l10n.updateStatus,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
                                _updateStatus(r['id'].toString(), status,
                                    newStatus, quantityRequested, productId);
                              }
                            },
                          ),
                        if (isFinalStatus)
                          Center(
                            child: Text(
                              l10n.requestFinalized,
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic),
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
