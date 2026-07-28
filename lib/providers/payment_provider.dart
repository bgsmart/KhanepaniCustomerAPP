// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/payment_topic.dart';
import '../config/app_config.dart';

class PaymentProvider extends ChangeNotifier {
  List<PaymentTopic> _topics = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  double _totalAmount = 0.0;
  String _paymentStatus = '';

  // Getters
  List<PaymentTopic> get topics => _topics;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  double get totalAmount => _totalAmount;
  String get paymentStatus => _paymentStatus;
  int get selectedCount => _topics.where((t) => t.isSelected).length;
  List<PaymentTopic> get selectedTopics => _topics.where((t) => t.isSelected).toList();

  // ✅ FIXED: Fetch payment topics from API using GET method
  Future<bool> fetchTopics(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ Use GET method with query parameter
      final url = Uri.parse(
        '${AppConfig.baseUrl}/api/MeterReading/GetTopics?ClientCODE=${AppConfig.tenantId}'
      );
      
      print('🔗 URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Get Topics Response Status: ${response.statusCode}');
      print('📡 Get Topics Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> topicsData = data['data'] ?? [];
          _topics = topicsData.map((item) => PaymentTopic.fromJson(item)).toList();
          _calculateTotal();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Failed to load payment options';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Failed to load payment options (${response.statusCode})';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error fetching topics: $e');
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Toggle topic selection
  void toggleSelection(String sn) {
    final index = _topics.indexWhere((topic) => topic.sn == sn);
    if (index != -1) {
      _topics[index] = _topics[index].copyWith(
        isSelected: !_topics[index].isSelected,
      );
      _calculateTotal();
      notifyListeners();
    }
  }

  // Select all topics
  void selectAll() {
    for (var i = 0; i < _topics.length; i++) {
      _topics[i] = _topics[i].copyWith(isSelected: true);
    }
    _calculateTotal();
    notifyListeners();
  }

  // Deselect all topics
  void deselectAll() {
    for (var i = 0; i < _topics.length; i++) {
      _topics[i] = _topics[i].copyWith(isSelected: false);
    }
    _calculateTotal();
    notifyListeners();
  }

  // Calculate total amount
  void _calculateTotal() {
    _totalAmount = _topics.fold(
      0.0,
      (sum, topic) => topic.isSelected ? sum + topic.rate : sum,
    );
  }

  // Process payment with String customerId (converts to int internally)
  Future<bool> processPayment({
    required String token,
    required String customerId,
    required List<PaymentTopic> selectedTopics,
  }) async {
    _isProcessing = true;
    _paymentStatus = 'Processing payment...';
    _errorMessage = null;
    notifyListeners();

    try {
      // Convert customerId to int safely
      final int customerIdInt = int.tryParse(customerId) ?? 0;
      
      if (customerIdInt == 0) {
        _errorMessage = 'Invalid Customer ID';
        _paymentStatus = 'Payment failed';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      final paymentData = {
        'clientCode': AppConfig.tenantId,
        'customerId': customerIdInt,
        'amount': _totalAmount,
        'topics': selectedTopics.map((t) => {
          'sn': t.sn,
          'name': t.name,
          'rate': t.rate,
        }).toList(),
        'paymentDate': DateTime.now().toIso8601String(),
      };

      print('💳 Processing Payment: ${jsonEncode(paymentData)}');
      print('📝 Customer ID: $customerIdInt');

      // Send payment request to API
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/Payment/Process'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(paymentData),
      );

      print('📡 Payment Response Status: ${response.statusCode}');
      print('📡 Payment Response Body: ${response.body}');

      _isProcessing = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _paymentStatus = 'Payment successful!';
          clearSelection();
          notifyListeners();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Payment processing failed';
          _paymentStatus = 'Payment failed';
          notifyListeners();
          return false;
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please login again.';
        _paymentStatus = 'Authentication failed';
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Payment processing failed (${response.statusCode})';
        _paymentStatus = 'Payment failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Payment Error: $e');
      _errorMessage = 'Network error: ${e.toString()}';
      _paymentStatus = 'Payment failed';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Process payment with int customerId (convenience method)
  Future<bool> processPaymentWithInt({
    required String token,
    required int customerId,
    required List<PaymentTopic> selectedTopics,
  }) async {
    return processPayment(
      token: token,
      customerId: customerId.toString(),
      selectedTopics: selectedTopics,
    );
  }

  // Clear selection
  void clearSelection() {
    for (var i = 0; i < _topics.length; i++) {
      _topics[i] = _topics[i].copyWith(isSelected: false);
    }
    _calculateTotal();
    notifyListeners();
  }

  // Reset provider
  void reset() {
    _topics = [];
    _isLoading = false;
    _isProcessing = false;
    _errorMessage = null;
    _totalAmount = 0.0;
    _paymentStatus = '';
    notifyListeners();
  }

  // Update topic rate
  void updateTopicRate(String sn, double newRate) {
    final index = _topics.indexWhere((topic) => topic.sn == sn);
    if (index != -1) {
      _topics[index] = _topics[index].copyWith(rate: newRate);
      _calculateTotal();
      notifyListeners();
    }
  }
}