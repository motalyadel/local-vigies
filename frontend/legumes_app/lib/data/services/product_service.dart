// data/services/product_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart' as cross_file;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:legumes_app/core/network/api_fetcher.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient clientSpb = Supabase.instance.client;

  // Token toujours à jour → on recrée le fetcher à chaque appel
  ApiFetcher get _fetcher {
    final token = clientSpb.auth.currentSession?.accessToken;
    return ApiFetcher(
      accessToken: token,
      baseUrl: 'http://10.0.2.2:4000',
    );
  }

  // ==================== MES PRODUITS ====================
  Future<List<Product>> getMyProducts() async {
    final userId = clientSpb.auth.currentUser?.id;
    if (userId == null) return [];

    final res = await _fetcher.getWithId('product/vendor/:id', id: userId);

    if (!res.isSuccess || res.data['success'] != true) {
      print('Erreur getMyProducts → ${res.status} ${res.error}');
      return [];
    }

    // Filtre les produits supprimés
    final List<dynamic> list = res.data['products'];
    return list
        .where((p) => p['active'] != false) // ou p['is_deleted'] != true
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ==================== TOUS LES PRODUITS DU MARCHÉ ====================
  Future<List<Product>> getAllProducts() async {
    final res = await _fetcher.get('product/list');

    if (!res.isSuccess || res.data['success'] != true) {
      print('Erreur getAllProducts → ${res.status} ${res.error}');
      return [];
    }

    // Filtre les produits supprimés
    final List<dynamic> list = res.data['products'];
    return list
        .where((p) => p['active'] != false) // ou p['is_deleted'] != true
        .map((e) => Product.fromMap(e as Map<String, dynamic>))
        .toList();
  }

// ==================== FONCTION COMMUNE D'UPLOAD (à mettre dans ton service) ====================
  Future<String?> uploadProductImage(cross_file.XFile imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = clientSpb.auth.currentUser?.id;
      final cleanName = imageFile.name
          .replaceAll(RegExp(r'[() ]+'), '_')
          .replaceAll('×', 'x')
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');

      final fileName = '${timestamp}_$cleanName';
      final filePath = 'product/$userId/$fileName';

      final bytes = await imageFile.readAsBytes();

      // Utilise uploadBinary pour gérer web et mobile correctement
      final response =
          await Supabase.instance.client.storage.from('products').uploadBinary(
                filePath,
                bytes,
                fileOptions: FileOptions(upsert: false),
              );

      // Si erreur, Supabase lance une exception → on catch
      final publicUrl = Supabase.instance.client.storage
          .from('products')
          .getPublicUrl(filePath);

      print('Image uploadée avec succès : $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      print('Erreur Storage : ${e.message}');
      return null;
    } catch (e) {
      print('Erreur inattendue upload : $e');
      return null;
    }
  }

  Future<bool> createProduct({
    required String name,
    required double price,
    required int quantity,
    String? imageUrl, // ← On accepte l'URL directement
    DateTime? date,
  }) async {
    final body = {
      'name': name,
      'price': price.toString(),
      'quantity': quantity.toString(),
      if (imageUrl != null) 'image_url': imageUrl,
      if (date != null) 'date': date.toIso8601String().split('T')[0],
    };

    final res = await _fetcher.post('product/create', body: body);

    if (!res.isSuccess) {
      print('Erreur API création produit : ${res.error}');
      return false;
    }

    final data = res.data;
    if (data is Map && data['success'] == true) {
      return true;
    }

    print('Réponse inattendue : $data');
    return false;
  }

  // Pour la mise à jour (updateProduct)
  Future<bool> updateProduct(String id, Map<String, dynamic> updates) async {
    final res = await _fetcher.put('product/update/$id', body: updates);
    return res.isSuccess && res.data['success'] == true;
  }

  // ==================== SUPPRESSION ====================
  Future<bool> deleteProduct(String id) async {
    final res = await _fetcher.delete('product/delete/$id');

    if (!res.isSuccess) {
      print('Suppression échouée → ${res.status} ${res.error}');
      return false;
    }

    return res.data['success'] == true;
  }

  // Nouvelle méthode statique pour parser les nombres
  static double parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
