import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5000/api', // Android emulator → localhost
);

const FlutterSecureStorage _storage = FlutterSecureStorage();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // JWT Interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'orbit_access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          // Try token refresh
          final refreshToken = await _storage.read(key: 'orbit_refresh_token');
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: _kBaseUrl));
              final res = await refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
              final newToken = res.data['accessToken'];
              await _storage.write(key: 'orbit_access_token', value: newToken);
              // Retry original request
              err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryRes = await _dio.fetch(err.requestOptions);
              handler.resolve(retryRes);
              return;
            } catch (_) {
              await _storage.deleteAll();
            }
          }
        }
        handler.next(err);
      },
    ));
  }

  Dio get dio => _dio;

  // Convenience methods
  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}

final apiClient = ApiClient();
