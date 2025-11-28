// presentation/pages/admin_vendor_management_page.dart
import 'package:flutter/material.dart';
import 'package:legumes_app/core/utils/navigator.dart';
import 'package:legumes_app/data/models/auth_model.dart';
import 'package:legumes_app/data/services/vendor_service.dart';
import 'package:legumes_app/presentation/providers/auth_controller.dart';
import 'package:legumes_app/presentation/providers/vendor_management_controller.dart';
import 'package:legumes_app/presentation/screens/vendor/add_vendor_page.dart';
import 'package:legumes_app/presentation/screens/vendor/edit_vendor_page.dart';
import 'package:legumes_app/presentation/widgets/vendor_card.dart';
import 'package:provider/provider.dart';

class AdminVendorManagementPage extends StatefulWidget {
  const AdminVendorManagementPage({super.key});

  @override
  State<AdminVendorManagementPage> createState() =>
      _AdminVendorManagementPageState();
}

class _AdminVendorManagementPageState extends State<AdminVendorManagementPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<VendorManagementController>(context, listen: false)
        .loadVendors();
  }

  Future<void> _addVendor() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AddVendorPage()));
    if (result == true) {
      Provider.of<VendorManagementController>(context, listen: false)
          .loadVendors();
    }
  }

  Future<void> _editVendor(Vendor vendor) async {
    final result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => EditVendorPage(vendor: vendor)));
    if (result == true) {
      Provider.of<VendorManagementController>(context, listen: false)
          .loadVendors();
    }
  }

  Future<void> _deleteVendor(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer ce vendeur ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await VendorService().deleteVendor(id);
      if (success) {
        Provider.of<VendorManagementController>(context, listen: false)
            .loadVendors();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Vendeur supprimé')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    if (!auth.isAuthenticated || auth.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigator.pushReplacement('/login');
      });
      return const SizedBox();
    }

    return Consumer<VendorManagementController>(
      builder: (context, controller, child) {
        if (controller.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestion des Vendeurs'),
            actions: [
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
          floatingActionButton: FloatingActionButton(
            onPressed: _addVendor,
            child: const Icon(Icons.add),
          ),
          body: controller.error != null
              ? Center(child: Text('Erreur: ${controller.error}'))
              : controller.vendors.isEmpty
                  ? const Center(child: Text('Aucun vendeur'))
                  : RefreshIndicator(
                      onRefresh: controller.loadVendors,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: controller.vendors.length,
                        itemBuilder: (context, i) {
                          final v = controller.vendors[i];
                          return VendorCard(
                            vendor: v,
                            onEdit: () => _editVendor(v),
                            onDelete: () => _deleteVendor(v.id),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}
