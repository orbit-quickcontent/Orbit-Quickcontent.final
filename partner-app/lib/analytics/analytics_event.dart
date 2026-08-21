/// ORBIT Behavioural Analytics Events for Partner App
enum AnalyticsEventType {
  sessionStarted,
  sessionEnded,
  screenViewed,
  buttonClicked,
  onlineModeToggled,
  partnerRequestReceived,
  partnerRequestAccepted,
  partnerRequestRejected,
  partnerRequestTimeout,
  navigationStarted,
  partnerArrived,
  shootingStarted,
  shootingCompleted,
  uploadStarted,
  uploadCompleted,
  uploadFailed,
  jobCompleted,
  withdrawalRequested,
  withdrawalSuccess,
  withdrawalFailed,
  actionFailed,
}

/// Analytics Event Model
class AnalyticsEvent {
  final AnalyticsEventType type;
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.type,
    required this.name,
    Map<String, dynamic>? parameters,
    DateTime? timestamp,
  })  : parameters = parameters ?? {},
        timestamp = timestamp ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() {
    return {
      'event': name,
      'type': type.name,
      'params': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() => 'AnalyticsEvent($name, $parameters, $timestamp)';
}
