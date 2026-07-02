// lib/providers/company_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company.dart';
import 'dart:convert';

class CompanyProvider extends ChangeNotifier {
  Company _company = Company.defaultCompany;
  bool _isLoading = false;
  String? _errorMessage;

  Company get company => _company;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters for easy access
  String get name => _company.name;
  String get address => _company.address;
  String get phone => _company.phone;
  String get email => _company.email;
  String get logoPath => _company.logoPath;
  String get website => _company.website;
  String get panNumber => _company.panNumber;
  String get registrationNumber => _company.registrationNumber;

  CompanyProvider() {
    _loadCompanyData();
  }

  // Load company data from shared preferences
  Future<void> _loadCompanyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? companyJson = prefs.getString('company_data');
      
      if (companyJson != null) {
        final Map<String, dynamic> jsonMap = json.decode(companyJson);
        _company = Company.fromJson(jsonMap);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading company data: $e');
      // Use default company if loading fails
      _company = Company.defaultCompany;
    }
  }

  // Save company data to shared preferences
  Future<void> saveCompanyData(Company company) async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('company_data', json.encode(company.toJson()));
      
      _company = company;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to save company data: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Update specific fields
  Future<void> updateCompany({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
    String? website,
    String? panNumber,
    String? registrationNumber,
  }) async {
    final updatedCompany = _company.copyWith(
      name: name,
      address: address,
      phone: phone,
      email: email,
      logoPath: logoPath,
      website: website,
      panNumber: panNumber,
      registrationNumber: registrationNumber,
    );
    await saveCompanyData(updatedCompany);
  }

  // Reset to default company
  Future<void> resetToDefault() async {
    await saveCompanyData(Company.defaultCompany);
  }

  // Clear company data (logout)
  Future<void> clearCompanyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('company_data');
      _company = Company.defaultCompany;
      notifyListeners();
    } catch (e) {
      print('Error clearing company data: $e');
    }
  }
}