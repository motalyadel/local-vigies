// presentation/widgets/vendor_form.dart
import 'package:flutter/material.dart';
import 'package:legumes_app/data/models/auth_model.dart';

class VendorForm extends StatefulWidget {
  final Vendor? vendor;
  final Future<bool> Function({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? phone,
    String? location,
  }) onSubmit;
  const VendorForm({
    super.key,
    this.vendor,
    required this.onSubmit,
  });
  @override
  State<VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends State<VendorForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _shopNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationCtrl;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vendor?.name ?? '');
    // _emailCtrl = TextEditingController(text: widget.vendor?.email ?? '');
    _passwordCtrl = TextEditingController();
    _shopNameCtrl = TextEditingController(text: widget.vendor?.shopName ?? '');
    _phoneCtrl = TextEditingController(text: widget.vendor?.phone ?? '');
    _locationCtrl = TextEditingController(text: widget.vendor?.location ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vendor != null;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom complet'),
            validator: (v) => v?.isEmpty == true ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            enabled: !isEdit, // Disable for edit
            validator: (v) {
              if (v?.isEmpty == true) return 'Requis';
              if (!v!.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 12),
          if (!isEdit)
            TextFormField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
              validator: (v) => v?.isEmpty == true ? 'Requis' : null,
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _shopNameCtrl,
            decoration: const InputDecoration(labelText: 'Nom du magasin'),
            validator: (v) => v?.isEmpty == true ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Téléphone'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationCtrl,
            decoration: const InputDecoration(labelText: 'Localisation'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? 'Mettre à jour' : 'Créer le vendeur'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = await widget.onSubmit(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      shopName: _shopNameCtrl.text.trim(),
      phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text.trim(),
      location: _locationCtrl.text.isEmpty ? null : _locationCtrl.text.trim(),
    );
    setState(() => _isLoading = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.vendor == null
                ? 'Vendeur créé !'
                : 'Vendeur mis à jour !')),
      );
      Navigator.pop(context, true); // refresh list
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l\'opération')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _shopNameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }
}
