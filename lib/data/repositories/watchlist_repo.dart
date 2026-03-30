import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../../utils/constants.dart';
import '../models/response_model/watchlist_response/watchlist_response.dart';
import '../providers/api_provider.dart';

class WatchlistRepo {
  final ApiProvider apiProvider;

  WatchlistRepo({required this.apiProvider});

  Future<WatchlistResponseModel?> addToWatchlist(String movieId) async {
    try {
      final storage = GetStorage();
      String? token = storage.read('token');

      if (token == null || token.isEmpty) {
        throw Exception("User not logged in");
      }

      final response = await apiProvider.post(
        AppConstants.addWatchlist,
        {
          "movieId": movieId,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return WatchlistResponseModel.fromJson(
          response.body is String
              ? jsonDecode(response.body)
              : response.body,
        );
      } else {
        print("API ERROR: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception in addToWatchlist: $e");
      rethrow;
    }
  }
}
