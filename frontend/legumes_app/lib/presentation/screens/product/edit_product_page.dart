import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/data/services/product_service.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _quantityCtrl;

  cross_file.XFile? imageFile;
  late DateTime _selectedDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _priceCtrl =
        TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _quantityCtrl =
        TextEditingController(text: widget.product.quantity.toString());
    _selectedDate = widget.product.date;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = picked);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final controller =
        Provider.of<ProductManagementController>(context, listen: false);

    // String? imageUrl = widget.product.imageUrl;

    // // Upload nouvelle photo si sélectionnée
    // if (imageFile != null) {
    //   imageUrl = await ProductService().uploadImage(imageFile!);
    //   if (imageUrl == null) {
    //     if (mounted) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text('Failed to upload image')),
    //       );
    //     }
    //     setState(() => _loading = false);
    //     return;
    //   }
    // }

    try {
      await controller.updateProduct(
        id: widget.product.id,
        name: _nameCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? widget.product.price,
        quantity: int.tryParse(_quantityCtrl.text) ?? widget.product.quantity,
        imageFile: imageFile,
        date: _selectedDate,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.productUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.productUpdateFailed)),
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
        title: Text(l10n.editProduct),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo actuelle + possibilité de changer
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageFile != null
                      ? Image.file(File(imageFile!.path),
                          width: 120, height: 120, fit: BoxFit.cover)
                      : widget.product.imageUrl != null
                          ? Image.network(widget.product.imageUrl!,
                              width: 120, height: 120, fit: BoxFit.cover)
                          : Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 60),
                            ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera),
                label: Text(l10n.changePhoto),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              if (imageFile != null)
                Text(l10n.newPhotoSelected,
                    style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.productName,
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: l10n.priceMRU,
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityCtrl,
                decoration: InputDecoration(
                  labelText: l10n.quantityKg,
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
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
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 16)),
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
