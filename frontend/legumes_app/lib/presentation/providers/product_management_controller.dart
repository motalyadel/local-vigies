// presentation/controllers/product_management_controller.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/data/services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // NOUVELLE MÉTHODE : Charger les demandes du vendeur
  Future<void> loadRequests() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        products = [];
        return;
      }

      final response = await Supabase.instance.client
          .from('product_requests')
          .select()
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);

      products =
          (response as List).map((json) => Product.fromMap(json)).toList();
    } catch (e) {
      error = 'Failed to load requests: $e';
      products = [];
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
    XFile? imageFile, // ← NOUVEAU : on passe le fichier directement
    DateTime? date,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      print('debuit creation de produit ');
      final success = await _service.createProduct(
        name: name,
        price: price,
        quantity: quantity,
        imageFile: imageFile, // ← On passe le XFile ici
        date: date,
      );

      if (success) {
        await loadProducts(); // Recharge la liste
      } else {
        throw Exception('Échec de la création du produit');
      }
    } catch (e) {
      error = 'Impossible de créer le produit : $e';
      print('Erreur création produit : $e');
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
    XFile? imageFile, // ← Permet de changer la photo
    DateTime? date,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      String? imageUrl;
      if (imageFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
        imageUrl = await ProductService().uploadImage(imageFile, fileName);
        if (imageUrl == null) throw Exception("Échec de l'upload de l'image");
      }

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
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      error = 'Erreur mise à jour : $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePriceDirectly(String productId, double newPrice) async {
    loading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('products')
          .update({
            'price': newPrice,
            'updated_at': DateTime.now().toIso8601String(),
            'date':
                DateTime.now().toIso8601String().split('T')[0], // date du jour
          })
          .eq('id', productId)
          .select(); // important pour avoir la réponse

      if (response.isEmpty) {
        error = "Produit non trouvé ou vous n'êtes pas autorisé";
        return false;
      }

      // Mise à jour locale
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = products[index].copyWith(price: newPrice);
        notifyListeners();
      }

      return true;
    } catch (e) {
      error = "Erreur : $e";
      print("Erreur update price: $e");
      return false;
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
