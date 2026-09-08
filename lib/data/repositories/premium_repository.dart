import '../network/base_api_service.dart';
import '../../utils/constants.dart';

class PremiumRepository {
  final BaseApiService apiProvider;

  PremiumRepository(this.apiProvider);

  Future<dynamic> getPlans({String platform = 'hinge'}) async {
    try {
      String url = AppConstants.planList;
      if (platform == 'website') {
        url += "?platform=website";
      }
      final response = await apiProvider.getApi(url);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> subscribeToPlan(String planId, {String? promoCode, String platform = 'hinge'}) async {
    try {
      final Map<String, dynamic> data = {
        "planId": planId,
        "platform": platform,
      };
      if (promoCode != null && promoCode.isNotEmpty) {
        data["promoCode"] = promoCode;
      }
      
      final response = await apiProvider.postApi(
        AppConstants.buyPlan,
        data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getSubscriptionStatus({String platform = 'hinge'}) async {
    try {
      String url = AppConstants.planCheck;
      if (platform == 'website') {
        url += "?platform=website";
      }

      final response = await apiProvider.getApi(url);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> redeemVoucher(String code) async {
    try {
      final response = await apiProvider.postApi(
        AppConstants.redeemVoucher,
        {"code": code},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
