// presentation/pages/add_product_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:provider/provider.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  cross_file.XFile? _photo;
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photo = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final controller =
        Provider.of<ProductManagementController>(context, listen: false);

    try {
      final success = await controller.createProduct(
        name: _nameCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? 0.0,
        quantity: int.tryParse(_quantityCtrl.text) ?? 0,
        imageFile: _photo,
        date: _selectedDate,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.productCreatedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${AppLocalizations.of(context)!.productCreatedFailed}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addProduct),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nom du produit
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.productName,
                  prefixIcon: const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),

              // Prix
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.priceMRU,
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return l10n.fieldRequired;
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return l10n.invalidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantité
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.quantityKg,
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return l10n.fieldRequired;
                  if (int.tryParse(v) == null || int.parse(v) <= 0) {
                    return l10n.invalidQuantity;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(l10n.productDate(
                    DateFormat('dd/MM/yyyy').format(_selectedDate))),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 16),

              // Photo
              ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera),
                label: Text(l10n.selectPhoto),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              if (_photo != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${l10n.photoSelected}: ${_photo!.name}',
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 24),

              // Bouton Créer
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.createProduct,
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }
}
