// lib/config/runtime_config.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class RuntimeConfig {
  static const String _baseUrlKey = 'base_url';
  static const String _tenantIdKey = 'tenant_id';
  
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? AppConfig.baseUrl;
  }
  
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }
  
  static Future<int> getTenantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tenantIdKey) ?? AppConfig.tenantId;
  }
  
  static Future<void> setTenantId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tenantIdKey, id);
  }
}