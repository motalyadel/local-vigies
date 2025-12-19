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
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _quantityCtrl;

  cross_file.XFile? _newPhoto;
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
      setState(() => _newPhoto = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final controller =
        Provider.of<ProductManagementController>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    final success = await controller.updateProduct(
      id: widget.product.id,
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text),
      quantity: int.tryParse(_quantityCtrl.text),
      newImageFile: _newPhoto,
      date: _selectedDate,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.productUpdatedSuccess),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.productUpdateFailed),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(l10n.editProduct,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          backgroundColor: const Color.fromARGB(0, 136, 150, 150).withOpacity(1),
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
                              color: Color.fromARGB(0, 136, 150, 150).withOpacity(0.3), width: 4),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10))
                          ],
                        ),
                        child: _newPhoto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.file(File(_newPhoto!.path),
                                    fit: BoxFit.cover),
                              )
                            : widget.product.imageUrl != null &&
                                    widget.product.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: Image.network(widget.product.imageUrl!,
                                        fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.image_rounded,
                                    size: 80, color: Colors.grey),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: FloatingActionButton.small(
                          onPressed: _pickPhoto,
                          backgroundColor: Color.fromARGB(0, 136, 150, 150),
                          child:
                              const Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
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
                            const BorderSide(color: Color.fromARGB(0, 136, 150, 150), width: 2)),
                  ),
                  validator: (v) => v!.trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 20),
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
                            const BorderSide(color: Color.fromARGB(0, 136, 150, 150), width: 2)),
                  ),
                  validator: (v) => v!.trim().isEmpty ||
                          double.tryParse(v!) == null ||
                          double.parse(v!) <= 0
                      ? l10n.invalidPrice
                      : null,
                ),
                const SizedBox(height: 20),
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
                            const BorderSide(color: Color.fromARGB(0, 136, 150, 150), width: 2)),
                  ),
                  validator: (v) => v!.trim().isEmpty ||
                          int.tryParse(v!) == null ||
                          int.parse(v!) <= 0
                      ? l10n.invalidQuantity
                      : null,
                ),
                const SizedBox(height: 20),
                ListTile(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey[300]!)),
                  tileColor: Colors.white,
                  leading: const Icon(Icons.calendar_today_rounded,
                      color: Colors.teal),
                  title: Text(
                      l10n.productDate(
                          DateFormat('dd MMMM yyyy').format(_selectedDate)),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.edit_calendar, color: Colors.teal),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(0, 136, 150, 150),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.update,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 30),
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
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }
}
