// lib/services/api_service.dart
import 'dart:convert';
import 'package:KhanepaniApp/models/customer_statement.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/login_response.dart';
import '../models/customer_validation.dart';
import '../models/customer_details.dart';
import '../models/consumption_history.dart';

class ApiService {
  static String baseUrl = AppConfig.baseUrl;
  static int tenantId = AppConfig.tenantId;
  static String? _authToken;

  static setBaseUrl(String url) {
    baseUrl = url;
    print('🔄 Base URL updated to: $baseUrl');
  }

  static setTenantId(int id) {
    tenantId = id;
    print('🔄 Tenant ID updated to: $tenantId');
  }

  static void setToken(String? token) {
    _authToken = token;
    if (token != null && token.isNotEmpty) {
      print('🔑 Token set: ${token.substring(0, 20)}...');
    } else {
      print('🔑 Token cleared');
    }
  }

  static String? get token => _authToken;

  // Helper method to get headers with authorization
  static Map<String, String> _getHeaders({bool isMultipart = false}) {
    final headers = {
      'accept': '*/*',
      'Content-Type': isMultipart ? 'multipart/form-data' : 'application/json',
    };
    
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Login API - Get Token
  static Future<LoginResponse> login(String username, String password) async {
    try {
      final url = Uri.parse('$baseUrl/api/Auth/login');
      print('🔐 Login URL: $url');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('📡 Login Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Login Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Change Password Method (Primary)
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    try {
      final url = Uri.parse('$baseUrl/api/Auth/change-password');
      print('🔑 Change Password URL: $url');
      print('🔑 Tenant ID: $tenantId');
      
      final requestBody = {
        'tenantId': tenantId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
      print('🔑 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );

      print('📡 Change Password Response Status: ${response.statusCode}');
      print('📡 Change Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Password changed successfully',
          'data': data,
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? data['error'] ?? 'Invalid request';
        throw Exception('Bad Request: $message');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid current password or token expired');
      } else if (response.statusCode == 404) {
        print('❌ Endpoint not found: $url');
        throw Exception('API endpoint not found. Please check the server URL: $baseUrl/api/Auth/change-password');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      } else {
        throw Exception('Password change failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Change Password Error: $e');
      throw Exception('Error changing password: $e');
    }
  }

  // Update Password (Alternative endpoint using customer ID)
  static Future<Map<String, dynamic>> updatePassword({
    required int customerID,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    try {
      final url = Uri.parse('$baseUrl/api/MeterReading/UpdatePassword');
      print('🔄 Update Password URL: $url');
      print('🔄 Tenant ID: $tenantId');
      print('🔄 Customer ID: $customerID');
      
      final requestBody = {
        'clientCODE': tenantId,
        'customerID': customerID,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };
      print('🔄 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );

      print('📡 Update Password Response Status: ${response.statusCode}');
      print('📡 Update Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Password updated successfully',
          'data': data,
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? data['error'] ?? 'Invalid request';
        throw Exception('Bad Request: $message');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid old password or token expired');
      } else if (response.statusCode == 404) {
        print('❌ Endpoint not found: $url');
        throw Exception('API endpoint not found. Please check the server URL: $baseUrl/api/MeterReading/UpdatePassword');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      } else {
        throw Exception('Failed to update password: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Update Password Error: $e');
      throw Exception('Error updating password: $e');
    }
  }

  // Validate Customer
  static Future<CustomerValidation> validateCustomer({
    required int customerID,
    required String password,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    try {
      final url = Uri.parse('$baseUrl/api/MeterReading/isValidCustomer?ClientCODE=$tenantId');
      print('🔍 Validate Customer URL: $url');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'customerID': customerID,
          'password': password,
        }),
      );

      print('📡 Validate Customer Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CustomerValidation.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('401: Unauthorized - Token may have expired');
      } else {
        throw Exception('Customer validation failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Validation Error: $e');
      throw Exception('Network error during validation: $e');
    }
  }

  // Get Customer Details
  static Future<CustomerDetails> getCustomerInfo(int customerID) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    try {
      final url = Uri.parse('$baseUrl/api/MeterReading/GetCustomerInfo?ClientCODE=$tenantId&CustomerID=$customerID');
      print('👤 Get Customer Info URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      print('📡 Get Customer Info Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CustomerDetails.fromJson(data);
      } else {
        throw Exception('Failed to get customer info: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Customer Info Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get Consumption History
  static Future<ConsumptionHistoryResponse> getConsumptionHistory(int customerID) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    try {
      final url = Uri.parse('$baseUrl/api/MeterReading/GetConsumptionHistory');
      print('📊 Get Consumption History URL: $url');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'clientCODE': tenantId,
          'customerID': customerID,
        }),
      );

      print('📡 Get Consumption History Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ConsumptionHistoryResponse.fromJson(data);
      } else {
        throw Exception('Failed to get consumption history: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Consumption History Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get Customer Statement
  static Future<CustomerStatementResponse> getCustomerStatement({
    required int customerID,
    required String fromDate,
    required String toDate,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    try {
      final url = Uri.parse('$baseUrl/api/MeterReading/GetCustomerStatement');
      print('📄 Get Customer Statement URL: $url');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'clientCODE': tenantId,
          'customerID': customerID,
          'fromDate': fromDate,
          'toDate': toDate,
        }),
      );

      print('📡 Get Customer Statement Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CustomerStatementResponse.fromJson(data);
      } else {
        throw Exception('Failed to get statement: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get Customer Statement Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // ✅ Forgot Password - Static method (CORRECT)
  static Future<Map<String, dynamic>> forgotPassword({
    required int customerID,
    required String mobile,
    required String newPassword,
  }) async {
    // Check if token exists
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    try {
      final url = Uri.parse('$baseUrl/api/MeterReading/ForgotPassword');
      print('🔐 Forgot Password URL: $url');
      print('🔐 Tenant ID: $tenantId');
      print('🔐 Customer ID: $customerID');
      print('🔐 Mobile: $mobile');
      
      final requestBody = {
        'clientCODE': tenantId,
        'customerID': customerID,
        'mobile': mobile,
        'newPassword': newPassword,
      };
      print('🔐 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );

      print('📡 Forgot Password Response Status: ${response.statusCode}');
      print('📡 Forgot Password Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Password reset successfully',
          'data': data,
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? data['error'] ?? 'Invalid request';
        throw Exception('Bad Request: $message');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token may have expired');
      } else if (response.statusCode == 404) {
        print('❌ Endpoint not found: $url');
        throw Exception('API endpoint not found. Please check the server URL: $baseUrl/api/MeterReading/ForgotPassword');
      } else if (response.statusCode == 409) {
        throw Exception('Customer ID or mobile number not found. Please check your details.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      } else {
        throw Exception('Failed to reset password: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Forgot Password Error: $e');
      throw Exception('Error resetting password: $e');
    }
  }

  // Verify Token (to check if token is still valid)
  static Future<bool> verifyToken() async {
    if (_authToken == null || _authToken!.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$baseUrl/api/Auth/verify-token');
      print('🔍 Verify Token URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      print('📡 Verify Token Response Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Verify Token Error: $e');
      return false;
    }
  }

  // Test Endpoint (to check if API is reachable)
  static Future<Map<String, dynamic>> testEndpoint() async {
    try {
      final url = Uri.parse('$baseUrl/api/Auth/test');
      print('🧪 Test Endpoint URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      print('📡 Test Endpoint Response Status: ${response.statusCode}');
      print('📡 Test Endpoint Response Body: ${response.body}');

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'body': response.body,
      };
    } catch (e) {
      print('❌ Test Endpoint Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Logout (clear token)
  static void logout() {
    _authToken = null;
    print('🔑 Logged out - token cleared');
  }

  // Debug: Print current configuration
  static void printConfig() {
    print('📋 ===== API Service Configuration =====');
    print('📋 Base URL: $baseUrl');
    print('📋 Tenant ID: $tenantId');
    print('📋 Token: ${_authToken != null ? "${_authToken!.substring(0, 20)}..." : "null"}');
    print('📋 Is Authenticated: ${_authToken != null && _authToken!.isNotEmpty}');
    print('📋 =====================================');
  }
}