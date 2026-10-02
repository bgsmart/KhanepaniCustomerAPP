class EsewaPaymentStatusModel {
  final bool success;
  final String code;
  final String message;
  final String status;
  final String bookingId;
  final String correlationId;
  final String transactionId;
  final String updatedAt;

  EsewaPaymentStatusModel({
    required this.success,
    required this.code,
    required this.message,
    required this.status,
    required this.bookingId,
    required this.correlationId,
    required this.transactionId,
    required this.updatedAt,
  });

  factory EsewaPaymentStatusModel.fromJson(Map<String, dynamic> json) {
    return EsewaPaymentStatusModel(
      success: json['success'] ?? false,
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? '',
      bookingId: json['booking_id'] ?? '',
      correlationId: json['correlation_id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'code': code,
      'message': message,
      'status': status,
      'booking_id': bookingId,
      'correlation_id': correlationId,
      'transaction_id': transactionId,
      'updated_at': updatedAt,
    };
  }
}