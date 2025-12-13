// presentation/pages/vendor/vendor_home_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/core/services/unread_messages_service.dart';
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
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(l10n.vendorDashboard,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () {
                  final current = localeProvider.locale.languageCode;
                  localeProvider.changeLocale(current == 'fr'
                      ? const Locale('ar')
                      : const Locale('fr'));
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Profil / Déconnexion',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content:
                          const Text('Voulez-vous vraiment vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Déconnecter'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await auth.signOut();
                  }
                },
              ),
            ],
          ),
          body: Consumer<ProductManagementController>(
            builder: (context, ctrl, child) {
              final totalProducts = ctrl.products.length;
              final totalStock =
                  ctrl.products.fold<int>(0, (sum, p) => sum + p.quantity);

              return RefreshIndicator(
                onRefresh: ctrl.loadProducts,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ===== Carte principale : Mes produits (UN SEUL BOUTON) =====
                      _buildMainActionCard(
                        context: context,
                        title: l10n.myProducts,
                        subtitle: l10n.totalProductsCount(totalProducts),
                        stockInfo: l10n.totalStockKg(totalStock),
                        icon: Icons.inventory_2_rounded,
                        color: Colors.teal,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyProductsPage())),
                      ),
                      const SizedBox(height: 24),

                      // ===== Statistiques rapides =====
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  l10n.totalProducts,
                                  totalProducts.toString(),
                                  Icons.bar_chart,
                                  Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(l10n.totalStock,
                                  "$totalStock kg", Icons.scale, Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ===== Actions rapides =====
                      _buildQuickActionTile(
                        icon: Icons.add_box_rounded,
                        title: l10n.addProduct,
                        color: Colors.orange,
                        onTap: () => AppNavigator.push('/add_product'),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionTile(
                        icon: Icons.storefront,
                        title: l10n.marketProducts,
                        color: Colors.purple,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AllProductsPage())),
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          _buildQuickActionTile(
                            icon: Icons.chat_bubble,
                            title: l10n.myConversations,
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const VendorChatListScreen())),
                          ),
                          // Badge non lus
                          FutureBuilder<int>(
                            future:
                                UnreadMessagesService.getUnreadCountForVendor(),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              if (count == 0) return const SizedBox();
                              return Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 20, minHeight: 20),
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          _buildQuickActionTile(
                            icon: Icons.shopping_cart_checkout,
                            title: l10n.myRequests,
                            color: Colors.deepOrange,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const VendorRequestsPage())),
                          ),

                          // Badge demandes en attente
                          FutureBuilder<int>(
                            future: productCtrl.pendingRequestsCount,
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              if (count == 0) return const SizedBox();

                              return Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 20, minHeight: 20),
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Text(
                        '${l10n.lastUpdate}: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===== Carte principale (gros bouton "Mes produits") =====
  Widget _buildMainActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String stockInfo,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(stockInfo,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  // ===== Petites cartes stats =====
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ]),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }

  // ===== Tuiles d'action rapide =====
  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
