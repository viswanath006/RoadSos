import 'package:geolocator/geolocator.dart';

import '../../domain/emergency_service.dart';
import '../../domain/repositories/emergency_services_repository.dart';
import '../../domain/service_type.dart';
import '../datasource/emergency_services_datasource.dart';

class EmergencyServicesRepositoryImpl implements EmergencyServicesRepository {
  EmergencyServicesRepositoryImpl({
    required EmergencyServicesRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final EmergencyServicesRemoteDataSource _remoteDataSource;

  @override
  Future<List<EmergencyService>> getNearbyEmergencyServices({
    required double latitude,
    required double longitude,
  }) async {
    final rawData = await _remoteDataSource.fetchNearbyServices(
      latitude: latitude,
      longitude: longitude,
    );

    final List<dynamic> elements = rawData['elements'] ?? [];
    final List<EmergencyService> services = [];

    for (final element in elements) {
      final tags = element['tags'] as Map<String, dynamic>? ?? {};
      final name = tags['name'] as String? ?? '';
      final phone = (tags['phone'] as String?) ?? (tags['contact:phone'] as String?);

      // Extract coordinates based on element type (nodes vs center of ways/relations)
      double? lat;
      double? lon;

      if (element['type'] == 'node') {
        lat = (element['lat'] as num?)?.toDouble();
        lon = (element['lon'] as num?)?.toDouble();
      } else if (element['center'] != null) {
        final center = element['center'] as Map<String, dynamic>;
        lat = (center['lat'] as num?)?.toDouble();
        lon = (center['lon'] as num?)?.toDouble();
      }

      if (lat == null || lon == null) {
        continue; // Skip element if coordinates are unavailable
      }

      // Determine service type
      ServiceType? type;
      final amenity = tags['amenity'] as String?;
      final emergency = tags['emergency'] as String?;

      if (amenity == 'hospital') {
        type = ServiceType.hospital;
      } else if (amenity == 'police') {
        type = ServiceType.police;
      } else if (emergency == 'ambulance_station' || amenity == 'ambulance_station') {
        type = ServiceType.ambulance;
      }

      if (type == null) {
        continue; // Skip if we cannot classify the service type
      }

      // Calculate distance in kilometers
      final distanceInMeters = Geolocator.distanceBetween(
        latitude,
        longitude,
        lat,
        lon,
      );
      final distanceInKm = distanceInMeters / 1000.0;

      services.add(
        EmergencyService(
          id: element['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.isNotEmpty ? name : _fallbackName(type),
          type: type,
          latitude: lat,
          longitude: lon,
          distance: distanceInKm,
          phone: phone,
        ),
      );
    }

    // Sort by distance nearest first
    services.sort((a, b) => (a.distance ?? 0.0).compareTo(b.distance ?? 0.0));

    // Fallback: If no ambulance stations are found, display nearest hospitals as ambulance fallback
    final hasAmbulances = services.any((s) => s.type == ServiceType.ambulance);
    if (!hasAmbulances) {
      final hospitals = services.where((s) => s.type == ServiceType.hospital).toList();
      for (final hospital in hospitals) {
        services.add(
          hospital.copyWith(
            id: '${hospital.id}_ambulance_fallback',
            name: '${hospital.name} (Ambulance Service)',
            type: ServiceType.ambulance,
          ),
        );
      }
    }

    // Sort again after fallback items have been added
    services.sort((a, b) => (a.distance ?? 0.0).compareTo(b.distance ?? 0.0));

    return services;
  }

  String _fallbackName(ServiceType type) {
    switch (type) {
      case ServiceType.hospital:
        return 'Emergency Medical Center';
      case ServiceType.police:
        return 'Police Station / Patrol';
      case ServiceType.ambulance:
        return 'Ambulance Response Point';
    }
  }
}
