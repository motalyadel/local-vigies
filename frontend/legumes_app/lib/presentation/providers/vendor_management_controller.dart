// presentation/controllers/vendor_management_controller.dart
import 'package:flutter/material.dart';
import 'package:legumes_app/data/models/auth_model.dart';
import 'package:legumes_app/data/services/vendor_service.dart';

class VendorManagementController extends ChangeNotifier {
  final VendorService _service = VendorService();

  List<Vendor> vendors = [];
  bool loading = false;
  String? error;

  Future<void> loadVendors() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      vendors = await _service.getAllVendors();
    } catch (e) {
      error = 'Échec du chargement : $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createVendor({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? phone,
    String? location,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.createVendor(
        name: name,
        email: email,
        password: password,
        shopName: shopName,
        phone: phone,
        location: location,
      );
      if (success) await loadVendors();
    } catch (e) {
      error = 'Échec création : $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? phone,
    String? location,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.createUser(
        name: name,
        email: email,
        password: password,
        shopName: shopName,
        phone: phone,
        location: location,
      );
      if (success) await loadVendors();
    } catch (e) {
      error = 'Échec création : $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  

  Future<void> updateVendor({
    required String id,
    String? name,
    String? shopName,
    String? phone,
    String? location,
    String? photoUrl,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.updateVendor(
        userId: id,
        name: name,
        shopName: shopName,
        phone: phone,
        location: location,
        photoUrl: photoUrl,
      );
      if (success) await loadVendors();
    } catch (e) {
      error = 'Échec mise à jour : $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVendor(String id) async {
    loading = true;
    notifyListeners();

    try {
      final success = await _service.deleteVendor(id);
      if (success) {
        vendors.removeWhere((v) => v.id == id);
        notifyListeners();
      }
    } catch (e) {
      error = 'Échec suppression : $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}