import '../../domain/emergency_service.dart';

abstract class EmergencyServicesRepository {
  Future<List<EmergencyService>> getNearbyEmergencyServices({
    required double latitude,
    required double longitude,
  });
}
