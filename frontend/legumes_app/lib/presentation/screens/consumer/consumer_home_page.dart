// presentation/screens/consumer/consumer_home_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/data/services/product_service.dart';

class ConsumerHomePage extends StatefulWidget {
  const ConsumerHomePage({super.key});

  @override
  State<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  final ProductService _service = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      _products = await _service.getAllProducts();
      _filteredProducts = _products;
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading products: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredProducts = _products.where((p) {
        final nameMatch = p.name.toLowerCase().contains(_searchQuery);
        final vendorMatch =
            p.vendorShopName?.toLowerCase().contains(_searchQuery) ?? false;
        return nameMatch || vendorMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Products'),
        backgroundColor: Colors.orange,
        actions: [
          // Bouton "Se connecter" en haut à droite
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/login');
            },
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text(
              'Se connecter',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Optionnel : garder le bouton refresh à côté
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProducts,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by product or vendor...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: _filterProducts,
            ),
          ),

          // Optional Category Filter (placeholder for later)
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   child: DropdownButton<String>(
          //     value: 'All',
          //     items: ['All', 'Fruits', 'Vegetables', 'Others'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
          //     onChanged: (value) { /* Implement category filter later */ },
          //   ),
          // ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('No products found'))
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final p = _filteredProducts[index];
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: p.imageUrl != null
                                          ? Image.network(
                                              p.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.broken_image,
                                                      size: 80),
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image,
                                                  size: 80),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${p.price.toStringAsFixed(0)} MRU',
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'By: ${p.vendorShopName ?? 'Unknown Vendor'}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
