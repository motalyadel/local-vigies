// data/services/product_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
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

    final List<dynamic> list = res.data['products'];
    return list.map((e) => Product.fromMap(e as Map<String, dynamic>)).toList();
  }

  // ==================== TOUS LES PRODUITS DU MARCHÉ ====================
  Future<List<Product>> getAllProducts() async {
    final res = await _fetcher.get('product/list');

    if (!res.isSuccess || res.data['success'] != true) {
      print('Erreur getAllProducts → ${res.status} ${res.error}');
      return [];
    }

    final List<dynamic> list = res.data['products'];
    return list.map((e) => Product.fromMap(e as Map<String, dynamic>)).toList();
  }

  // ==================== CRÉATION DE PRODUIT ====================
  Future<bool> createProduct({
    required String name,
    required double price,
    required int quantity,
    XFile? imageFile,
    DateTime? date,
  }) async {
    String? imageUrl;

    // Upload image dans le dossier product/userId/…
    if (imageFile != null) {
      final userId = clientSpb.auth.currentUser?.id;
      if (userId == null) return false;

      String cleanName = imageFile.name
          .replaceAll(RegExp(r'[() ]+'), '_')
          .replaceAll('×', 'x')
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');

      // Extension en minuscule
      if (cleanName.contains('.')) {
        final parts = cleanName.split('.');
        cleanName = '${parts.first}.${parts.last.toLowerCase()}';
      }

      final path =
          'product/$userId/${DateTime.now().millisecondsSinceEpoch}_$cleanName';

      try {
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          await clientSpb.storage.from('products').uploadBinary(
                path,
                bytes,
                fileOptions:
                    FileOptions(upsert: true, contentType: imageFile.mimeType),
              );
        } else {
          await clientSpb.storage.from('products').upload(
                path,
                File(imageFile.path),
                fileOptions:
                    FileOptions(upsert: true, contentType: imageFile.mimeType),
              );
        }

        imageUrl = clientSpb.storage.from('products').getPublicUrl(path);
        print('Image uploadée → $imageUrl');
      } catch (e) {
        print('Échec upload image : $e');
        return false;
      }
    }

    // Envoi au backend
    final body = {
      'name': name,
      'price': price.toString(),
      'quantity': quantity.toString(),
      if (imageUrl != null) 'image_url': imageUrl,
      if (date != null) 'date': date.toIso8601String().split('T')[0],
    };

    final res = await _fetcher.post('product/create', body: body);
    final success = res.isSuccess && res.data['success'] == true;

    if (!success) print('Création produit échouée → ${res.error}');
    return success;
  }

  // ==================== MISE À JOUR ====================
  Future<bool> updateProduct(String id, Map<String, dynamic> updates) async {
    final res = await _fetcher.put('product/update/$id', body: updates);
    return res.isSuccess && res.data['success'] == true;
  }

  // ==================== SUPPRESSION ====================
  Future<bool> deleteProduct(String id) async {
    final res = await _fetcher.delete('product/delete/$id');
    return res.isSuccess && res.data['success'] == true;
  }

  // Dans data/services/product_service.dart
  Future<String?> uploadImage(XFile file, String path) async {
    try {
      // Nettoyage du nom de fichier
      String cleanFileName = file.name
          .replaceAll(RegExp(r'[() ]'), '_') // remplace ( ) et espaces par _
          .replaceAll('×', 'x') // remplace le × spécial
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),
              ''); // supprime tout caractère bizarre

      // Optionnel : tu peux forcer l'extension en minuscule
      if (cleanFileName.contains('.')) {
        final parts = cleanFileName.split('.');
        cleanFileName = '${parts.first}.${parts.last.toLowerCase()}';
      }

      // Chemin final propre
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
      final finalPath =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';

      print('Upload vers: $finalPath');

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await clientSpb.storage.from('products').uploadBinary(finalPath, bytes,
            fileOptions: FileOptions(upsert: true, contentType: file.mimeType));
      } else {
        await clientSpb.storage.from('products').upload(
            finalPath, File(file.path),
            fileOptions: FileOptions(upsert: true, contentType: file.mimeType));
      }

      final url = clientSpb.storage.from('products').getPublicUrl(finalPath);
      print('Upload réussi → $url');
      return url;
    } catch (e) {
      print("Échec upload: $e");
      return null;
    }
  }

  // Nouvelle méthode statique pour parser les nombres
  static double parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
