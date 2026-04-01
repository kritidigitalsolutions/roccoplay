import '../network/base_api_service.dart';
import '../../utils/constants.dart';

class PremiumRepository {
  final BaseApiService apiProvider;

  PremiumRepository(this.apiProvider);

  Future<dynamic> getPlans() async {
    try {
      final response = await apiProvider.getApi(AppConstants.planList);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> subscribeToPlan(String planId) async {
    try {
      final response = await apiProvider.postApi(
        AppConstants.buyPlan,
        {"planId": planId},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getSubscriptionStatus() async {
    try {
      final response = await apiProvider.getApi(AppConstants.planCheck);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
