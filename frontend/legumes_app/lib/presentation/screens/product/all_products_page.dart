// presentation/pages/all_products_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:provider/provider.dart';

class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductManagementController()..loadAllProducts(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All Market Products'),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
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
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.products.isEmpty) {
              return const Center(
                  child: Text('No products available in the market'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.products.length,
              itemBuilder: (context, i) {
                final p = controller.products[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: p.imageUrl != null && p.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              p.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 40),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Par : ${p.vendorShopName ?? 'Vendeur inconnu'}",
                          style: TextStyle(
                            fontSize: 13,
                            color: p.vendorShopName != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${p.price.toStringAsFixed(0)} MRU • ${p.quantity} K",
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    trailing: p.vendorPhotoUrl != null &&
                            p.vendorPhotoUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(p.vendorPhotoUrl!),
                            backgroundColor: Colors.grey[200],
                          )
                        : const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.person,
                                color: Colors.white, size: 20),
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
