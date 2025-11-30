// presentation/pages/add_product_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:legumes_app/presentation/providers/product_management_controller.dart';
import 'package:provider/provider.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

import 'package:legumes_app/data/services/product_service.dart';

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

    String? imageUrl;

    // Upload photo si sélectionnée
    if (_photo != null) {
      imageUrl = await ProductService().uploadImage(_photo!);
      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        setState(() => _loading = false);
        return;
      }
    }

    try {
      await controller.createProduct(
        name: _nameCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text) ?? 0.0,
        quantity: int.tryParse(_quantityCtrl.text) ?? 0,
        // imageUrl: imageUrl,
        date: _selectedDate,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
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
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Price (MRU)',
                  prefixIcon: Icon(Icons.attach_money),
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
                decoration: const InputDecoration(
                  labelText: 'Quantity (K)',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Select Photo'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              if (_photo != null) ...[
                const SizedBox(height: 8),
                Text('Selected: ${_photo!.name}',
                    style: const TextStyle(color: Colors.green)),
              ],
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
                      : const Text('Create Product',
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
