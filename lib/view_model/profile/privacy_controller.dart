import 'package:get/get.dart';
import '../../data/providers/privacy_provider.dart';

class PrivacyController extends GetxController {
  var privacyTitle = "".obs;
  var privacyContent = "".obs;
  
  var termsTitle = "".obs;
  var termsContent = "".obs;
  
  var refundTitle = "".obs;
  var refundContent = "".obs;

  var helpData = <dynamic>[].obs;

  var isLoadingPrivacy = true.obs;
  var isLoadingTerms = true.obs;
  var isLoadingRefund = true.obs;
  var isLoadingHelp = true.obs;

  Future<void> fetchPrivacyPolicy() async {
    isLoadingPrivacy.value = true;
    final data = await PrivacyService.getPrivacyPolicy();
    if (data != null) {
      privacyTitle.value = data['document']['title'] ?? "";
      privacyContent.value = data['document']['content'] ?? "";
    }
    isLoadingPrivacy.value = false;
  }

  Future<void> fetchTerms() async {
    isLoadingTerms.value = true;
    final data = await PrivacyService.getTerms();
    if (data != null) {
      termsTitle.value = data['document']['title'] ?? "";
      termsContent.value = data['document']['content'] ?? "";
    }
    isLoadingTerms.value = false;
  }

  Future<void> fetchRefundPolicy() async {
    isLoadingRefund.value = true;
    final data = await PrivacyService.getRefundPolicy();
    if (data != null) {
      refundTitle.value = data['document']['title'] ?? "";
      refundContent.value = data['document']['content'] ?? "";
    }
    isLoadingRefund.value = false;
  }

  Future<void> fetchHelpData() async {
    isLoadingHelp.value = true;
    final data = await PrivacyService.getHelpData();
    helpData.assignAll(data);
    await fetchSupportContactInfo(); // Fetch support info too
    isLoadingHelp.value = false;
  }

  var supportNumber = "".obs;
  var supportEmail = "".obs;
  var isNumberHide = true.obs; // Default to true to avoid flashing empty cards
  var isEmailHide = true.obs;

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) {
      return value == 1;
    }
    return false;
  }

  Future<void> fetchSupportContactInfo() async {
    try {
      final numberData = await PrivacyService.getSupportNumber();
      if (numberData != null && _parseBool(numberData['success'])) {
        supportNumber.value = numberData['supportNumber'] ??
            numberData['contactNumber'] ??
            supportNumber.value;
        isNumberHide.value = _parseBool(numberData['isHide']);
      }
    } catch (e) {
      print("Error fetching support number: $e");
    }

    try {
      final emailData = await PrivacyService.getSupportEmail();
      if (emailData != null && _parseBool(emailData['success'])) {
        supportEmail.value = emailData['supportEmail'] ??
            emailData['email'] ??
            supportEmail.value;
        isEmailHide.value = _parseBool(emailData['isHide']);
      }
    } catch (e) {
      print("Error fetching support email: $e");
    }
  }
}
