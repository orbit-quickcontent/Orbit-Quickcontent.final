import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccessToken = 'orbit_access_token';
const _kRefreshToken = 'orbit_refresh_token';

class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? email;
  final String? name;
  final String? role;
  final String? accessToken;

  const AuthState({
    this.isLoggedIn = false,
    this.userId,
    this.email,
    this.name,
    this.role,
    this.accessToken,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    String? email,
    String? name,
    String? role,
    String? accessToken,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    name: name ?? this.name,
    role: role ?? this.role,
    accessToken: accessToken ?? this.accessToken,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  AuthNotifier() : super(const AuthState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final token = await _storage.read(key: _kAccessToken);
      if (token != null) {
        final userId = await _storage.read(key: 'orbit_user_id');
        final email = await _storage.read(key: 'orbit_user_email');
        final name = await _storage.read(key: 'orbit_user_name');
        final role = await _storage.read(key: 'orbit_user_role');
        state = AuthState(
          isLoggedIn: true,
          accessToken: token,
          userId: userId,
          email: email,
          name: name,
          role: role,
        );
      }
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }

  Future<void> setAuthenticated({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: 'orbit_user_id', value: user['id']),
      _storage.write(key: 'orbit_user_email', value: user['email']),
      _storage.write(key: 'orbit_user_name', value: user['name'] ?? ''),
      _storage.write(key: 'orbit_user_role', value: user['role']),
    ]);

    state = AuthState(
      isLoggedIn: true,
      accessToken: accessToken,
      userId: user['id'],
      email: user['email'],
      name: user['name'],
      role: user['role'],
    );
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
