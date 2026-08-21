import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'analytics_event.dart';

/// ORBIT Partner Behavioural Analytics Service
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final Queue<AnalyticsEvent> _eventQueue = Queue<AnalyticsEvent>();
  Timer? _flushTimer;
  String? _partnerId;
  String? _sessionId;
  DateTime? _screenEnterTime;
  String? _currentScreen;

  void init({String? partnerId}) {
    _partnerId = partnerId;
    _sessionId = 'sess_ptr_${DateTime.now().millisecondsSinceEpoch}';
    _startFlushTimer();
    trackEvent(AnalyticsEventType.sessionStarted, 'session_started', {
      'sessionId': _sessionId,
      'platform': defaultTargetPlatform.name,
    });
  }

  void setPartnerId(String? id) {
    _partnerId = id;
  }

  void trackEvent(AnalyticsEventType type, String name, [Map<String, dynamic>? parameters]) {
    final params = Map<String, dynamic>.from(parameters ?? {});
    if (_partnerId != null) params['partnerId'] = _partnerId;
    if (_sessionId != null) params['sessionId'] = _sessionId;

    final event = AnalyticsEvent(
      type: type,
      name: name,
      parameters: params,
    );

    _eventQueue.add(event);

    if (kDebugMode) {
      debugPrint('[Partner Analytics] ${event.name} -> ${event.parameters}');
    }

    if (_eventQueue.length >= 20) {
      flush();
    }
  }

  void trackScreenView(String screenName) {
    if (_currentScreen != null && _screenEnterTime != null) {
      final durationMs = DateTime.now().difference(_screenEnterTime!).inMilliseconds;
      trackEvent(AnalyticsEventType.screenViewed, 'screen_duration', {
        'screen': _currentScreen,
        'durationMs': durationMs,
      });
    }

    _currentScreen = screenName;
    _screenEnterTime = DateTime.now();

    trackEvent(AnalyticsEventType.screenViewed, 'screen_viewed', {
      'screenName': screenName,
    });
  }

  void trackButtonClick(String buttonName, {String? screen, Map<String, dynamic>? extra}) {
    final params = <String, dynamic>{
      'buttonName': buttonName,
      'screen': screen ?? _currentScreen ?? 'unknown',
    };
    if (extra != null) params.addAll(extra);

    trackEvent(AnalyticsEventType.buttonClicked, 'button_clicked', params);
  }

  void trackOnlineToggled({required bool isOnline}) {
    trackEvent(AnalyticsEventType.onlineModeToggled, 'online_mode_toggled', {
      'isOnline': isOnline,
    });
  }

  void trackRequestReceived({required String bookingId, required int earning, required double distanceKm}) {
    trackEvent(AnalyticsEventType.partnerRequestReceived, 'partner_request_received', {
      'bookingId': bookingId,
      'earning': earning,
      'distanceKm': distanceKm,
    });
  }

  void trackRequestAccepted({required String bookingId, required int responseTimeMs}) {
    trackEvent(AnalyticsEventType.partnerRequestAccepted, 'partner_request_accepted', {
      'bookingId': bookingId,
      'responseTimeMs': responseTimeMs,
    });
  }

  void trackRequestRejected({required String bookingId, String? reason}) {
    trackEvent(AnalyticsEventType.partnerRequestRejected, 'partner_request_rejected', {
      'bookingId': bookingId,
      'reason': reason ?? 'manual_decline',
    });
  }

  void trackNavigationStarted({required String bookingId}) {
    trackEvent(AnalyticsEventType.navigationStarted, 'navigation_started', {
      'bookingId': bookingId,
    });
  }

  void trackArrival({required String bookingId}) {
    trackEvent(AnalyticsEventType.partnerArrived, 'partner_arrived', {
      'bookingId': bookingId,
    });
  }

  void trackShootStarted({required String bookingId}) {
    trackEvent(AnalyticsEventType.shootingStarted, 'shooting_started', {
      'bookingId': bookingId,
    });
  }

  void trackShootCompleted({required String bookingId, required int durationMinutes}) {
    trackEvent(AnalyticsEventType.shootingCompleted, 'shooting_completed', {
      'bookingId': bookingId,
      'durationMinutes': durationMinutes,
    });
  }

  void trackUploadStarted({required String bookingId, required int fileCount}) {
    trackEvent(AnalyticsEventType.uploadStarted, 'upload_started', {
      'bookingId': bookingId,
      'fileCount': fileCount,
    });
  }

  void trackUploadCompleted({required String bookingId, required int totalBytes}) {
    trackEvent(AnalyticsEventType.uploadCompleted, 'upload_completed', {
      'bookingId': bookingId,
      'totalBytes': totalBytes,
    });
  }

  void trackJobCompleted({required String bookingId, required int payout}) {
    trackEvent(AnalyticsEventType.jobCompleted, 'job_completed', {
      'bookingId': bookingId,
      'payout': payout,
    });
  }

  void trackWithdrawal({required num amount, required bool isSuccess}) {
    trackEvent(
      isSuccess ? AnalyticsEventType.withdrawalSuccess : AnalyticsEventType.withdrawalFailed,
      isSuccess ? 'withdrawal_success' : 'withdrawal_failed',
      {'amount': amount},
    );
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;
    _eventQueue.clear();
  }

  void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}

final partnerAnalytics = AnalyticsService();
final analytics = partnerAnalytics;
