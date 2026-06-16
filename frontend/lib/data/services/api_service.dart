import 'package:dio/dio.dart';
import 'package:fleet_management/core/config/app_config.dart';

/// Base API Service
/// Handles HTTP requests with error handling and token management
class ApiService {
  late final Dio _dio;
  String get baseUrl => AppConfig.apiBaseUrl;

  Future<bool> Function()? _onRefresh;
  Future<void> Function()? _onLogout;

  /// Wire up auth callbacks so the 401 interceptor can refresh / force-logout.
  void setAuthCallbacks({
    required Future<bool> Function() onRefresh,
    required Future<void> Function() onLogout,
  }) {
    _onRefresh = onRefresh;
    _onLogout  = onLogout;
  }

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
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        // Auto-handle 401: try refresh once, then force logout
        if (error.response?.statusCode == 401 && _onRefresh != null) {
          // Don't retry auth or refresh endpoints — those failures are not retryable
          final path = error.requestOptions.path;
          final isAuthCall = path.contains('/refresh-token') ||
              path.contains('/auth/login') ||
              path.contains('/auth/signup');
          if (!isAuthCall) {
            final refreshed = await _onRefresh!();
            if (refreshed) {
              // Retry original request with the updated token
              try {
                final opts = error.requestOptions;
                opts.headers['Authorization'] = _dio.options.headers['Authorization'];
                final retryResponse = await _dio.fetch(opts);
                handler.resolve(retryResponse);
                return;
              } catch (_) {
                // retry also failed — fall through to logout
              }
            }
            // Only logout if the failed path is one the user is authorized to access.
            // 401 on LP-only endpoints (stages, claims) for a load_owner are
            // permission errors — do not log the user out.
            final isLpOnly = path.contains('/claim-stage') ||
                path.contains('/submit-stage') ||
                path.contains('/stage/') ||
                path.contains('/save-draft');
            if (!isLpOnly) {
              await _onLogout?.call();
            }
          }
        }
        handler.next(error);
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
    // Strip ALL whitespace (including embedded \n from Android Keystore base64-wrapping)
    final clean = token.replaceAll(RegExp(r'\s+'), '');
    _dio.options.headers['Authorization'] = 'Bearer $clean';
    print('🔑 Token set in API service: ${clean.substring(0, clean.length.clamp(0, 20))}...');
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

        case DioExceptionType.connectionError:
          return 'Cannot connect to server. Please check your connection.';

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
