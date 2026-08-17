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
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
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
            } catch (_) {
              await _storage.deleteAll();
            }
          }
        }

        // Offline / Unreachable fallback so Partner APK works standalone
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.unknown) {
          final mockResponse = _generateMockResponse(err.requestOptions);
          if (mockResponse != null) {
            handler.resolve(mockResponse);
            return;
          }
        }

        handler.next(err);
      },
    ));
  }

  Response? _generateMockResponse(RequestOptions req) {
    final path = req.path;

    if (path.contains('/auth/send-otp')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {'success': true, 'message': 'Verification code sent to your email (Demo code: 123456)'},
      );
    }

    if (path.contains('/auth/verify-otp')) {
      final email = req.data is Map ? req.data['email'] ?? 'utkarshssg2608@gmail.com' : 'utkarshssg2608@gmail.com';
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {
          'success': true,
          'accessToken': 'demo_partner_token_${DateTime.now().millisecondsSinceEpoch}',
          'refreshToken': 'demo_partner_refresh_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 'partner_user_1',
            'name': 'utkarsh gupta',
            'email': email,
            'role': 'PARTNER',
          },
          'partner': {
            'id': 'partner_1',
            'status': 'ACTIVE',
            'displayName': 'utkarsh gupta',
            'rating': 5.0,
            'completedProjects': 12,
            'activeProjects': 0,
            'walletBalance': 8400,
          },
        },
      );
    }

    if (path.contains('/partner/profile')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {
          'displayName': 'utkarsh gupta',
          'user': {
            'name': 'utkarsh gupta',
            'email': 'utkarshssg2608@gmail.com',
          },
          'rating': 5.0,
          'completedProjects': 12,
          'activeProjects': 0,
          'walletBalance': 8400,
        },
      );
    }

    if (path.contains('/partner/earnings')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {
          'totalEarned': 8400,
          'monthEarned': 2800,
          'weekEarned': 1400,
          'completedCount': 12,
          'rating': 5.0,
        },
      );
    }

    if (path.contains('/partner/available-jobs')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {
          'jobs': [
            {
              'id': 'job_demo_1',
              'address': 'Bandra West, Mumbai (2.4 km away)',
              'partnerSalary': 700,
              'package': {'name': 'Personalized Reel Shoot', 'priceDisplay': 1999},
            },
            {
              'id': 'job_demo_2',
              'address': 'Koramangala 4th Block, Bengaluru',
              'partnerSalary': 1800,
              'package': {'name': 'Professional Brand DNA Shoot', 'priceDisplay': 4999},
            },
          ],
        },
      );
    }

    if (path.contains('/partner/history')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {
          'jobs': [
            {
              'id': 'job_past_1',
              'status': 'DELIVERED',
              'partnerSalary': 700,
              'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
              'package': {'name': 'Personalized Shoot'},
            },
            {
              'id': 'job_past_2',
              'status': 'DELIVERED',
              'partnerSalary': 1800,
              'createdAt': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
              'package': {'name': 'Professional UGC Shoot'},
            },
          ],
        },
      );
    }

    return null;
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      return await _dio.get(path, queryParameters: params);
    } on DioException {
      rethrow;
    } catch (e) {
      final mock = _generateMockResponse(RequestOptions(path: path, method: 'GET', queryParameters: params));
      if (mock != null) return mock;
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException {
      rethrow;
    } catch (e) {
      final mock = _generateMockResponse(RequestOptions(path: path, method: 'POST', data: data));
      if (mock != null) return mock;
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);
  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);
}

final partnerApiClient = PartnerApiClient();
