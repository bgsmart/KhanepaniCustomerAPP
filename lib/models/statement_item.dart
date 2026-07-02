// lib/models/statement_item.dart
import 'package:flutter/material.dart';

class StatementItem {
  final String sn;
  final String date;
  final int units;
  final double amount;
  final String status;

  StatementItem({
    required this.sn,
    required this.date,
    required this.units,
    required this.amount,
    required this.status,
  });

  factory StatementItem.fromJson(Map<String, dynamic> json) {
    return StatementItem(
      sn: json['sn']?.toString() ?? '0',
      date: json['date'] ?? '',
      units: json['units'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }

  // Helper properties
  bool get isPayment => status.toLowerCase() == 'receipt';
  bool get isBill => status.toLowerCase() == 'billing';
  
  String get displayStatus => isPayment ? 'Payment' : 'Bill';
  String get displayStatusShort => isPayment ? 'Paid' : 'Pending';
  
  Color getStatusColor(ColorScheme colorScheme) {
    return isPayment ? colorScheme.secondary : colorScheme.primary;
  }
  
  IconData getStatusIcon() {
    return isPayment ? Icons.credit_card : Icons.receipt_long;
  }
}