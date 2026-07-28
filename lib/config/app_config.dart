// lib/config/app_config.dart
class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://103.68.40.118:88';
  static const int tenantId = 2;
  
  // Admin Credentials
  static const String adminUsername = 'admin';
  static const String adminPassword = 'admin@0011';

//Company Information
  static const String companyName = 'हेटौडा खानेपानी ब्यवस्थापन वोर्ड';
  static const String companyAddress = 'हेटौडा २, मकवानपुर';
  static const String companyPhone = '+977 057-520000';
  static const String companyEmail = 'info@hetudawater.gov.np';
  
  // App Configuration
  static const String appName = 'HWSMBOARD';
  static const String appVersion = '1.0.0';
  
  // Date Formats
  static const String dateFormat = 'yyyy/MM/dd';
  static const String apiDateFormat = 'yyyy/MM/dd';
  
  // Timeouts
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Shared Preferences Keys
  static const String prefTokenKey = 'auth_token';
  static const String prefRememberMeKey = 'remember_me';
  static const String prefCustomerIdKey = 'customer_id';
  
  // ✅ Get full API URL (can be const getter)
  static String get apiUrl => baseUrl;
  
  // ✅ Get API endpoint (now uses const)
  static String getEndpoint(String path) => '$baseUrl$path';
  
  // ✅ Nepali month names with const
  static const List<String> nepaliMonths = [
    'बैशाख', 'जेठ', 'असार', 'साउन', 
    'भदौ', 'असोज', 'कात्तिक', 'मंसिर', 
    'पुष', 'माघ', 'फागुन', 'चैत'
  ];
  
  // ✅ Month number to Nepali name mapping (improved with switch)
  static String getNepaliMonth(int monthNumber) {
    switch (monthNumber) {
      case 1: return 'बैशाख';
      case 2: return 'जेठ';
      case 3: return 'असार';
      case 4: return 'साउन';
      case 5: return 'भदौ';
      case 6: return 'असोज';
      case 7: return 'कात्तिक';
      case 8: return 'मंसिर';
      case 9: return 'पुष';
      case 10: return 'माघ';
      case 11: return 'फागुन';
      case 12: return 'चैत';
      default: return '';
    }
  }
  
  // ✅ Convert month from API format to Nepali (improved)
  static String convertMonthToNepali(String monthStr) {
    try {
      final parts = monthStr.split('/');
      if (parts.length == 2) {
        final monthNum = int.tryParse(parts[1]);
        if (monthNum != null) {
          return getNepaliMonth(monthNum);
        }
      }
      return monthStr;
    } catch (e) {
      return monthStr;
    }
  }
  
  // ✅ Get current date in API format
  static String getCurrentDate() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }
  
  // ✅ Get current month for API
  static String getCurrentMonth() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    return '$year/$month';
  }
  
  // ✅ Get default date range (last 12 months)
  static Map<String, String> getDefaultDateRange() {
    final now = DateTime.now();
    final fromDate = DateTime(now.year - 1, now.month, now.day);
    final toDate = now;
    
    return {
      'fromDate': '${fromDate.year}/${fromDate.month.toString().padLeft(2, '0')}/${fromDate.day.toString().padLeft(2, '0')}',
      'toDate': '${toDate.year}/${toDate.month.toString().padLeft(2, '0')}/${toDate.day.toString().padLeft(2, '0')}',
    };
  }
  
  // ✅ Check if token is valid (for debugging)
  static bool isValidToken(String? token) {
    return token != null && token.isNotEmpty && token.length > 20;
  }
  
  // ✅ Get short app name for display
  static String getShortAppName() {
    return 'HWSMBOARD';
  }
  
  // ✅ Get full app name with version
  static String getFullAppName() {
    return '$appName v$appVersion';
  }
}