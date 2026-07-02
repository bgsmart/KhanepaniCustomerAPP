// lib/providers/reading_provider.dart
import 'package:flutter/material.dart';
import '../models/reading.dart';
import '../models/transaction.dart';

class ReadingProvider extends ChangeNotifier {
  List<Reading> _readings = [];
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Reading> get readings => _readings;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  ReadingProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    _readings = [
      Reading(
        id: '1',
        meterId: 'AF-9928-X02',
        previousReading: 1042,
        currentReading: 1066,
        unitsConsumed: 24,
        readingDate: DateTime(2023, 6, 15),
        submittedDate: DateTime(2023, 6, 15),
        status: 'approved',
      ),
      Reading(
        id: '2',
        meterId: 'AF-9928-X02',
        previousReading: 1022,
        currentReading: 1042,
        unitsConsumed: 20,
        readingDate: DateTime(2023, 5, 15),
        submittedDate: DateTime(2023, 5, 15),
        status: 'approved',
      ),
      Reading(
        id: '3',
        meterId: 'AF-9928-X02',
        previousReading: 991,
        currentReading: 1022,
        unitsConsumed: 31,
        readingDate: DateTime(2023, 4, 15),
        submittedDate: DateTime(2023, 4, 15),
        status: 'approved',
      ),
    ];

    _transactions = [
      Transaction(
        id: '1',
        description: 'Monthly Water Bill',
        amount: 124.80,
        date: DateTime(2023, 9, 24),
        type: 'bill',
        status: 'unpaid',
        invoiceNumber: 'AF-8821',
      ),
      Transaction(
        id: '2',
        description: 'Late Payment Penalty',
        amount: 18.00,
        date: DateTime(2023, 9, 15),
        type: 'penalty',
        status: 'unpaid',
      ),
      Transaction(
        id: '3',
        description: 'Rounding Adjustment',
        amount: -0.30,
        date: DateTime(2023, 9, 12),
        type: 'discount',
        status: 'cleared',
      ),
      Transaction(
        id: '4',
        description: 'Bill Payment',
        amount: -115.40,
        date: DateTime(2023, 8, 28),
        type: 'payment',
        status: 'cleared',
        invoiceNumber: 'Visa ****4242',
      ),
      Transaction(
        id: '5',
        description: 'Loyalty Discount',
        amount: -5.00,
        date: DateTime(2023, 8, 20),
        type: 'discount',
        status: 'cleared',
      ),
    ];

    notifyListeners();
  }

  Future<void> submitReading(int currentReading, DateTime readingDate) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final previous = _readings.isNotEmpty ? _readings.first.currentReading : 0;
    _readings.insert(0, Reading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      meterId: 'AF-9928-X02',
      previousReading: previous,
      currentReading: currentReading,
      unitsConsumed: currentReading - previous,
      readingDate: readingDate,
      submittedDate: DateTime.now(),
      status: 'pending',
    ));

    _isLoading = false;
    notifyListeners();
  }
}