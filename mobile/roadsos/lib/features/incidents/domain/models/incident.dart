class Incident {
  const Incident({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.alertSent,
  });

  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final bool alertSent;

  Incident copyWith({
    String? id,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    bool? alertSent,
  }) {
    return Incident(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      alertSent: alertSent ?? this.alertSent,
    );
  }
}
