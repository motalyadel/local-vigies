// presentation/pages/vendor_home_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/local_provider.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:legumes_app/presentation/screens/home/login_page.dart';
import 'package:legumes_app/presentation/screens/product/all_products_page.dart';
import 'package:legumes_app/presentation/screens/product/my_products_page.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_chat_list_screen.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_requests_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:legumes_app/core/utils/navigator.dart';
import 'package:legumes_app/presentation/providers/auth_controller.dart';

class VendorHomePage extends StatelessWidget {
  const VendorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        if (auth.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          );
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
            title: Text(l10n.vendorDashboard),
            backgroundColor: Colors.teal,
            actions: [
              IconButton(
                icon: const Icon(Icons.language, color: AppColors.background),
                onPressed: () {
                  final current = localeProvider.locale.languageCode;
                  final newLocale =
                      current == 'fr' ? const Locale('ar') : const Locale('fr');
                  localeProvider.changeLocale(newLocale);
                },
                tooltip: 'Changer la langue',
              ),
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: l10n.profileLogout,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(l10n.logout),
                      content: Text(l10n.logoutConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.logout),
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
                          children: [
                            // Stats
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.4,
                              children: [
                                _buildClickableStatCard(
                                  context: context,
                                  icon: Icons.inventory_2,
                                  label: l10n.totalProducts,
                                  value: totalProducts.toString(),
                                  color: Colors.blue,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const MyProductsPage())),
                                ),
                                _buildClickableStatCard(
                                  context: context,
                                  icon: Icons.scale,
                                  label: l10n.totalStock,
                                  value: "$totalStock kg",
                                  color: Colors.green,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const MyProductsPage())),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Menu
                            ListTile(
                              leading: const Icon(Icons.add_circle,
                                  color: Colors.teal),
                              title: Text(l10n.addProduct),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => AppNavigator.push('/add_product'),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.list_alt,
                                  color: Colors.orange),
                              title: Text(l10n.myProducts),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const MyProductsPage())),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading:
                                  const Icon(Icons.store, color: Colors.purple),
                              title: Text(l10n.marketProducts),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AllProductsPage())),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading:
                                  const Icon(Icons.chat, color: Colors.green),
                              title: Text(l10n.myConversations),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const VendorChatListScreen())),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.shopping_cart_outlined,
                                  color: Colors.deepOrange),
                              title: Text(l10n.myRequests),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const VendorRequestsPage())),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '${l10n.lastUpdate}: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
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
          padding: const EdgeInsets.all(8),
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
