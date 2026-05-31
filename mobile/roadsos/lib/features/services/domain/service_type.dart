enum ServiceType {
  hospital,
  police,
  ambulance;

  String get displayName {
    switch (this) {
      case ServiceType.hospital:
        return 'Hospital';
      case ServiceType.police:
        return 'Police Station';
      case ServiceType.ambulance:
        return 'Ambulance Service';
    }
  }
}
