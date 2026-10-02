class ReceiptModel {
  final bool success;
  final String message;
  final String responseCode;
  final String strValues;

  ReceiptModel({
    required this.success,
    required this.message,
    required this.responseCode,
    required this.strValues,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      responseCode: json['responseCode'] ?? '',
      strValues: json['strValues'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'responseCode': responseCode,
      'strValues': strValues,
    };
  }
}