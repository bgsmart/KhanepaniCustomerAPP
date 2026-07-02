// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/customer_details.dart';
import '../models/consumption_history.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  CustomerDetails? _customerDetails;
  ConsumptionHistoryResponse? _consumptionHistory;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _authToken;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  CustomerDetails? get customerDetails => _customerDetails;
  ConsumptionHistoryResponse? get consumptionHistory => _consumptionHistory;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;
  String? get errorMessage => _errorMessage;

  // Fixed admin credentials from config
  static const String _adminUsername = AppConfig.adminUsername;
  static const String _adminPassword = AppConfig.adminPassword;

  AuthProvider() {
    _loadStoredData();
  }

  // Load stored authentication data
  Future<void> _loadStoredData() async {
    try {
      final token = await SecureStorageService.getToken();
      final customerId = await SecureStorageService.getCustomerId();
      
      if (token != null && customerId != null) {
        _authToken = token;
        ApiService.setToken(token);
        
        // Try to restore customer details
        try {
          final details = await ApiService.getCustomerInfo(int.parse(customerId));
          _customerDetails = details;
          _currentUser = User(
            id: details.cusID,
            name: details.name,
            // email: details.email ?? '',
            phone: details.phone,
            customerId: details.cusID,
          );
          _isAuthenticated = true;
          
          // Get consumption history
          try {
            final history = await ApiService.getConsumptionHistory(int.parse(customerId));
            _consumptionHistory = history;
          } catch (e) {
            print('Error loading consumption history: $e');
            // Don't fail the whole load if consumption history fails
            _consumptionHistory = ConsumptionHistoryResponse(
              success: false,
              data: [],
              count: 0,
              customerID: int.parse(customerId),
            );
          }
          
          notifyListeners();
        } catch (e) {
          // If token is invalid, clear it
          await SecureStorageService.clearAll();
          _authToken = null;
          _isAuthenticated = false;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading stored data: $e');
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Login with username and password (gets token)
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginResponse = await ApiService.login(username, password);
      _authToken = loginResponse.token;
      ApiService.setToken(_authToken!);
      
      // Save token to secure storage
      await SecureStorageService.saveToken(_authToken!);
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to authenticate: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Validate customer with token
  Future<bool> validateCustomer(int customerID, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First, ensure we have a valid token
      if (_authToken == null || _authToken!.isEmpty) {
        final loginSuccess = await login(_adminUsername, _adminPassword);
        if (!loginSuccess) {
          _errorMessage = 'Failed to authenticate with server';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Validate customer
      final validation = await ApiService.validateCustomer(
        customerID: customerID,
        password: password,
      );

      if (validation.responseCode == 200) {
        // Get customer details
        final details = await ApiService.getCustomerInfo(validation.customerID);
        _customerDetails = details;

        // Get consumption history
        try {
          final history = await ApiService.getConsumptionHistory(validation.customerID);
          _consumptionHistory = history;
        } catch (e) {
          print('Error loading consumption history: $e');
          _consumptionHistory = ConsumptionHistoryResponse(
            success: false,
            data: [],
            count: 0,
            customerID: validation.customerID,
          );
        }

        // Create user from customer details
        _currentUser = User(
          id: details.cusID,
          name: details.name,
          // email: details.email ?? '',
          phone: details.phone,
          customerId: details.cusID,
        );

        // Save customer ID
        await SecureStorageService.saveCustomerId(customerID.toString());

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = validation.responseMessage.isNotEmpty 
            ? validation.responseMessage 
            : 'Invalid Customer ID or Password';
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on Exception catch (e) {
      String errorMsg = 'Login failed. Please try again.';
      final errorStr = e.toString();
      
      if (errorStr.contains('401')) {
        errorMsg = 'Invalid credentials. Please check your Customer ID and Password.';
        // If token expired, clear it and try to refresh
        await SecureStorageService.clearAll();
        _authToken = null;
        ApiService.setToken(null);
      } else if (errorStr.contains('404')) {
        errorMsg = 'Customer not found. Please check your Customer ID.';
      } else if (errorStr.contains('500')) {
        errorMsg = 'Server error. Please try again later.';
      } else if (errorStr.contains('timeout') || errorStr.contains('Failed to connect')) {
        errorMsg = 'Connection error. Please check your internet connection.';
      } else {
        errorMsg = errorStr.replaceFirst('Exception: ', '');
      }
      
      _errorMessage = errorMsg;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Combined login (get token + validate customer)
  Future<bool> loginWithCustomer({
    required String username,
    required String password,
    required int customerID,
    required String customerPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Login to get token
      final loginResponse = await ApiService.login(username, password);
      _authToken = loginResponse.token;
      ApiService.setToken(_authToken!);
      
      // Save token to secure storage
      await SecureStorageService.saveToken(_authToken!);

      // Step 2: Validate customer
      final validation = await ApiService.validateCustomer(
        customerID: customerID,
        password: customerPassword,
      );

      if (validation.responseCode == 200) {
        // Step 3: Get customer details
        final details = await ApiService.getCustomerInfo(validation.customerID);
        _customerDetails = details;

        // Step 4: Get consumption history
        try {
          final history = await ApiService.getConsumptionHistory(validation.customerID);
          _consumptionHistory = history;
        } catch (e) {
          print('Error loading consumption history: $e');
          _consumptionHistory = ConsumptionHistoryResponse(
            success: false,
            data: [],
            count: 0,
            customerID: validation.customerID,
          );
        }

        _currentUser = User(
          id: details.cusID,
          name: details.name,
          // email: details.email ?? '',
          phone: details.phone,
          customerId: details.cusID,
        );

        // Save customer ID
        await SecureStorageService.saveCustomerId(customerID.toString());

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = validation.responseMessage.isNotEmpty 
            ? validation.responseMessage 
            : 'Invalid Customer ID or Password';
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on Exception catch (e) {
      String errorMsg = 'Login failed. Please try again.';
      final errorStr = e.toString();
      
      if (errorStr.contains('401')) {
        errorMsg = 'Invalid admin credentials. Please check your username and password.';
        // If token expired, clear it
        await SecureStorageService.clearAll();
        _authToken = null;
        ApiService.setToken(null);
      } else if (errorStr.contains('404')) {
        errorMsg = 'Customer not found. Please check your Customer ID.';
      } else if (errorStr.contains('500')) {
        errorMsg = 'Server error. Please try again later.';
      } else if (errorStr.contains('timeout') || errorStr.contains('Failed to connect')) {
        errorMsg = 'Connection error. Please check your internet connection.';
      } else {
        errorMsg = errorStr.replaceFirst('Exception: ', '');
      }
      
      _errorMessage = errorMsg;
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Simplified login - just customer ID and password (uses fixed admin credentials)
  Future<bool> loginWithCustomerSimple({
    required int customerID,
    required String password,
  }) async {
    return loginWithCustomer(
      username: _adminUsername,
      password: _adminPassword,
      customerID: customerID,
      customerPassword: password,
    );
  }

  // Refresh customer data (for dashboard updates)
  Future<void> refreshCustomerData(int customerID) async {
    try {
      // Ensure we have a valid token
      if (_authToken == null || _authToken!.isEmpty) {
        final success = await login(_adminUsername, _adminPassword);
        if (!success) {
          throw Exception('Failed to refresh token');
        }
      }
      
      // Get customer details
      final details = await ApiService.getCustomerInfo(customerID);
      _customerDetails = details;

      // Get consumption history
      try {
        final history = await ApiService.getConsumptionHistory(customerID);
        _consumptionHistory = history;
      } catch (e) {
        print('Error refreshing consumption history: $e');
        // Keep existing history or set empty
        if (_consumptionHistory == null) {
          _consumptionHistory = ConsumptionHistoryResponse(
            success: false,
            data: [],
            count: 0,
            customerID: customerID,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing customer data: $e');
      // If token expired, clear and let user login again
      if (e.toString().contains('401')) {
        await logout();
      }
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _customerDetails = null;
    _consumptionHistory = null;
    _isAuthenticated = false;
    _authToken = null;
    _errorMessage = null;
    ApiService.setToken(null);
    
    // Clear secure storage
    await SecureStorageService.clearAll();
    
    notifyListeners();
  }

  // Check if user is authenticated with valid token
  Future<bool> checkAuthentication() async {
    try {
      final token = await SecureStorageService.getToken();
      final customerId = await SecureStorageService.getCustomerId();
      
      if (token != null && customerId != null) {
        _authToken = token;
        ApiService.setToken(token);
        _isAuthenticated = true;
        
        // Refresh customer data
        await refreshCustomerData(int.parse(customerId));
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  // Update settings (runtime config changes)
  static void updateSettings(String baseUrl, int tenantId) {
    ApiService.setBaseUrl(baseUrl);
    ApiService.setTenantId(tenantId);
  }

  // Get consumption data for graph
  List<ConsumptionData> getConsumptionData() {
    if (_consumptionHistory != null) {
      return _consumptionHistory!.data;
    }
    return [];
  }

  // Get last 6 months consumption data
  List<ConsumptionData> getLastSixMonthsConsumption() {
    final data = getConsumptionData();
    if (data.length > 6) {
      return data.sublist(data.length - 6);
    }
    return data;
  }

  // Get consumption values as list of doubles
  List<double> getConsumptionValues() {
    return getConsumptionData().map((e) => e.consumption.toDouble()).toList();
  }

  // Get months as list of strings
  List<String> getConsumptionMonths() {
    return getConsumptionData().map((e) => e.month).toList();
  }
}