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

  Future<void> _showQuickPriceDialog(
      BuildContext context, Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        TextEditingController(text: product.price.toStringAsFixed(0));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.updatePriceTitle(product.name),
            textAlign: TextAlign.center),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
          decoration: InputDecoration(
            hintText: product.price.toStringAsFixed(0),
            suffixText: ' MRU',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: Text(l10n.update),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice >= 0) Navigator.pop(ctx, true);
            },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text(l10n.deleteProduct, style: const TextStyle(color: Colors.red)),
        content: Text(l10n.deleteProductConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.white),
            ),
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

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(l10n.myProducts,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.refresh,
              onPressed: () =>
                  Provider.of<ProductManagementController>(context, listen: false)
                      .loadProducts(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddProductPage()));
            if (result == true) {
              Provider.of<ProductManagementController>(context, listen: false)
                  .loadProducts();
            }
          },
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add, size: 28),
          label: Text(l10n.addProduct,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
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
                    Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(controller.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => controller.loadProducts(),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.teal),
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
                    Icon(Icons.inventory_2_outlined,
                        size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    Text(l10n.noProductsAddHint,
                        style: const TextStyle(fontSize: 20, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              );
            }
      
            return RefreshIndicator(
              onRefresh: controller.loadProducts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.products.length,
                itemBuilder: (context, index) {
                  final product = controller.products[index];
      
                  return Card(
                    elevation: 8,
                    color: Colors.white,
                    shadowColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showQuickPriceDialog(context, product),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image,
                                            size: 40, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      child: const Icon(Icons.image,
                                          size: 40, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(width: 16),
      
                            // Infos
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        "${product.price.toStringAsFixed(0)} ${l10n.pricePerKg}",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory,
                                          size: 18, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(l10n.stock(product.quantity),
                                          style: const TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.productDate(DateFormat('dd/MM/yyyy')
                                        .format(product.date)),
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
      
                            // Actions
                            PopupMenuButton<String>(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              EditProductPage(product: product)));
                                  if (updated == true) controller.loadProducts();
                                } else if (value == 'delete') {
                                  _showDeleteDialog(product.id);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      const Icon(Icons.edit, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(l10n.edit)
                                    ])),
                                PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      const Icon(Icons.delete, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(l10n.delete)
                                    ])),
                              ],
                            ),
                          ],
                        ),
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
