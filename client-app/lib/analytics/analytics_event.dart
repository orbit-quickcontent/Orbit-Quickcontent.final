/// ORBIT Behavioural Analytics Events
enum AnalyticsEventType {
  sessionStarted,
  sessionEnded,
  screenViewed,
  buttonClicked,
  bookingStarted,
  packageSelected,
  locationSelected,
  timeSlotSelected,
  paymentStarted,
  paymentSuccess,
  paymentFailed,
  paymentAbandoned,
  partnerSearchStarted,
  partnerFound,
  partnerRequestReceived,
  partnerRequestAccepted,
  partnerRequestRejected,
  partnerArrived,
  shootingStarted,
  shootingCompleted,
  uploadStarted,
  uploadCompleted,
  reelDelivered,
  reelDownloaded,
  ratingSubmitted,
  onlineModeToggled,
  withdrawalRequested,
  withdrawalSuccess,
  withdrawalFailed,
  bookingAbandoned,
  formError,
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
