// lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _customerIdKey = 'customer_id';
  static const String _userIdKey = 'user_id';

  // Save token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save customer ID
  static Future<void> saveCustomerId(String customerId) async {
    await _storage.write(key: _customerIdKey, value: customerId);
  }

  // Get customer ID
  static Future<String?> getCustomerId() async {
    return await _storage.read(key: _customerIdKey);
  }

  // Save user ID
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _customerIdKey);
    await _storage.delete(key: _userIdKey);
  }

  // Delete specific key
  static Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }

  // Check if key exists
  static Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }

  // Get all keys
  static Future<Map<String, String>> getAll() async {
    return await _storage.readAll();
  }
}