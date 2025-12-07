// import 'package:shared_preferences/shared_preferences.dart';

// class LocalStorageService {
//   static const String _consumerIdKey = 'consumer_id';

//   static Future<void> saveConsumerId(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_consumerIdKey, id);
//   }

//   static Future<String?> getConsumerId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_consumerIdKey);
//   }
// }

// lib/core/services/consumer_local_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class ConsumerLocalService {
  static const String _keyName = 'consumer_name';
  static const String _keyPhone = 'consumer_phone';
  static const String _keyId = 'consumer_id';

  static Future<void> saveConsumerInfo({
    required String name,
    required String phone,
    String? consumerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name.trim());
    await prefs.setString(_keyPhone, phone.trim());
    if (consumerId != null) {
      await prefs.setString(_keyId, consumerId);
    }
  }

  static Future<Map<String, String>?> getConsumerInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    final phone = prefs.getString(_keyPhone);
    if (name != null && phone != null && name.isNotEmpty && phone.isNotEmpty) {
      return {'name': name, 'phone': phone};
    }
    return null;
  }

  static Future<String?> getConsumerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyId);
  }
}