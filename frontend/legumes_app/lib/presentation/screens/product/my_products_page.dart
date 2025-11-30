// presentation/pages/my_products_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:legumes_app/presentation/screens/product/add_product_page.dart';
import 'package:legumes_app/presentation/screens/product/edit_product_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:legumes_app/data/models/product_model.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  @override
  void initState() {
    super.initState();
    // Charger les produits dès l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductManagementController>(context, listen: false)
          .loadProducts();
    });
  }

  Future<void> _showDeleteDialog(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text(
            "Are you sure you want to delete this product permanently?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<ProductManagementController>(context, listen: false)
          .deleteProduct(productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Products"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ProductManagementController>(context, listen: false)
                  .loadProducts();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductPage()),
          );
          if (result == true) {
            Provider.of<ProductManagementController>(context, listen: false)
                .loadProducts();
          }
        },
      ),
      body: Consumer<ProductManagementController>(
        builder: (context, controller, child) {
          if (controller.loading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(controller.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadProducts(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (controller.products.isEmpty) {
            return const Center(
              child: Text(
                "No products yet\nTap + to add your first product",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadProducts,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.products.length,
              itemBuilder: (context, index) {
                final product = controller.products[index];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 40),
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image,
                                  size: 40, color: Colors.grey),
                            ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Price: ${product.price.toStringAsFixed(0)} MRU"),
                        Text("Quantity: ${product.quantity.toString()} K"),
                        Text(
                            "Date: ${DateFormat('dd/MM/yyyy').format(product.date)}"),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductPage(product: product),
                            ),
                          );
                          if (updated == true) {
                            controller.loadProducts();
                          }
                        } else if (value == 'delete') {
                          _showDeleteDialog(product.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text("Delete",
                              style: TextStyle(color: Colors.red)),
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
    );
  }
}
