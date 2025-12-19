// presentation/pages/all_products_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:provider/provider.dart';

class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (_) => ProductManagementController()..loadAllProducts(),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(l10n.allProducts,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 28),
                tooltip: l10n.refresh,
                onPressed: () {
                  Provider.of<ProductManagementController>(context, listen: false)
                      .loadAllProducts();
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Consumer<ProductManagementController>(
            builder: (context, controller, child) {
              if (controller.loading) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Colors.blue, strokeWidth: 5));
              }
        
              if (controller.error != null) {
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
                        Text(controller.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700])),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => controller.loadAllProducts(),
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.retry),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16)),
                        ),
                      ],
                    ),
                  ),
                );
              }
        
              if (controller.products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sentiment_dissatisfied_rounded,
                            size: 120, color: Colors.grey[400]),
                        const SizedBox(height: 32),
                        Text(l10n.noProducts,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text("Revenez plus tard pour découvrir les nouveautés !",
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
        
              return RefreshIndicator(
                onRefresh: controller.loadAllProducts,
                color: Colors.blue,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: controller.products.length,
                  itemBuilder: (context, i) {
                    final p = controller.products[i];
        
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
                        child: Row(
                          children: [
                            // Image du produit
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      p.imageUrl!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      // loadingBuilder:
                                      //     (context, child, loadingProgress) {
                                      //   if (loadingProgress == null) return child;
                                      //   return Container(
                                      //       color: Colors.grey[200],
                                      //       child: const Center(
                                      //           child: CircularProgressIndicator(
                                      //               color: Colors.blue)));
                                      // },
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image,
                                            size: 50, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: const Icon(Icons.image,
                                          size: 50, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 20),
        
                            // Infos produit
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.vendorBy(
                                        p.vendorPhone ?? l10n.unknownVendor),
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 15),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money_rounded,
                                          size: 18, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${p.price.toStringAsFixed(0)} MRU",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.inventory_rounded,
                                          size: 18, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text("${p.quantity} kg",
                                          style: const TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
        
                            // Avatar du vendeur
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: p.vendorPhotoUrl != null &&
                                      p.vendorPhotoUrl!.isNotEmpty
                                  ? NetworkImage(p.vendorPhotoUrl!)
                                  : null,
                              backgroundColor: Colors.blue,
                              child: p.vendorPhotoUrl == null ||
                                      p.vendorPhotoUrl!.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 28, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
