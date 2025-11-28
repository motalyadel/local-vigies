import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
import 'package:legumes_app/data/models/auth_model.dart';
import 'package:legumes_app/data/services/vendor_service.dart';
import 'package:cross_file/cross_file.dart' as cross_file;

class VendorUpdateController extends ChangeNotifier {
  final nameCtrl = TextEditingController();
  final shopCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final locCtrl = TextEditingController();
  cross_file.XFile? photo;
  bool loading = false;
  String? error;

  void init(Vendor v) {
    nameCtrl.text = v.name ?? '';
    shopCtrl.text = v.shopName;
    phoneCtrl.text = v.phone ?? '';
    locCtrl.text = v.location ?? '';
  }

  Future<void> pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      photo = picked;
      notifyListeners();
    }
  }

  Future<bool> save(BuildContext context, String vendorId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      String? photoUrl;
      if (photo != null) {
        photoUrl = await VendorService().uploadPhoto(photo!, 'vendors/$vendorId/photo.jpg');
        if (photoUrl == null) throw 'Échec upload';
      }

      final success = await VendorService().updateVendor(
        userId: vendorId,
        name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        shopName: shopCtrl.text.trim().isEmpty ? null : shopCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        location: locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
        photoUrl: photoUrl,
      );

      return success;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    shopCtrl.dispose();
    phoneCtrl.dispose();
    locCtrl.dispose();
    super.dispose();
  }
}
