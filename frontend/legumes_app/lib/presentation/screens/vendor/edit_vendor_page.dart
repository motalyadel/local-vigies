import 'dart:io';

import 'package:flutter/material.dart';
import 'package:legumes_app/presentation/providers/auth_controller.dart';
import 'package:legumes_app/presentation/providers/vendor_management_controller.dart';
import 'package:legumes_app/presentation/providers/vendor_update_controller.dart';
import 'package:provider/provider.dart';
import 'package:legumes_app/data/models/auth_model.dart';
import 'package:legumes_app/data/services/vendor_service.dart';
import 'package:cross_file/cross_file.dart' as cross_file;


class EditVendorPage extends StatefulWidget {
  final Vendor vendor;
  const EditVendorPage({super.key, required this.vendor});

  @override
  State<EditVendorPage> createState() => _EditVendorPageState();
}

class _EditVendorPageState extends State<EditVendorPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser le controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<VendorUpdateController>(context, listen: false);
      controller.init(widget.vendor);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final controller = Provider.of<VendorUpdateController>(context, listen: false);

    try {
      final success = await controller.save(context, widget.vendor.id);
      if (success && mounted) {
        Provider.of<VendorManagementController>(context, listen: false).loadVendors();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendeur modifié avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final updateController = Provider.of<VendorUpdateController>(context);

    // Sécurité : admin uniquement
    if (authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le Vendeur'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: updateController.loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : updateController.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        updateController.error!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => updateController.error = null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Consumer<VendorUpdateController>(
                            builder: (context, ctrl, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Modifier le Vendeur',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                  const SizedBox(height: 16),

                                  // === Email en lecture seule ===
                                  // Card(
                                  //   color: Colors.grey[100],
                                  //   child: ListTile(
                                  //     leading: const Icon(Icons.email, color: Colors.teal),
                                  //     title: Text(widget.vendor.email ?? 'Email non défini'),
                                  //     subtitle: const Text('Non modifiable'),
                                  //   ),
                                  // ),
                                  const SizedBox(height: 16),

                                  // === Photo ===
                                  Center(
                                    child: GestureDetector(
                                      onTap: () => ctrl.pickPhoto(context),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundImage: ctrl.photo != null
                                            ? FileImage(File(ctrl.photo!.path))
                                            : (widget.vendor.photoUrl != null
                                                ? NetworkImage(widget.vendor.photoUrl!)
                                                : null),
                                        child: ctrl.photo == null && widget.vendor.photoUrl == null
                                            ? const Icon(Icons.store, size: 60, color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () => ctrl.pickPhoto(context),
                                      icon: const Icon(Icons.photo_camera, color: Colors.white),
                                      label: const Text('Changer la photo'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                    ),
                                  ),
                                  if (ctrl.photo != null) ...[
                                    const SizedBox(height: 8),
                                    Center(child: Text('Photo: ${ctrl.photo!.name}')),
                                  ],
                                  const SizedBox(height: 16),

                                  // === Champs ===
                                  TextFormField(
                                    controller: ctrl.nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom complet',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                      prefixIcon: Icon(Icons.person, color: Colors.teal),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: ctrl.shopCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom du magasin',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                      prefixIcon: Icon(Icons.store, color: Colors.teal),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: ctrl.phoneCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Téléphone',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                      prefixIcon: Icon(Icons.phone, color: Colors.teal),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: ctrl.locCtrl
                                    ,
                                    decoration: const InputDecoration(
                                      labelText: 'Localisation',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                      prefixIcon: Icon(Icons.location_on, color: Colors.teal),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // === Bouton ===
                                  Center(
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.teal)
                                        : ElevatedButton(
                                            onPressed: _submitForm,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              textStyle: const TextStyle(fontSize: 16),
                                            ),
                                            child: const Text('Sauvegarder'),
                                          ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}