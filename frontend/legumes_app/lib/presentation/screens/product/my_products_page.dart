// presentation/pages/my_products_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:legumes_app/presentation/screens/product/add_product_page.dart';
import 'package:legumes_app/presentation/screens/product/edit_product_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductManagementController>(context, listen: false)
          .loadProducts();
    });
  }

  // Dialog rapide pour changer le prix
  Future<void> _showQuickPriceDialog(
      BuildContext context, Product product) async {
    final controller =
        TextEditingController(text: product.price.toStringAsFixed(0));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nouveau prix – ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: product.price.toStringAsFixed(0),
            suffixText: ' DA',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice >= 0) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Mettre à jour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newPrice = double.tryParse(controller.text) ?? product.price;
      final success =
          await Provider.of<ProductManagementController>(context, listen: false)
              .updatePriceDirectly(product.id, newPrice);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Prix mis à jour : ${newPrice.toStringAsFixed(0)} DA'
                : 'Échec de la mise à jour'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le produit"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
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
        title: const Text("Mes Produits"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                Provider.of<ProductManagementController>(context, listen: false)
                    .loadProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddProductPage()));
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
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(controller.error!),
                  ElevatedButton(
                      onPressed: () => controller.loadProducts(),
                      child: const Text("Réessayer")),
                ],
              ),
            );
          }

          if (controller.products.isEmpty) {
            return const Center(
              child: Text("Aucun produit\nAppuyez sur + pour ajouter",
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
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
                          ? Image.network(product.imageUrl!,
                              width: 70, height: 70, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 40)),
                    ),
                    title: Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Prix : ${product.price.toStringAsFixed(0)} MRU",
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text("Stock : ${product.quantity} K"),
                        Text(
                            "Date : ${DateFormat('dd/MM/yyyy').format(product.date)}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton mise à jour rapide du prix
                        IconButton(
                          icon: const Icon(Icons.price_change,
                              color: Colors.orange, size: 28),
                          tooltip: "Mettre à jour le prix",
                          onPressed: () =>
                              _showQuickPriceDialog(context, product),
                        ),
                        // Menu classique
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EditProductPage(product: product)),
                              );
                              if (updated == true) controller.loadProducts();
                            } else if (value == 'delete') {
                              _showDeleteDialog(product.id);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text("Modifier")),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Text("Supprimer",
                                    style: TextStyle(color: Colors.red))),
                          ],
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
