// data/models/product_model.dart
import 'package:legumes_app/data/services/product_service.dart';

class Product {
  final String id;
  final String vendorId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? vendorShopName;
  final String? vendorPhotoUrl;
  final String? vendorLocation;

  Product({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.date,
    this.createdAt,
    this.updatedAt,
    this.vendorShopName,
    this.vendorPhotoUrl,
    this.vendorLocation,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
  final vendorData = map['vendor'] as Map<String, dynamic>?;

  return Product(
    id: map['id']?.toString() ?? '',
    vendorId: map['vendor_id']?.toString() ?? '',
    name: map['name']?.toString() ?? 'Produit inconnu',
    price: ProductService.parseDouble(map['price']),
    quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    
    // LA LIGNE QUI PLANTE ÉTAIT ICI :
    imageUrl: map['image_url']?.toString(),  // CORRIGÉ !

    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    
    createdAt: map['created_at'] != null 
        ? DateTime.tryParse(map['created_at'].toString()) 
        : null,
        
    updatedAt: map['updated_at'] != null 
        ? DateTime.tryParse(map['updated_at'].toString()) 
        : null,

    // Ces 3 là aussi étaient dangereuses :
    vendorShopName: vendorData?['shop_name']?.toString(),
    vendorPhotoUrl: vendorData?['photo_url']?.toString(),
    vendorLocation: vendorData?['location']?.toString(),
  );
}

  // // Parser sécurisé pour le prix (Supabase peut renvoyer String, int ou double)
  // static double _parseDouble(dynamic value) {
  //   if (value is double) return value;
  //   if (value is int) return value.toDouble();
  //   if (value is String) return double.tryParse(value) ?? 0.0;
  //   return 0.0;
  // }

  static String? _parseImageUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value['url'] as String?; // Cas Supabase Storage
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'date': date.toIso8601String().split('T')[0],
    };
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price MRU, qty: $quantity K)';
  }

  // Pour mise à jour facile
  Product copyWith({
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    DateTime? date,
  }) {
    return Product(
      id: id,
      vendorId: vendorId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
