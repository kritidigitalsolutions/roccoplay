import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roccoplay/utils/constants.dart';

class PrivacyService {
  static Future<Map<String, dynamic>?> getPrivacyPolicy() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.privacyPolicyUrl),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Error handled by returning null
    }
    return null;
  }

/// terms and conditions
  static Future<Map<String, dynamic>?> getTerms() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.termsAndConditionsUrl),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Error handled by returning null
    }
    return null;
  }
/// refund policy
  static Future<Map<String, dynamic>?> getRefundPolicy() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.refundPolicy),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Error handled by returning null
    }
    return null;
  }
/// help & support
  static Future<List<dynamic>> getHelpData() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.helpSupport),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['helpData'] ?? [];
      }
    } catch (e) {
      // Error handled by returning empty list
    }
    return [];
  }

  /// get support number
  static Future<Map<String, dynamic>?> getSupportNumber() async {
    try {
      final response = await http.get(Uri.parse(AppConstants.supportNumber));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Error handled by returning null
    }
    return null;
  }

  /// get support email
  static Future<Map<String, dynamic>?> getSupportEmail() async {
    try {
      final response = await http.get(Uri.parse(AppConstants.supportEmail));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Error handled by returning null
    }
    return null;
  }
}
