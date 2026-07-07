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

  // Change Password Method
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_authToken == null || _authToken!.isEmpty) {
        final loginSuccess = await login(_adminUsername, _adminPassword);
        if (!loginSuccess) {
          _errorMessage = 'Failed to authenticate with server';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final response = await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Password change failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on Exception catch (e) {
      String errorMsg = 'Failed to change password. Please try again.';
      final errorStr = e.toString();
      
      if (errorStr.contains('401')) {
        errorMsg = 'Current password is incorrect or session expired.';
        await SecureStorageService.clearAll();
        _authToken = null;
        ApiService.setToken(null);
      } else if (errorStr.contains('404')) {
        errorMsg = 'Password change endpoint not found. Please contact support.';
      } else if (errorStr.contains('500')) {
        errorMsg = 'Server error. Please try again later.';
      } else {
        errorMsg = errorStr.replaceFirst('Exception: ', '');
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update Password (Alternative endpoint using customer ID)
  Future<bool> updatePassword({
    required int customerID,
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_authToken == null || _authToken!.isEmpty) {
        final loginSuccess = await login(_adminUsername, _adminPassword);
        if (!loginSuccess) {
          _errorMessage = 'Failed to authenticate with server';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final response = await ApiService.updatePassword(
        customerID: customerID,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Password update failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on Exception catch (e) {
      String errorMsg = 'Failed to update password. Please try again.';
      final errorStr = e.toString();
      
      if (errorStr.contains('401')) {
        errorMsg = 'Old password is incorrect or session expired.';
        await SecureStorageService.clearAll();
        _authToken = null;
        ApiService.setToken(null);
      } else if (errorStr.contains('404')) {
        errorMsg = 'Password update endpoint not found. Please contact support.';
      } else if (errorStr.contains('500')) {
        errorMsg = 'Server error. Please try again later.';
      } else {
        errorMsg = errorStr.replaceFirst('Exception: ', '');
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ Forgot Password Method
  Future<bool> forgotPassword({
    required int customerID,
    required String mobile,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure we have a valid token
      if (_authToken == null || _authToken!.isEmpty) {
        final loginSuccess = await login(_adminUsername, _adminPassword);
        if (!loginSuccess) {
          _errorMessage = 'Failed to authenticate with server';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final response = await ApiService.forgotPassword(
        customerID: customerID,
        mobile: mobile,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to reset password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on Exception catch (e) {
      String errorMsg = 'Failed to reset password. Please try again.';
      final errorStr = e.toString();
      
      if (errorStr.contains('401')) {
        errorMsg = 'Session expired. Please login again.';
        await SecureStorageService.clearAll();
        _authToken = null;
        ApiService.setToken(null);
      } else if (errorStr.contains('404')) {
        errorMsg = 'API endpoint not found. Please contact support.';
      } else if (errorStr.contains('409')) {
        errorMsg = 'Customer ID or mobile number not found. Please check your details.';
      } else if (errorStr.contains('500')) {
        errorMsg = 'Server error. Please try again later.';
      } else if (errorStr.contains('timeout') || errorStr.contains('Failed to connect')) {
        errorMsg = 'Connection error. Please check your internet connection.';
      } else {
        errorMsg = errorStr.replaceFirst('Exception: ', '');
      }
      
      _errorMessage = errorMsg;
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
      final loginResponse = await ApiService.login(username, password);
      _authToken = loginResponse.token;
      ApiService.setToken(_authToken!);
      await SecureStorageService.saveToken(_authToken!);

      final validation = await ApiService.validateCustomer(
        customerID: customerID,
        password: customerPassword,
      );

      if (validation.responseCode == 200) {
        final details = await ApiService.getCustomerInfo(validation.customerID);
        _customerDetails = details;

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
          phone: details.phone,
          customerId: details.cusID,
        );

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
      if (_authToken == null || _authToken!.isEmpty) {
        final success = await login(_adminUsername, _adminPassword);
        if (!success) {
          throw Exception('Failed to refresh token');
        }
      }
      
      final details = await ApiService.getCustomerInfo(customerID);
      _customerDetails = details;

      try {
        final history = await ApiService.getConsumptionHistory(customerID);
        _consumptionHistory = history;
      } catch (e) {
        print('Error refreshing consumption history: $e');
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

}