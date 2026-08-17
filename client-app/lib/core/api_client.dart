import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://orbit-quickcontent-final.orbit-quickcontent.workers.dev',
);

const FlutterSecureStorage _storage = FlutterSecureStorage();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // JWT Interceptor + Offline Fallback
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
          final refreshToken = await _storage.read(key: 'orbit_refresh_token');
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: _kBaseUrl));
              final res = await refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
              final newToken = res.data['accessToken'];
              await _storage.write(key: 'orbit_access_token', value: newToken);
              err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryRes = await _dio.fetch(err.requestOptions);
              handler.resolve(retryRes);
              return;
            } catch (_) {
              await _storage.deleteAll();
            }
          }
        }

        // Offline / Unreachable fallback so APK works standalone
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
    final method = req.method.toUpperCase();

    if (path.contains('/auth/send-otp')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {'success': true, 'message': 'Verification code sent to your email (Demo code: 123456)'},
      );
    }

    if (path.contains('/auth/verify-otp')) {
      final email = req.data is Map ? req.data['email'] ?? 'test@example.com' : 'test@example.com';
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {
          'success': true,
          'accessToken': 'demo_access_token_${DateTime.now().millisecondsSinceEpoch}',
          'refreshToken': 'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 'user_demo_1',
            'name': 'Test User',
            'email': email,
            'role': 'CLIENT',
            'persona': 'Creator',
          },
        },
      );
    }

    if (path.contains('/auth/me')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {
          'id': 'user_demo_1',
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '+91 9876543210',
          'role': 'CLIENT',
          'persona': 'Creator',
        },
      );
    }

    if (path.contains('/packages')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: [
          {
            'id': 'pkg_creator_personalized',
            'name': 'Personalized',
            'focus': 'Individual creators, personal events',
            'priceDisplay': 1999,
            'popular': false,
            'features': [
              '1 cinematic reel (30-60 sec)',
              'Professional color grading',
              'Background score licensing',
              'Same-day delivery (60-90 mins)',
              '1 revision round',
              'Ideal for active content creators',
            ],
          },
          {
            'id': 'pkg_creator_ugc_pro',
            'name': 'Professional (UGC)',
            'focus': 'Brands, businesses, template creators',
            'priceDisplay': 4999,
            'popular': true,
            'features': [
              '3 cinematic reels (30-60 sec each)',
              'Brand DNA integration (logo, palette, font)',
              'Professional color grading & stabilization',
              'Licensed premium sound scores',
              'Same-day express delivery (90-120 mins)',
              '2 revision rounds with master editor',
              'Dedicated creator-editor sync',
            ],
          },
        ],
      );
    }

    if (path.contains('/bookings')) {
      if (method == 'POST') {
        return Response(
          requestOptions: req,
          statusCode: 200,
          data: {
            'bookingId': 'bk_demo_${DateTime.now().millisecondsSinceEpoch}',
            'status': 'DISPATCHING',
            'package': {'name': 'Personalized', 'priceDisplay': 1999},
            'payment': {'keyId': 'rzp_test_demo', 'amount': 199900, 'currency': 'INR', 'orderId': 'order_demo_123'},
          },
        );
      }
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: {
          'bookings': [
            {
              'id': 'bk_demo_1',
              'status': 'DELIVERED',
              'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
              'address': 'Kartar Mansion, 35, Dr Dadasaheb Bhadkamkar Marg',
              'package': {'name': 'Personalized', 'priceDisplay': 1999},
              'partner': {'user': {'name': 'Arjun Mehta'}},
              'partnerSalary': 700,
            },
            {
              'id': 'bk_demo_2',
              'status': 'DELIVERED',
              'createdAt': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
              'address': 'WeWork Enam Sambhav, BKC, Mumbai',
              'package': {'name': 'Professional (UGC)', 'priceDisplay': 4999},
              'partner': {'user': {'name': 'Rohan Shah'}},
              'partnerSalary': 1800,
            },
          ],
        },
      );
    }

    if (path.contains('/notifications')) {
      return Response(
        requestOptions: req,
        statusCode: 200,
        data: [
          {
            'id': 'n1',
            'title': 'Shoot Completed',
            'body': 'Your video footage has been uploaded and sent to express editing.',
            'isRead': false,
          },
          {
            'id': 'n2',
            'title': 'Welcome to Orbit',
            'body': 'Explore available packages and book your first 60-minute shoot.',
            'isRead': true,
          },
        ],
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

  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);
  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
}

final apiClient = ApiClient();
