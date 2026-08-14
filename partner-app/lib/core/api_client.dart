import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000/api');
const FlutterSecureStorage _storage = FlutterSecureStorage();

class PartnerApiClient {
  static final PartnerApiClient _instance = PartnerApiClient._internal();
  factory PartnerApiClient() => _instance;

  late final Dio _dio;

  PartnerApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _kBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) async {
        final token = await _storage.read(key: 'orbit_partner_token');
        if (token != null) opts.headers['Authorization'] = 'Bearer $token';
        handler.next(opts);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          final refresh = await _storage.read(key: 'orbit_partner_refresh');
          if (refresh != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: _kBase));
              final res = await refreshDio.post('/auth/refresh', data: {'refreshToken': refresh});
              final newToken = res.data['accessToken'];
              await _storage.write(key: 'orbit_partner_token', value: newToken);
              err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryRes = await _dio.fetch(err.requestOptions);
              handler.resolve(retryRes);
              return;
            } catch (_) { await _storage.deleteAll(); }
          }
        }
        handler.next(err);
      },
    ));
  }

  Dio get dio => _dio;
  Future<Response> get(String path, {Map<String, dynamic>? params}) => _dio.get(path, queryParameters: params);
  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);
  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);
  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);
}

final partnerApiClient = PartnerApiClient();
