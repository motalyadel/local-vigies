// presentation/pages/my_products_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final controller =
        TextEditingController(text: product.price.toStringAsFixed(0));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.updatePriceTitle(product.name)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: product.price.toStringAsFixed(0),
            suffixText: ' MRU',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice >= 0) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.check),
            label: Text(l10n.update),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.priceUpdated(newPrice.toStringAsFixed(0))
                : l10n.priceUpdateFailed),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(String productId) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteProduct),
        content: Text(l10n.deleteProductConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProducts),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () =>
                Provider.of<ProductManagementController>(context, listen: false)
                    .loadProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        tooltip: l10n.addProduct,
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
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(controller.error!),
                  ElevatedButton(
                    onPressed: () => controller.loadProducts(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (controller.products.isEmpty) {
            return Center(
              child: Text(
                l10n.noProductsAddHint,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
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
                      child: product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              width: 64,
                              height: 64,
                              child: const Icon(Icons.image, size: 40),
                            ),
                    ),
                    title: Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.price(product.price.toStringAsFixed(0))),
                        Text(l10n.stock(product.quantity)),
                        Text(l10n.productDate(
                            DateFormat('dd/MM/yyyy').format(product.date))),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.price_change,
                              color: Colors.orange, size: 28),
                          tooltip: l10n.updatePrice,
                          onPressed: () =>
                              _showQuickPriceDialog(context, product),
                        ),
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
                            PopupMenuItem(
                                value: 'edit', child: Text(l10n.edit)),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.delete,
                                  style: const TextStyle(color: Colors.red)),
                            ),
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
