import 'dart:convert';

import 'package:KhanepaniApp/models/UtilityPayementModelResponse.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharePreference {
  static const String userName = "userName";
  static const String utilityPayment = "utilityPayment";
  static const String receiptCode = "receiptCode";

  static Future setUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  static Future setUtilityPayment(
      UtilityPayementModelResponse utilityPaymentva) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        utilityPayment, json.encode(utilityPaymentva.toJson()));
  }

  static Future<UtilityPayementModelResponse?> getUtilityPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(utilityPayment);
    if (jsonString != null) {
      final jsonMap = json.decode(jsonString);
      return UtilityPayementModelResponse.fromJson(jsonMap);
    }
    return null;
  }
  static Future setReceiptCode(String receiptCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receiptCode', receiptCode);
  }

  static Future<String?> getReceiptCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('receiptCode');
  }
}
