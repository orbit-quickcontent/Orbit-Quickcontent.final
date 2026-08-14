import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PartnerAuthState {
  final bool isLoggedIn;
  final bool needsOnboarding;
  final String? partnerId;
  final String? userId;
  final String? name;
  final String? email;
  final String? accessToken;
  final bool isOnline;
  final bool isAvailable;

  const PartnerAuthState({
    this.isLoggedIn = false,
    this.needsOnboarding = false,
    this.partnerId,
    this.userId,
    this.name,
    this.email,
    this.accessToken,
    this.isOnline = false,
    this.isAvailable = false,
  });

  PartnerAuthState copyWith({
    bool? isLoggedIn,
    bool? needsOnboarding,
    String? partnerId,
    String? userId,
    String? name,
    String? email,
    String? accessToken,
    bool? isOnline,
    bool? isAvailable,
  }) => PartnerAuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    needsOnboarding: needsOnboarding ?? this.needsOnboarding,
    partnerId: partnerId ?? this.partnerId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    email: email ?? this.email,
    accessToken: accessToken ?? this.accessToken,
    isOnline: isOnline ?? this.isOnline,
    isAvailable: isAvailable ?? this.isAvailable,
  );
}

class PartnerAuthNotifier extends StateNotifier<PartnerAuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  PartnerAuthNotifier() : super(const PartnerAuthState()) {
    _load();
  }

  Future<void> _load() async {
    final token = await _storage.read(key: 'orbit_partner_token');
    if (token == null) return;
    state = PartnerAuthState(
      isLoggedIn: true,
      accessToken: token,
      userId: await _storage.read(key: 'orbit_partner_user_id'),
      partnerId: await _storage.read(key: 'orbit_partner_id'),
      name: await _storage.read(key: 'orbit_partner_name'),
      email: await _storage.read(key: 'orbit_partner_email'),
      needsOnboarding: (await _storage.read(key: 'orbit_partner_onboarded')) != 'true',
    );
  }

  Future<void> setAuthenticated({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
    required Map<String, dynamic>? partner,
  }) async {
    await Future.wait([
      _storage.write(key: 'orbit_partner_token', value: accessToken),
      _storage.write(key: 'orbit_partner_refresh', value: refreshToken),
      _storage.write(key: 'orbit_partner_user_id', value: user['id']),
      _storage.write(key: 'orbit_partner_name', value: user['name'] ?? ''),
      _storage.write(key: 'orbit_partner_email', value: user['email']),
      if (partner != null) _storage.write(key: 'orbit_partner_id', value: partner['id']),
    ]);

    state = PartnerAuthState(
      isLoggedIn: true,
      accessToken: accessToken,
      userId: user['id'],
      name: user['name'],
      email: user['email'],
      partnerId: partner?['id'],
      needsOnboarding: partner == null || partner['status'] != 'ACTIVE',
      isOnline: partner?['isOnline'] ?? false,
    );
  }

  Future<void> completedOnboarding() async {
    await _storage.write(key: 'orbit_partner_onboarded', value: 'true');
    state = state.copyWith(needsOnboarding: false);
  }

  Future<void> setOnlineStatus(bool isOnline) async {
    state = state.copyWith(isOnline: isOnline, isAvailable: isOnline);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const PartnerAuthState();
  }

  Future<String?> getToken() => _storage.read(key: 'orbit_partner_token');
}

final partnerAuthProvider = StateNotifierProvider<PartnerAuthNotifier, PartnerAuthState>(
  (ref) => PartnerAuthNotifier(),
);
