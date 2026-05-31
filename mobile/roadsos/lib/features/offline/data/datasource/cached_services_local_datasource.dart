import 'package:hive/hive.dart';
import '../../../services/domain/emergency_service.dart';

abstract class CachedServicesLocalDataSource {
  List<EmergencyService> getCachedServices();
  Future<void> cacheServices(List<EmergencyService> services);
}

class CachedServicesLocalDataSourceImpl implements CachedServicesLocalDataSource {
  CachedServicesLocalDataSourceImpl({Box<EmergencyService>? box})
      : _box = box ?? Hive.box<EmergencyService>('cached_services_box');

  final Box<EmergencyService> _box;

  @override
  List<EmergencyService> getCachedServices() {
    return _box.values.toList();
  }

  @override
  Future<void> cacheServices(List<EmergencyService> services) async {
    await _box.clear();
    for (final service in services) {
      await _box.put(service.id, service);
    }
  }
}
