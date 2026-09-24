import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../../utils/app_session.dart';
import '../exception/app_exception.dart';
import 'base_api_service.dart';

class NetworkApiService extends BaseApiService {
  late Dio _dio;

  NetworkApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {"Content-Type": "application/json"},
      ),
    );

    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    /// Interceptor for dynamic token and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ✅ AUTOMATICALLY ADD TOKEN FROM STORAGE EVERY TIME
          String? token = AppSession.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          debugPrint("🌐 [API REQ] ${options.method} ${options.uri}");
          if (options.data != null) {
            debugPrint("📤 [API REQ DATA] ${options.data}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint("✅ [API RES] ${response.requestOptions.method} ${response.requestOptions.uri} (${response.statusCode})");
          debugPrint("📥 [API RES DATA] ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint("❌ [API ERR] ${e.requestOptions.method} ${e.requestOptions.uri}");
          debugPrint("⚠️ [API ERR DETAILS] ${e.response?.statusCode} - ${e.response?.data ?? e.message}");
          return handler.next(e);
        },
      ),
    );
  }

  /// 🔑 Set Authorization Token
  void setToken(String token) {
    _dio.options.headers["Authorization"] = "Bearer $token";
  }

  /// ❌ Remove Token (Logout)
  void clearToken() {
    _dio.options.headers.remove("Authorization");
  }

  @override
  Future<dynamic> getApi(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _dio.get(url, options: Options(headers: headers));
      return returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<dynamic> postApi(String url, dynamic data,
      {Map<String, String>? headers}) async {
    try {
      final response = await _dio.post(url, data: data, options: Options(headers: headers));
      return returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<dynamic> pacthApi(String url, dynamic data,
      {Map<String, String>? headers}) async {
    try {
      final response = await _dio.patch(url, data: data, options: Options(headers: headers));
      return returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<dynamic> putApi(String url, dynamic data,
      {Map<String, String>? headers}) async {
    try {
      final response = await _dio.put(url, data: data, options: Options(headers: headers));
      return returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<dynamic> deleteApi(String url, dynamic data,
      {Map<String, String>? headers}) async {
    try {
      final response = await _dio.delete(url, data: data, options: Options(headers: headers));
      return returnResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return FetchDataException("Connection timeout");

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.data.toString() ?? "Unknown error";

        if (statusCode == 400) {
          return BadRequestException(message);
        } else if (statusCode == 401 || statusCode == 403) {
          return UnauthorizedException(message);
        } else if (statusCode == 500) {
          return FetchDataException("Server Error");
        } else {
          return FetchDataException(
            "Error occurred with status code : $statusCode",
          );
        }

      case DioExceptionType.cancel:
        return FetchDataException("Request cancelled");

      case DioExceptionType.unknown:
      default:
        if (kIsWeb) {
          return FetchDataException(
            "Connection failed. This might be a CORS issue on the server. Please check the browser console.",
          );
        }
        return FetchDataException("No Internet Connection");
    }
  }
}

dynamic returnResponse(Response response) {
  switch (response.statusCode) {
    case 200:
    case 201:
      return response.data;

    case 400:
      throw BadRequestException(response.data.toString());

    case 401:
    case 403:
      throw UnauthorizedException(response.data.toString());

    case 500:
    default:
      throw FetchDataException(
        "Error occurred with status code : ${response.statusCode}",
      );
  }
}
