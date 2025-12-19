// presentation/pages/add_vendor_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:legumes_app/data/services/vendor_service.dart';
import 'package:legumes_app/presentation/providers/vendor_management_controller.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

class AddVendorPage extends StatefulWidget {
  const AddVendorPage({super.key});

  @override
  State<AddVendorPage> createState() => _AddVendorPageState();
}

class _AddVendorPageState extends State<AddVendorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  cross_file.XFile? _photo;
  bool _loading = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final controller =
        Provider.of<VendorManagementController>(context, listen: false);

    String? photoUrl;
    if (_photo != null) {
      photoUrl = await VendorService().uploadPhoto(_photo!, 'vendors/${DateTime.now().millisecondsSinceEpoch}/photo.jpg');
      if (photoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec upload photo')));
        setState(() => _loading = false);
        return;
      }
    }

    await controller.createUser(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      shopName: _shopCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vendeur créé !')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Échec création')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajouter un Vendeur'),
          backgroundColor: Colors.teal,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nom complet', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? 'Email invalide' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? '6+ caractères' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _shopCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nom du magasin', prefixIcon: Icon(Icons.store)),
                  validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Téléphone', prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _locCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Localisation',
                        prefixIcon: Icon(Icons.location_on))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo),
                  label: const Text('Photo'),
                ),
                if (_photo != null) Text('Photo: ${_photo!.name}'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.all(16)),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Créer', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _shopCtrl.dispose();
    _phoneCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }
}
