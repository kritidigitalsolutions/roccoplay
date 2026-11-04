import '../network/base_api_service.dart';
import '../../utils/app_session.dart';
import '../../utils/constants.dart';
import '../models/response_model/popup_model/app_popup_model.dart';

class PopupRepository {
  final BaseApiService apiProvider;

  PopupRepository(this.apiProvider);

  /// 📥 Fetch Active Popup from Backend
  Future<AppPopupResponseModel?> getActivePopup({String? token}) async {
    try {
      final String? userToken = token ?? AppSession.getToken();
      final Map<String, String> headers = {};
      if (userToken != null && userToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await apiProvider.getApi(
        AppConstants.getActivePopup,
        headers: headers.isNotEmpty ? headers : null,
      );
      if (response != null && response is Map<String, dynamic>) {
        return AppPopupResponseModel.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 📤 Record Action Button Clicked / Dismissed with User Token
  Future<bool> markActionCompleted(String popupId, {String? token}) async {
    if (popupId.isEmpty) return false;
    try {
      final String? userToken = token ?? AppSession.getToken();

      final Map<String, dynamic> body = {};
      final Map<String, String> headers = {};

      if (userToken != null && userToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $userToken';
        body['token'] = userToken;
      }

      final response = await apiProvider.postApi(
        AppConstants.actionCompletedPopup(popupId),
        body,
        headers: headers.isNotEmpty ? headers : null,
      );
      if (response != null && response['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
