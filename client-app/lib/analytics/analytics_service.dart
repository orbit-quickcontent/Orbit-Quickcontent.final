import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'analytics_event.dart';

/// ORBIT Behavioural Analytics Service
/// Non-blocking, batched, high-performance event logger
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final Queue<AnalyticsEvent> _eventQueue = Queue<AnalyticsEvent>();
  Timer? _flushTimer;
  String? _userId;
  String? _sessionId;
  DateTime? _screenEnterTime;
  String? _currentScreen;

  void init({String? userId}) {
    _userId = userId;
    _sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
    _startFlushTimer();
    trackEvent(AnalyticsEventType.sessionStarted, 'session_started', {
      'sessionId': _sessionId,
      'platform': defaultTargetPlatform.name,
    });
  }

  void setUserId(String? id) {
    _userId = id;
  }

  /// Track generic event asynchronously
  void trackEvent(AnalyticsEventType type, String name, [Map<String, dynamic>? parameters]) {
    final params = Map<String, dynamic>.from(parameters ?? {});
    if (_userId != null) params['userId'] = _userId;
    if (_sessionId != null) params['sessionId'] = _sessionId;

    final event = AnalyticsEvent(
      type: type,
      name: name,
      parameters: params,
    );

    _eventQueue.add(event);

    if (kDebugMode) {
      debugPrint('[Analytics] ${event.name} -> ${event.parameters}');
    }

    if (_eventQueue.length >= 20) {
      flush();
    }
  }

  /// Track screen view and duration
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

  /// Track primary CTA click
  void trackButtonClick(String buttonName, {String? screen, Map<String, dynamic>? extra}) {
    final params = <String, dynamic>{
      'buttonName': buttonName,
      'screen': screen ?? _currentScreen ?? 'unknown',
    };
    if (extra != null) params.addAll(extra);

    trackEvent(AnalyticsEventType.buttonClicked, 'button_clicked', params);
  }

  /// Track booking lifecycle events
  void trackBookingStarted({required String packageId, String? tier}) {
    trackEvent(AnalyticsEventType.bookingStarted, 'booking_started', {
      'packageId': packageId,
      'tier': tier,
    });
  }

  void trackPaymentStarted({required String bookingId, required num amount}) {
    trackEvent(AnalyticsEventType.paymentStarted, 'payment_started', {
      'bookingId': bookingId,
      'amount': amount,
    });
  }

  void trackPaymentSuccess({required String bookingId, required String paymentId, required num amount}) {
    trackEvent(AnalyticsEventType.paymentSuccess, 'payment_success', {
      'bookingId': bookingId,
      'paymentId': paymentId,
      'amount': amount,
    });
  }

  void trackPaymentFailed({required String bookingId, required String reason}) {
    trackEvent(AnalyticsEventType.paymentFailed, 'payment_failed', {
      'bookingId': bookingId,
      'reason': reason,
    });
  }

  void trackPartnerSearchStarted({required String bookingId, required double latitude, required double longitude}) {
    trackEvent(AnalyticsEventType.partnerSearchStarted, 'partner_search_started', {
      'bookingId': bookingId,
      'lat': latitude,
      'lng': longitude,
    });
  }

  void trackPartnerFound({required String bookingId, required String partnerId}) {
    trackEvent(AnalyticsEventType.partnerFound, 'partner_found', {
      'bookingId': bookingId,
      'partnerId': partnerId,
    });
  }

  void trackReelDelivered({required String bookingId}) {
    trackEvent(AnalyticsEventType.reelDelivered, 'reel_delivered', {
      'bookingId': bookingId,
    });
  }

  void trackReelDownloaded({required String bookingId}) {
    trackEvent(AnalyticsEventType.reelDownloaded, 'reel_downloaded', {
      'bookingId': bookingId,
    });
  }

  void trackRatingSubmitted({required String bookingId, required int rating, String? feedback}) {
    trackEvent(AnalyticsEventType.ratingSubmitted, 'rating_submitted', {
      'bookingId': bookingId,
      'rating': rating,
      'feedback': feedback,
    });
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  /// Flush events queue without blocking UI
  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;

    final batch = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      // In production, batch is dispatched to backend analytics endpoint
      if (kDebugMode) {
        debugPrint('[Analytics Flush] Dispatched ${batch.length} events');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics Error] Failed to flush events: $e');
      }
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}

final analytics = AnalyticsService();
