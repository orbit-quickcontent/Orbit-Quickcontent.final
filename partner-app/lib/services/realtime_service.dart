import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

/// Real-time event polling service for the Partner App.
/// Polls the edge worker's event endpoint to receive dispatch notifications,
/// booking status updates, and other real-time events.
class PartnerRealtimeService {
  static final PartnerRealtimeService _instance = PartnerRealtimeService._internal();
  factory PartnerRealtimeService() => _instance;
  PartnerRealtimeService._internal();

  Timer? _pollTimer;
  String _lastSince = DateTime.now().toUtc().toIso8601String();
  String? _partnerId;
  bool _isPolling = false;

  // Event callbacks
  final List<void Function(Map<String, dynamic>)> _onDispatchNew = [];
  final List<void Function(Map<String, dynamic>)> _onBookingStatusUpdate = [];
  final List<void Function(Map<String, dynamic>)> _onDispatchExpired = [];
  final List<void Function(Map<String, dynamic>)> _onGenericEvent = [];

  /// Start polling for events for the given partner ID
  void start(String partnerId) {
    _partnerId = partnerId;
    _lastSince = DateTime.now().subtract(const Duration(minutes: 5)).toUtc().toIso8601String();
    _isPolling = true;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());

    // Initial poll immediately
    _poll();

    debugPrint('[RealtimeService] Started polling for partner: $partnerId');
  }

  /// Stop polling
  void stop() {
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    debugPrint('[RealtimeService] Stopped polling');
  }

  /// Register callback for new dispatch offers
  void onDispatchNew(void Function(Map<String, dynamic>) callback) {
    _onDispatchNew.add(callback);
  }

  /// Register callback for booking status updates
  void onBookingStatusUpdate(void Function(Map<String, dynamic>) callback) {
    _onBookingStatusUpdate.add(callback);
  }

  /// Register callback for dispatch expired
  void onDispatchExpired(void Function(Map<String, dynamic>) callback) {
    _onDispatchExpired.add(callback);
  }

  /// Register callback for any event
  void onEvent(void Function(Map<String, dynamic>) callback) {
    _onGenericEvent.add(callback);
  }

  /// Remove all callbacks
  void clearCallbacks() {
    _onDispatchNew.clear();
    _onBookingStatusUpdate.clear();
    _onDispatchExpired.clear();
    _onGenericEvent.clear();
  }

  Future<void> _poll() async {
    if (!_isPolling || _partnerId == null) return;

    try {
      final res = await partnerApiClient.get(
        '/events/poll/partner/$_partnerId',
        params: {'since': _lastSince},
      );

      final data = res.data;
      if (data == null) return;

      final serverTime = data['serverTime'] as String?;
      if (serverTime != null) {
        _lastSince = serverTime;
      }

      final events = data['events'] as List? ?? [];
      for (final evt in events) {
        final event = evt as Map<String, dynamic>;
        final eventType = event['event'] as String? ?? '';
        final payload = event['payload'] as Map<String, dynamic>? ?? {};

        debugPrint('[RealtimeService] Event: $eventType | Payload: ${json.encode(payload)}');

        // Fire generic callbacks
        for (final cb in _onGenericEvent) {
          cb({'event': eventType, 'payload': payload});
        }

        // Fire specific callbacks
        switch (eventType) {
          case 'dispatch:new':
            for (final cb in _onDispatchNew) { cb(payload); }
            break;
          case 'booking:status-update':
            for (final cb in _onBookingStatusUpdate) { cb(payload); }
            break;
          case 'dispatch:expired':
            for (final cb in _onDispatchExpired) { cb(payload); }
            break;
        }
      }
    } catch (e) {
      debugPrint('[RealtimeService] Poll error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stop();
    clearCallbacks();
  }
}

final partnerRealtime = PartnerRealtimeService();
