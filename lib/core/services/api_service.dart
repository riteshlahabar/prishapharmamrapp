import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Dio-based API service for Prisha Pharma MR.
class ApiService {
  late final Dio _dio;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': AppConstants.contentType,
        'Accept': AppConstants.contentType,
      },
    ));
  }

  /// Add auth interceptor to attach the token to every request.
  void setupAuthInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers[AppConstants.authHeader] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid - trigger logout
          _clearAuth();
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  // ─── GET ──────────────────────────────────────────────────────
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  // ─── POST ─────────────────────────────────────────────────────
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  // ─── PUT ──────────────────────────────────────────────────────
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  // ─── PATCH ────────────────────────────────────────────────────
  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  // ─── DELETE ───────────────────────────────────────────────────
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  // ─── POST with FormData (file uploads) ────────────────────────
  Future<Response> postFormData(String path, FormData formData) {
    return _dio.post(path, data: formData);
  }

  // ─── Convenience: Login ───────────────────────────────────────
  Future<Response> login({required String email, required String password}) {
    return post(AppConstants.loginEndpoint, data: {
      'email': email,
      'password': password,
    });
  }

  // ─── Convenience: Get Profile ─────────────────────────────────
  Future<Response> getProfile() {
    return get(AppConstants.profileEndpoint);
  }
}
