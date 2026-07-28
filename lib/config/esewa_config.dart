// lib/config/esewa_config.dart
class EsewaConfigConstants {
  // ✅ Access Key for development
  static const String accessKey = 'LB0REg8HUSw3MTYrI1s6JTE8Kyc6JyAqJiA3MQ==';
  
  // ✅ Product Code
  static const String productCode = 'INTENT';
  
  // ✅ API Base URL (Test Environment)
  static const String baseUrl = 'https://rc-checkout.esewa.com.np/api/client/intent/payment';
  
  // ✅ Deeplink Base URL
  static const String deeplinkBaseUrl = 'https://rc-links.esewa.com.np/pay/';
  
  // ✅ Callback URL (Your server endpoint)
  static const String callbackUrl = 'https://your-server.com/api/payment/callback';
  
  // ✅ Redirect URL (Where user goes after payment)
  static const String redirectUrl = 'https://your-server.com/payment/complete';
  
  // ✅ For production, use these URLs
  // static const String baseUrl = 'https://checkout.esewa.com.np/api/client/intent/payment';
  // static const String deeplinkBaseUrl = 'https://links.esewa.com.np/pay/';
}