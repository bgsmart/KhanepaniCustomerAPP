// lib/models/payment_topic.dart
class PaymentTopic {
  final String sn;
  final String name;
  double rate;
  bool isSelected;

  PaymentTopic({
    required this.sn,
    required this.name,
    required this.rate,
    this.isSelected = false,
  });

  factory PaymentTopic.fromJson(Map<String, dynamic> json) {
    return PaymentTopic(
      sn: json['sn'] ?? '',
      name: json['name'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }

  PaymentTopic copyWith({
    String? sn,
    String? name,
    double? rate,
    bool? isSelected,
  }) {
    return PaymentTopic(
      sn: sn ?? this.sn,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sn': sn,
      'name': name,
      'rate': rate,
      'isSelected': isSelected,
    };
  }
}