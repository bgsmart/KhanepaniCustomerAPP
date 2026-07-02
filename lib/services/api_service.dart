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
  }

  static setTenantId(int id) {
    tenantId = id;
  }

  static void setToken(String? token) {
    _authToken = token;
  }

  static String? get token => _authToken;

  // Login API - Get Token
  static Future<LoginResponse> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LoginResponse.fromJson(data);
    } else {
      throw Exception('Login failed: ${response.statusCode}');
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

    final response = await http.post(
      Uri.parse('$baseUrl/api/MeterReading/isValidCustomer?ClientCODE=$tenantId'),
      headers: {
        'accept': 'text/plain',
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'customerID': customerID,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CustomerValidation.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('401: Unauthorized - Token may have expired');
    } else {
      throw Exception('Customer validation failed: ${response.statusCode}');
    }
  }

  // Get Customer Details
  static Future<CustomerDetails> getCustomerInfo(int customerID) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/MeterReading/GetCustomerInfo?ClientCODE=$tenantId&CustomerID=$customerID'),
      headers: {
        'accept': 'text/plain',
        'Authorization': 'Bearer $_authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CustomerDetails.fromJson(data);
    } else {
      throw Exception('Failed to get customer info: ${response.statusCode}');
    }
  }

  // Get Consumption History
  static Future<ConsumptionHistoryResponse> getConsumptionHistory(int customerID) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('No auth token available. Please login first.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/MeterReading/GetConsumptionHistory'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'clientCODE': tenantId,
        'customerID': customerID,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ConsumptionHistoryResponse.fromJson(data);
    } else {
      throw Exception('Failed to get consumption history: ${response.statusCode}');
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

    final response = await http.post(
      Uri.parse('$baseUrl/api/MeterReading/GetCustomerStatement'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'clientCODE': tenantId,
        'customerID': customerID,
        'fromDate': fromDate,
        'toDate': toDate,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CustomerStatementResponse.fromJson(data);
    } else {
      throw Exception('Failed to get statement: ${response.statusCode}');
    }
  }
}