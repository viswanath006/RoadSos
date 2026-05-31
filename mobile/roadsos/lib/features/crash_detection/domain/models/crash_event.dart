class CrashEvent {
  const CrashEvent({
    required this.id,
    required this.timestamp,
    required this.peakAcceleration,
    required this.speedChange,
    required this.peakGyroscope,
    this.latitude,
    this.longitude,
    required this.userResponse,
  });

  final String id;
  final DateTime timestamp;
  final double peakAcceleration; // in Gs
  final double speedChange;      // in m/s
  final double peakGyroscope;    // in rad/s
  final double? latitude;
  final double? longitude;
  final String userResponse;     // 'safe', 'help_needed', 'no_response'

  CrashEvent copyWith({
    String? id,
    DateTime? timestamp,
    double? peakAcceleration,
    double? speedChange,
    double? peakGyroscope,
    double? latitude,
    double? longitude,
    String? userResponse,
  }) {
    return CrashEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      peakAcceleration: peakAcceleration ?? this.peakAcceleration,
      speedChange: speedChange ?? this.speedChange,
      peakGyroscope: peakGyroscope ?? this.peakGyroscope,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userResponse: userResponse ?? this.userResponse,
    );
  }
}
