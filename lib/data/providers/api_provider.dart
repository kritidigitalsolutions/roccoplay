import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import 'dart:io' if (dart.library.html) 'package:roccoplay/utils/io_stub.dart' as io;

class ApiProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = AppConstants.baseUrl;
    httpClient.timeout = const Duration(seconds: 30);
    super.onInit();
  }

  Future<Response> sendOtp(String phoneNumber) {
    return post(AppConstants.sendOtp, {
      'identifier': phoneNumber,
      'type': 'phone',
    });
  }

  Future<Response> verifyOtp(String phoneNumber, String otp) async {
    // Body: {"identifier": "...", "otp": "...", "type": "phone"}
    final res = await post(AppConstants.verifyOtp, {
      'identifier': phoneNumber,
      'otp': otp,
      'type': 'phone',
    });

    return res;
  }

  /// Create Profile with Image Upload
  Future<Response> createProfile({
    required String phone,
    required String name,
    required String email,
    required String age,
    String? imagePath,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "phone": phone,
        "name": name,
        "email": email,
        "age": age,
      };

      if (imagePath != null) {
        if (!kIsWeb) {
          final file = io.File(imagePath);
          if ((file as dynamic).existsSync()) {
            body["profileImage"] = MultipartFile(
              (file as dynamic).readAsBytesSync(),
              filename: imagePath.split('/').last,
            );
          }
        } else {
          // On Web, imagePath might be a Blob URL or we might need to handle bytes differently.
          // For now, if it's just a path string, we might not be able to read it as a File.
          // In a real web app, we'd pass bytes to this method.
        }
      }

      final formData = FormData(body);
      final response = await post(
        AppConstants.createProfile,
        formData,
      );

      return response;
    } catch (e) {
      return Response(statusCode: 500, statusText: e.toString());
    }
  }
}
