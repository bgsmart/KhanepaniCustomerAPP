// lib/services/esewa_intent_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../config/esewa_config.dart';

class EsewaIntentService {
  static const String baseUrl = 'https://rc-checkout.esewa.com.np/api/client/intent/payment';
  static const String productCode = 'INTENT';
  
  // ✅ Access Key for development
  static const String accessKey = 'LB0REg8HUSw3MTYrI1s6JTE8Kyc6JyAqJiA3MQ==';

  // ✅ Generate HMAC SHA256 Signature
  static String generateSignature(Map<String, String> params, String accessKey) {
    // Step 1: Create message from signed fields
    final signedFields = params['signed_field_names']?.split(',') ?? [];
    final message = signedFields.map((field) => params[field] ?? '').join(',');
    
    // Step 2: Generate HMAC SHA256 hash
    final key = utf8.encode(accessKey);
    final msg = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(msg);
    
    // Step 3: Encode to Base64
    return base64.encode(digest.bytes);
  }

  // ✅ Initialize/Book Payment
  static Future<Map<String, dynamic>> bookPayment({
    required String amount,
    required String transactionUuid,
    required String callbackUrl,
    required String redirectUrl,
    required Map<String, String> properties,
  }) async {
    try {
      // Prepare signed fields
      final signedFieldNames = ['product_code', 'amount', 'transaction_uuid'];
      final params = {
        'product_code': productCode,
        'amount': amount,
        'transaction_uuid': transactionUuid,
        'signed_field_names': signedFieldNames.join(','),
      };

      // Generate signature
      final signature = generateSignature(params, accessKey);
      
      // Prepare request body
      final requestBody = {
        'product_code': productCode,
        'amount': amount,
        'transaction_uuid': transactionUuid,
        'signed_field_names': signedFieldNames.join(','),
        'signature': signature,
        'callback_url': callbackUrl,
        'redirect_url': redirectUrl,
        'properties': properties,
      };

      print('📝 eSewa Book Payment Request:');
      print(jsonEncode(requestBody));

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/book'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 eSewa Book Payment Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['code'] == 'IP-200',
          'data': data['data'],
          'message': data['message'],
          'code': data['code'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error_message'] ?? 'Booking failed',
          'code': data['code'] ?? 'ERROR',
        };
      }
    } catch (e) {
      print('❌ eSewa Book Payment Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ✅ Check Payment Status
  static Future<Map<String, dynamic>> checkStatus({
    required String bookingId,
    required String correlationId,
  }) async {
    try {
      // Prepare signed fields
      final signedFieldNames = ['booking_id', 'product_code', 'correlation_id'];
      final params = {
        'booking_id': bookingId,
        'product_code': productCode,
        'correlation_id': correlationId,
        'signed_field_names': signedFieldNames.join(','),
      };

      // Generate signature
      final signature = generateSignature(params, accessKey);
      
      // Prepare request body
      final requestBody = {
        'booking_id': bookingId,
        'product_code': productCode,
        'correlation_id': correlationId,
        'signed_field_names': signedFieldNames.join(','),
        'signature': signature,
      };

      print('📝 eSewa Status Check Request:');
      print(jsonEncode(requestBody));

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 eSewa Status Check Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['code'] == 'IP-200',
          'data': data['data'],
          'message': data['message'],
          'code': data['code'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error_message'] ?? 'Status check failed',
          'code': data['code'] ?? 'ERROR',
        };
      }
    } catch (e) {
      print('❌ eSewa Status Check Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ✅ Cancel Payment
  static Future<Map<String, dynamic>> cancelPayment({
    required String bookingId,
  }) async {
    try {
      // Prepare signed fields
      final signedFieldNames = ['booking_id', 'product_code'];
      final params = {
        'booking_id': bookingId,
        'product_code': productCode,
        'signed_field_names': signedFieldNames.join(','),
      };

      // Generate signature
      final signature = generateSignature(params, accessKey);
      
      // Prepare request body
      final requestBody = {
        'booking_id': bookingId,
        'product_code': productCode,
        'signed_field_names': signedFieldNames.join(','),
        'signature': signature,
      };

      print('📝 eSewa Cancel Payment Request:');
      print(jsonEncode(requestBody));

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 eSewa Cancel Payment Response: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['code'] == 'IP-210',
          'data': data['data'],
          'message': data['message'],
          'code': data['code'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error_message'] ?? 'Cancellation failed',
          'code': data['code'] ?? 'ERROR',
        };
      }
    } catch (e) {
      print('❌ eSewa Cancel Payment Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ✅ Verify Callback Signature
  static bool verifyCallbackSignature(Map<String, dynamic> callbackData) {
    try {
      final signedFields = (callbackData['signed_field_names'] as String).split(',');
      final params = <String, String>{};
      
      for (var field in signedFields) {
        params[field] = callbackData[field]?.toString() ?? '';
      }
      
      final providedSignature = callbackData['signature'] as String;
      final expectedSignature = generateSignature(params, accessKey);
      
      return providedSignature == expectedSignature;
    } catch (e) {
      print('❌ Callback verification error: $e');
      return false;
    }
  }
}

// ✅ Helper class for eSewa Payment Response
class EsewaPaymentResponse {
  final bool success;
  final String? bookingId;
  final String? deeplink;
  final String? correlationId;
  final String? message;
  final String? code;

  EsewaPaymentResponse({
    required this.success,
    this.bookingId,
    this.deeplink,
    this.correlationId,
    this.message,
    this.code,
  });

  factory EsewaPaymentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return EsewaPaymentResponse(
      success: json['code'] == 'IP-200',
      bookingId: data['booking_id'],
      deeplink: data['deeplink'],
      correlationId: data['correlation_id'],
      message: json['message'],
      code: json['code'],
    );
  }
}