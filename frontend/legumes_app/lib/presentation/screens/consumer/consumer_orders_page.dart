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
    _listenToRealtimeUpdates();
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
            quantity,
            vendor_shop_name,
            price_at_request,
            product_id,
            products:product_id(id, name, image_url)
          ''')
          .eq('consumer_id', consumerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erreur chargement historique demandes: $e");
      return [];
    }
  }

  void _listenToRealtimeUpdates() {
    ConsumerLocalService.getConsumerId().then((consumerId) {
      if (consumerId == null) return;

      Supabase.instance.client
          .channel('consumer_requests_history')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'product_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'consumer_id',
              value: consumerId,
            ),
            callback: (_) {
              setState(() {
                _ordersFuture = _loadOrders();
              });
            },
          )
          .subscribe();
    });
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(
      Supabase.instance.client.channel('consumer_requests_history'),
    );
    super.dispose();
  }

  String _getStatusText(String? status, AppLocalizations l10n) {
    return switch (status) {
      'pending' => l10n.statusPending ?? 'En attente',
      'accepted' => l10n.statusAccepted ?? 'Acceptée',
      'rejected' => l10n.statusRejected ?? 'Refusée',
      'in_delivery' => l10n.statusInDelivery ?? 'En livraison',
      'completed' => l10n.statusCompleted ?? 'Livrée',
      _ => l10n.statusUnknown ?? 'Inconnu',
    };
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(l10n.myRequests),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.green));
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text("${l10n.errorOccurred}\n${snapshot.error}"));
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    Text(
                      l10n.noRequestsYet,
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
                final String? vendor_shop_name = req['vendor_shop_name'] as String?;
                final String productName =
                    product['name'] as String? ?? 'Produit inconnu';
                final dynamic priceAtRequest = req['price_at_request'] ?? 0;
                final int quantity = (req['quantity'] as num?)?.toInt() ?? 1;
                final num totalPrice = priceAtRequest * quantity;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  color: Colors.white,
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
                                      placeholder: (_, __) =>
                                          Container(color: Colors.grey[300]),
                                      errorWidget: (_, __, ___) => Container(
                                          color: Colors.grey[300],
                                          child:
                                              const Icon(Icons.broken_image)),
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
                                  Text(productName,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "$quantity ${l10n.kilogram} $priceAtRequest ${l10n.pricePerKg}",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${l10n.totalLabel} $totalPrice MRU",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("$vendor_shop_name",
                                      style:
                                          TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              backgroundColor: _getStatusColor(req['status']),
                              label: Text(_getStatusText(req['status'], l10n),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy HH:mm')
                                  .format(DateTime.parse(req['created_at'])),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        if (req['customer_location'] != null &&
                            req['customer_location']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        req['customer_location'].toString())),
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
      ),
    );
  }
}
