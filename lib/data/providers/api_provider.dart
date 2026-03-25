import 'dart:io';
import 'package:get/get.dart';
import '../../utils/constants.dart';

class ApiProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = AppConstants.baseUrl;
    httpClient.timeout = const Duration(seconds: 30);
    super.onInit();
  }

  Future<Response> sendOtp(String phoneNumber) {
    return post(AppConstants.sendOtp, {
      'phone': phoneNumber,
    });
  }

  Future<Response> verifyOtp(String phoneNumber, String otp) async {
    final res = await post(AppConstants.verifyOtp, {
      'phone': phoneNumber,
      'otp': otp,
    });
    return res;
  }

  /// Create Profile with Image Upload
  Future<Response> createProfile({
    required String phone,
    required String name,
    required String email,
    // required String imagePath,
  }) async {
    try {
      // final file = File(imagePath);
      // if (!file.existsSync()) {
      //   return const Response(statusCode: 400, statusText: "Image file not found");
      // }

      final formData = FormData({
        "phone": phone,
        "name": name,
        "email": email,
        // "profileImage": MultipartFile(
        //   file.readAsBytesSync(),
        //   filename: imagePath.split('/').last,
        // ),
      });

      print("📤 SENDING CREATE PROFILE DATA...");
      print("Fields: phone=$phone, name=$name, email=$email");
      // print("Image Path: $imagePath");

      final response = await post(
        AppConstants.createProfile,
        formData,
      );

      return response;
    } catch (e) {
      print("❌ EXCEPTION IN createProfile Provider: $e");
      return Response(statusCode: 500, statusText: e.toString());
    }
  }
}
