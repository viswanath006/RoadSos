import '../../../services/domain/emergency_service.dart';

abstract class CachedServicesRepository {
  List<EmergencyService> getCachedServices();
  Future<void> cacheServices(List<EmergencyService> services);
}
