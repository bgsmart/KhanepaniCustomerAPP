class UtilityPayementModelResponse {
  final bool? success;
  final String? code;
  final String? message;
  final String? deeplink;
  final String? bookingId;
  final String? correlationId;

  UtilityPayementModelResponse({
    this.success,
    this.code,
    this.message,
    this.deeplink,
    this.bookingId,
    this.correlationId,
  });

  factory UtilityPayementModelResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return UtilityPayementModelResponse(
      success: json['success'] as bool?,
      code: json['code'] as String?,
      message: json['message'] as String?,
      deeplink: json['deeplink'] as String?,
      bookingId: json['booking_id'] as String?,
      correlationId: json['correlation_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'code': code,
      'message': message,
      'deeplink': deeplink,
      'booking_id': bookingId,
      'correlation_id': correlationId,
    };
  }
}