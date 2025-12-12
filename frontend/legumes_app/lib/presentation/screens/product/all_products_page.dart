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
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.allProducts),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refresh,
              onPressed: () {
                Provider.of<ProductManagementController>(context, listen: false)
                    .loadAllProducts();
              },
            ),
          ],
        ),
        body: Consumer<ProductManagementController>(
          builder: (context, controller, child) {
            if (controller.loading) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.orange));
            }

            if (controller.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(l10n.errorOccurred),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => controller.loadAllProducts(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }

            if (controller.products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied,
                        size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noProducts,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadAllProducts,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: controller.products.length,
                itemBuilder: (context, i) {
                  final p = controller.products[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                            ? Image.network(
                                p.imageUrl!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child:
                                      const Icon(Icons.broken_image, size: 40),
                                ),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey[200],
                                child:
                                    const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            l10n.vendorBy(
                                p.vendorShopName ?? l10n.unknownVendor),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.attach_money,
                                  size: 18, color: Colors.green),
                              Text(
                                "${p.price.toStringAsFixed(0)} MRU",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.scale,
                                  size: 18, color: Colors.blue),
                              Text(
                                "${p.quantity} kg",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: p.vendorPhotoUrl != null &&
                              p.vendorPhotoUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(p.vendorPhotoUrl!),
                            )
                          : const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
