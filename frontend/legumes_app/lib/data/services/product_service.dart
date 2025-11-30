// data/services/product_service.dart
import 'package:image_picker/image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legumes_app/core/network/api_fetcher.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cross_file/cross_file.dart';

class ProductService {
  late final SupabaseClient clientSpb;
  late final ApiFetcher apiFetcher;

  ProductService() {
    clientSpb = Supabase.instance.client;
    apiFetcher = ApiFetcher(
      accessToken: clientSpb.auth.currentSession?.accessToken,
      baseUrl: 'http://10.0.2.2:4000',
    );
  }

  // Dans ProductService
  Future<List<Product>> getMyProducts() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      print("Aucun utilisateur connecté");
      return [];
    }

    print("Récupération des produits pour vendor: $userId");

    final res = await apiFetcher.getWithId(
      'product/vendor/:id', // Template avec :id
      id: userId, // Remplace automatiquement :id
    );

    if (res.isSuccess && res.data['success'] == true) {
      final list = res.data['products'] as List;
      return list.map((e) => Product.fromMap(e)).toList();
    } else {
      print("Erreur API: ${res.error}");
      return [];
    }
  }

  Future<List<Product>> getAllProducts() async {
    print("Récupération de tous les produits du marché...");

    final res = await apiFetcher.get('product/list');

    if (!res.isSuccess || res.data['success'] != true) {
      print("Erreur lors du chargement de tous les produits: ${res.error}");
      return [];
    }

    final List<dynamic> rawList = res.data['products'] as List<dynamic>;

    return rawList.map((json) {
      // Important : convertir chaque élément en Map<String, dynamic>
      final map = json as Map<String, dynamic>;
      return Product.fromMap(map); // Tout est géré proprement ici !
    }).toList();
  }

// Nouvelle méthode statique pour parser les nombres
  static double parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<bool> createProduct({
    required String name,
    required double price,
    required int quantity,
    XFile? imageUrl,
    DateTime? date,
  }) async {
    final body = {
      'name': name,
      'price': price.toString(),
      'quantity': quantity.toString(),
      // if (imageUrl != null) 'image_url': imageUrl,
      if (date != null) 'date': date.toIso8601String().split('T')[0],
    };

    final res =
        await apiFetcher.post('product/create', body: body, file: imageUrl);
    return res.isSuccess && res.data['success'] == true;
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> updates) async {
    final res = await apiFetcher.put('product/update/$id', body: updates);
    return res.isSuccess && res.data['success'] == true;
  }

  Future<bool> deleteProduct(String id) async {
    final res = await apiFetcher.delete('product/delete/$id');
    return res.isSuccess && res.data['success'] == true;
  }

  // Dans data/services/product_service.dart
  Future<String?> uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName =
          'products/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      await Supabase.instance.client.storage
          .from('products')
          .uploadBinary(fileName, bytes);

      final publicUrl = Supabase.instance.client.storage
          .from('products')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}
