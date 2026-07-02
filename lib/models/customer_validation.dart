// lib/models/customer_validation.dart
class CustomerValidation {
  final int responseCode;
  final String responseMessage;
  final int customerID;
  final String customerName;
  final String mobile;

  CustomerValidation({
    required this.responseCode,
    required this.responseMessage,
    required this.customerID,
    required this.customerName,
    required this.mobile,
  });

  factory CustomerValidation.fromJson(Map<String, dynamic> json) {
    return CustomerValidation(
      responseCode: json['responseCode'] ?? 0,
      responseMessage: json['responseMessage'] ?? '',
      customerID: json['customerID'] ?? 0,
      customerName: json['customerName'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }
}

