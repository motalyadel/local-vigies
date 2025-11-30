// presentation/controllers/product_management_controller.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/data/services/product_service.dart';

class ProductManagementController extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> products = [];
  bool loading = false;
  String? error;

  // Charger les produits du vendeur connecté
  Future<void> loadProducts() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      products = await _service.getMyProducts();
    } catch (e) {
      error = 'Failed to load products: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllProducts() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      products = await _service.getAllProducts();
    } catch (e) {
      error = 'Failed to load products: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Créer un nouveau produit
  Future<void> createProduct({
    required String name,
    required double price,
    required int quantity,
    // String? imageUrl,
    DateTime? date,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.createProduct(
        name: name,
        price: price,
        quantity: quantity,
        // imageUrl: imageUrl,
        date: date,
      );

      if (success) {
        await loadProducts(); // Recharge la liste
      } else {
        throw Exception('Failed to create product');
      }
    } catch (e) {
      error = 'Failed to create product: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Mettre à jour un produit
  Future<void> updateProduct({
    required String id,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    DateTime? date,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (price != null) updates['price'] = price.toString();
      if (quantity != null) updates['quantity'] = quantity.toString();
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (date != null) updates['date'] = date.toIso8601String().split('T')[0];

      final success = await _service.updateProduct(id, updates);

      if (success) {
        await loadProducts();
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      error = 'Failed to update product: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Supprimer un produit
  Future<void> deleteProduct(String id) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.deleteProduct(id);
      if (success) {
        products.removeWhere((p) => p.id == id);
        notifyListeners();
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      error = 'Failed to delete product: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
