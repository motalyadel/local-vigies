// presentation/pages/vendor_home_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:legumes_app/presentation/screens/product/all_products_page.dart';
import 'package:legumes_app/presentation/screens/product/my_products_page.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_chat_list_screen.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_chat_screen.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_requests_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:legumes_app/core/utils/navigator.dart';
import 'package:legumes_app/presentation/providers/auth_controller.dart';

class VendorHomePage extends StatelessWidget {
  const VendorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        if (auth.loading) {
          return const Scaffold(
              body:
                  Center(child: CircularProgressIndicator(color: Colors.teal)));
        }

        if (!auth.isAuthenticated || auth.currentRole != 'vendor') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.pushReplacement('/login');
          });
          return const SizedBox();
        }

        final productCtrl =
            Provider.of<ProductManagementController>(context, listen: false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          productCtrl.loadProducts();
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Vendor Dashboard'),
            backgroundColor: Colors.teal,
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Profile / Logout',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) await auth.signOut();
                },
              ),
            ],
          ),
          body: Consumer<ProductManagementController>(
            builder: (context, productCtrl, child) {
              final totalProducts = productCtrl.products.length;
              final totalStock = productCtrl.products
                  .fold<int>(0, (sum, p) => sum + p.quantity);

              return RefreshIndicator(
                onRefresh: productCtrl.loadProducts,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Card
                            Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back, Vendor!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Manage your products and explore the market.',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Stats Grid – CLIC → MyProductsPage
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.5,
                              children: [
                                _buildClickableStatCard(
                                  context: context,
                                  icon: Icons.inventory_2,
                                  label: 'My Products',
                                  value: '$totalProducts',
                                  color: Colors.blue,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const MyProductsPage())),
                                ),
                                _buildClickableStatCard(
                                  context: context,
                                  icon: Icons.store,
                                  label: 'My Stock',
                                  value: '$totalStock units',
                                  color: Colors.green,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const MyProductsPage())),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    // Bouton principal → AllProductsPage (tous les produits du marché)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AllProductsPage()),
                                  );
                                },
                                icon: const Icon(Icons.public, size: 28),
                                label: const Text('Explore All Market Products',
                                    style: TextStyle(fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading:
                                  const Icon(Icons.chat, color: Colors.green),
                              title: const Text("Mes Conversations"),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const VendorChatListScreen(), // ← CORRIGÉ : va vers la liste
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.shopping_cart_outlined),
                              title: const Text("Mes demandes"),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const VendorRequestsPage()),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Last update: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Nouvelle fonction pour carte cliquable
  Widget _buildClickableStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
