// lib/models/transaction.dart
class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // bill, payment, discount, penalty
  final String status; // paid, unpaid, cleared
  final String? invoiceNumber;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    this.invoiceNumber,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? 'bill',
      status: json['status'] ?? 'unpaid',
      invoiceNumber: json['invoiceNumber'],
    );
  }

  bool get isCredit => amount < 0;
  bool get isDebit => amount > 0;
}