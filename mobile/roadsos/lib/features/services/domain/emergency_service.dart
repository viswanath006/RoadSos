import 'service_type.dart';

class EmergencyService {
  const EmergencyService({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.phone,
  });

  final String id;
  final String name;
  final ServiceType type;
  final double latitude;
  final double longitude;
  final double? distance;
  final String? phone;

  EmergencyService copyWith({
    String? id,
    String? name,
    ServiceType? type,
    double? latitude,
    double? longitude,
    double? distance,
    String? phone,
  }) {
    return EmergencyService(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      phone: phone ?? this.phone,
    );
  }

  String get distanceLabel {
    if (distance == null) return '';
    if (distance! < 1.0) {
      return '${(distance! * 1000).toStringAsFixed(0)} m';
    }
    return '${distance!.toStringAsFixed(1)} km';
  }
}
