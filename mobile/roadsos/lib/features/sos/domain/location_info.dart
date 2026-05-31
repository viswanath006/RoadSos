class LocationInfo {
  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
