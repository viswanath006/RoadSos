enum LocationFailureType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationFailure implements Exception {
  const LocationFailure(this.type, this.message);

  final LocationFailureType type;
  final String message;

  @override
  String toString() => message;

  static LocationFailure serviceDisabled() => const LocationFailure(
        LocationFailureType.serviceDisabled,
        'Location services are turned off. Enable GPS in device settings.',
      );

  static LocationFailure permissionDenied() => const LocationFailure(
        LocationFailureType.permissionDenied,
        'Location permission denied. Allow location access for RoadSoS.',
      );

  static LocationFailure permissionDeniedForever() => const LocationFailure(
        LocationFailureType.permissionDeniedForever,
        'Location permission permanently denied. Enable it in App Settings.',
      );

  static LocationFailure timeout() => const LocationFailure(
        LocationFailureType.timeout,
        'Could not get GPS fix in time. Move outdoors and try again.',
      );

  static LocationFailure unknown([String? detail]) => LocationFailure(
        LocationFailureType.unknown,
        detail ?? 'Failed to fetch location. Please try again.',
      );
}
