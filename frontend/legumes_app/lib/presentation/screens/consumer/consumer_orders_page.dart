// presentation/pages/consumer/consumer_orders_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:legumes_app/core/services/consumer_local_service.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumerOrdersPage extends StatefulWidget {
  const ConsumerOrdersPage({super.key});

  @override
  State<ConsumerOrdersPage> createState() => _ConsumerOrdersPageState();
}

class _ConsumerOrdersPageState extends State<ConsumerOrdersPage> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final consumerId = await ConsumerLocalService.getConsumerId();
    if (consumerId == null) return [];

    try {
      final response = await Supabase.instance.client
          .from('product_requests')
          .select('''
            id, 
            status, 
            created_at, 
            responded_at, 
            customer_location,
            price_at_request,
            product_id,
            products:product_id(id, name, image_url)
          ''')
          .eq('consumer_id', consumerId)
          .inFilter('status', ['accepted', 'in_delivery', 'completed'])
          .order('responded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erreur chargement commandes: $e");
      return [];
    }
  }

  String _getStatusText(String? status, AppLocalizations l10n) {
    return switch (status) {
      'accepted' => l10n.statusAccepted ?? 'Acceptée',
      'in_delivery' => l10n.statusInDelivery ?? 'En livraison',
      'completed' => l10n.statusCompleted ?? 'Livrée',
      _ => l10n.statusPending ?? 'En attente',
    };
  }

  Color _getStatusColor(String? status) {
    return switch (status) {
      'accepted' => Colors.green,
      'in_delivery' => Colors.blue,
      'completed' => Colors.purple,
      _ => Colors.orange,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myRequests ?? "Mes commandes"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("${l10n.errorOccurred}\n${snapshot.error}"),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    l10n.noAcceptedOrders ?? "Aucune commande en cours",
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final req = orders[index];
              final product = req['products'] as Map<String, dynamic>;

              final String? imageUrl = product['image_url'] as String?;
              final String productName =
                  product['name'] as String? ?? 'Produit inconnu';
              final dynamic priceAtRequest = req['price_at_request'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                            child:
                                                CircularProgressIndicator())),
                                    errorWidget: (_, __, ___) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image,
                                            size: 40)),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image,
                                        size: 40, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$priceAtRequest MRU",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Vendeur inconnu", // À améliorer plus tard avec table vendors
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
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
                            backgroundColor: _getStatusColor(req['status']),
                            label: Text(
                              _getStatusText(req['status'], l10n),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            req['responded_at'] != null
                                ? DateFormat('dd MMM yyyy HH:mm')
                                    .format(DateTime.parse(req['responded_at']))
                                : DateFormat('dd MMM yyyy HH:mm')
                                    .format(DateTime.parse(req['created_at'])),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (req['customer_location'] != null &&
                          req['customer_location'].toString().trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  req['customer_location'].toString(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
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
    );
  }
}
