import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _consumerIdKey = 'consumer_id';

  static Future<void> saveConsumerId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_consumerIdKey, id);
  }

  static Future<String?> getConsumerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_consumerIdKey);
  }
}
