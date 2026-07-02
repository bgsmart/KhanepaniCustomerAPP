// lib/models/statement_response.dart
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
}

class StatementResponse {
  final bool success;
  final List<StatementItem> data;
  final int count;
  final int customerID;

  StatementResponse({
    required this.success,
    required this.data,
    required this.count,
    required this.customerID,
  });

  factory StatementResponse.fromJson(Map<String, dynamic> json) {
    return StatementResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => StatementItem.fromJson(item))
          .toList() ?? [],
      count: json['count'] ?? 0,
      customerID: json['customerID'] ?? 0,
    );
  }

  // Get total outstanding (sum of all Billing amounts)
  double get totalOutstanding {
    return data
        .where((item) => item.isBill)
        .fold(0.0, (sum, item) => sum + item.amount);
  }
}