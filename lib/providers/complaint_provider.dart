// lib/providers/complaint_provider.dart
import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/api_service.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<Complaint> get complaints => _complaints;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // Submit complaint
  Future<bool> submitComplaint({
    required String customerId,
    required String complaintType,
    required String subject,
    required String description,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final complaint = Complaint(
        customerId: customerId,
        complaintType: complaintType,
        subject: subject,
        description: description,
        location: location,
        latitude: latitude,
        longitude: longitude,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      final response = await ApiService.submitComplaint(complaint);
      
      if (response['success'] == true) {
        if (response['data'] != null) {
          final newComplaint = Complaint.fromJson(response['data']);
          _complaints.insert(0, newComplaint);
        }
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to submit complaint';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // Load complaints
  Future<bool> loadComplaints(String customerId) async {
    if (customerId.isEmpty) {
      _isLoading = false;
      return false;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getComplaints(customerId);
      
      if (response['success'] == true && response['data'] != null) {
        _complaints = List<Complaint>.from(
          response['data'].map((x) => Complaint.fromJson(x))
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load complaints';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear complaints
  void clearComplaints() {
    _complaints = [];
    notifyListeners();
  }
}