import 'package:dio/dio.dart';
import 'package:fleet_management/core/config/app_config.dart';

/// Base API Service
/// Handles HTTP requests with error handling and token management
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      followRedirects: false,
      validateStatus: (status) => status != null && status < 400,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Redirect interceptor: manually follow 3xx redirects so Authorization
    // header is preserved (dart:io HttpClient drops custom headers on redirect)
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) async {
        final status = response.statusCode;
        if (status != null && status >= 300 && status < 400) {
          final location = response.headers.value('location');
          if (location != null) {
            // Parse the redirect URL so we can separate path from query params
            final uri = location.startsWith('http')
                ? Uri.parse(location)
                : Uri.parse('http://placeholder$location');

            // Use path only (no query string) + redirect URL's query params
            // to avoid duplicating params that were already in requestOptions
            final newOptions = response.requestOptions.copyWith(
              path: uri.path,
              queryParameters: uri.hasQuery
                  ? Uri.splitQueryString(uri.query)
                  : response.requestOptions.queryParameters,
            );
            final newResponse = await _dio.fetch(newOptions);
            handler.resolve(newResponse);
            return;
          }
        }
        handler.next(response);
      },
    ));

    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Dio get dio => _dio;

  /// Set authentication token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    print('🔑 Token set in API service: ${token.substring(0, 20)}...');
  }

  /// Remove authentication token
  void removeToken() {
    _dio.options.headers.remove('Authorization');
    print('🔑 Token removed from API service');
  }

  /// Handle API errors
  String handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';

        case DioExceptionType.badResponse:
          if (error.response?.data != null) {
            if (error.response!.data is Map &&
                error.response!.data.containsKey('detail')) {
              return error.response!.data['detail'];
            }
          }
          return 'Server error: ${error.response?.statusCode}';

        case DioExceptionType.cancel:
          return 'Request cancelled';

        case DioExceptionType.unknown:
        default:
          return 'Network error. Please check your connection.';
      }
    }

    return 'An unexpected error occurred';
  }
}
