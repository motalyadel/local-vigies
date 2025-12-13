// presentation/pages/product/edit_product_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:provider/provider.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final controller =
        Provider.of<ProductManagementController>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    try {
      final success = await controller.updateProduct(
        id: widget.product.id,
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text),
        quantity: int.tryParse(_quantityCtrl.text),
        imageFile: imageFile,
        date: _selectedDate,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productUpdatedSuccess),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l10n.productUpdateFailed}: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.editProduct,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Photo du produit
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.blue.withOpacity(0.3), width: 4),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10)),
                        ],
                      ),
                      child: imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.file(File(imageFile!.path),
                                  fit: BoxFit.cover),
                            )
                          : widget.product.imageUrl != null &&
                                  widget.product.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: Image.network(
                                    widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 80,
                                        color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.image_rounded,
                                  size: 80, color: Colors.grey),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: FloatingActionButton.small(
                        onPressed: _pickPhoto,
                        backgroundColor: Colors.blue,
                        child:
                            const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Nom du produit
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.productName,
                  prefixIcon: const Icon(Icons.inventory_2_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2)),
                ),
                validator: (v) => v!.trim().isEmpty ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 20),

              // Prix
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.priceMRU,
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  suffixText: ' MRU',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2)),
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return l10n.fieldRequired;
                  if (double.tryParse(v) == null || double.parse(v) <= 0)
                    return l10n.invalidPrice;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Quantité
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.quantityKg,
                  prefixIcon: const Icon(Icons.scale_rounded),
                  suffixText: ' kg',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2)),
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return l10n.fieldRequired;
                  if (int.tryParse(v) == null || int.parse(v) <= 0)
                    return l10n.invalidQuantity;
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date
              ListTile(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                          colorScheme:
                              const ColorScheme.light(primary: Colors.blue)),
                      child: child!,
                    ),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey[300]!)),
                tileColor: Colors.white,
                leading: const Icon(Icons.calendar_today_rounded,
                    color: Colors.blue),
                title: Text(
                    l10n.productDate(
                        DateFormat('dd MMMM yyyy').format(_selectedDate)),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.edit_calendar, color: Colors.blue),
              ),
              const SizedBox(height: 40),

              // Bouton Mettre à jour
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(33, 150, 243, 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 12,
                    shadowColor: Colors.blue.withOpacity(0.4),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3)
                      : Text(
                          l10n.update,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
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
