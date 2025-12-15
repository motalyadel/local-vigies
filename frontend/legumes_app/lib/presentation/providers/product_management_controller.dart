// presentation/controllers/product_management_controller.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/data/services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

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

  Future<int> get pendingRequestsCount async {
    final vendorId = Supabase.instance.client.auth.currentUser?.id;
    if (vendorId == null) return 0;

    try {
      final response = await Supabase.instance.client
          .from('product_requests')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('status', 'pending');

      return response.length;
    } catch (e) {
      print("Erreur comptage demandes pending: $e");
      return 0;
    }
  }

  // // NOUVELLE MÉTHODE : Charger les demandes du vendeur
  // Future<void> loadRequests() async {
  //   loading = true;
  //   error = null;
  //   notifyListeners();

  //   try {
  //     final userId = Supabase.instance.client.auth.currentUser?.id;
  //     if (userId == null) {
  //       products = [];
  //       return;
  //     }

  //     final response = await Supabase.instance.client
  //         .from('product_requests')
  //         .select()
  //         .eq('vendor_id', userId)
  //         .order('created_at', ascending: false);

  //     products =
  //         (response as List).map((json) => Product.fromMap(json)).toList();
  //   } catch (e) {
  //     error = 'Failed to load requests: $e';
  //     products = [];
  //   } finally {
  //     loading = false;
  //     notifyListeners();
  //   }
  // }

  // ==================== CRÉATION DE PRODUIT ====================
  Future<bool> createProduct({
    required String name,
    required double price,
    required int quantity,
    cross_file.XFile? imageFile,
    DateTime? date,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      String? imageUrl;

      // Upload de l'image si fournie
      if (imageFile != null) {
        imageUrl = await _service.uploadProductImage(imageFile);
        if (imageUrl == null) {
          error = "Échec de l'upload de la photo";
          return false;
        }
      }

      // Appel au service/backend
      final success = await _service.createProduct(
        name: name,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
        date: date,
      );

      if (success) {
        await loadProducts(); // Recharge la liste
      }

      return success;
    } catch (e) {
      error = 'Impossible de créer le produit : $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Mise à jour de produit avec upload photo si nouvelle
  Future<bool> updateProduct({
    required String id,
    String? name,
    double? price,
    int? quantity,
    cross_file.XFile? newImageFile,
    DateTime? date,
  }) async {
    loading = true;
    notifyListeners();

    String? newImageUrl;
    if (newImageFile != null) {
      newImageUrl = await _service.uploadProductImage(newImageFile);
      if (newImageUrl == null) {
        error = "Échec de l'upload de la nouvelle photo";
        loading = false;
        notifyListeners();
        return false;
      }
    }

    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) updates['name'] = name.trim();
    if (price != null) updates['price'] = price;
    if (quantity != null) updates['quantity'] = quantity;
    if (newImageUrl != null) updates['image_url'] = newImageUrl;
    if (date != null) updates['date'] = date.toIso8601String().split('T')[0];

    if (updates.isEmpty) {
      loading = false;
      notifyListeners();
      return true;
    }

    final success = await _service.updateProduct(id, updates);
    if (success) await loadProducts();

    loading = false;
    notifyListeners();
    return success;
  }

  // // Upload photo commune (utilisée par create et update)
  // Future<String?> _uploadImage(cross_file.XFile imageFile) async {
  //   try {
  //     final timestamp = DateTime.now().millisecondsSinceEpoch;
  //     final fileName = '${timestamp}_${imageFile.name}';
  //     final filePath = 'products/$fileName';

  //     final response = await Supabase.instance.client.storage
  //         .from('products')
  //         .upload(filePath, (await imageFile.readAsBytes()) as File);

  //     if (response.error != null) {
  //       print('Erreur upload Storage : ${response.error!.message}');
  //       return null;
  //     }

  //     return Supabase.instance.client.storage
  //         .from('products')
  //         .getPublicUrl(filePath);
  //   } on StorageException catch (e) {
  //     print('Erreur Storage : ${e.message}');
  //     return null;
  //   } catch (e) {
  //     print('Exception upload : $e');
  //     return null;
  //   }
  // }

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
