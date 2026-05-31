import '../../../services/domain/emergency_service.dart';
import '../../domain/repositories/cached_services_repository.dart';
import '../datasource/cached_services_local_datasource.dart';

class CachedServicesRepositoryImpl implements CachedServicesRepository {
  CachedServicesRepositoryImpl({
    required CachedServicesLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final CachedServicesLocalDataSource _localDataSource;

  @override
  List<EmergencyService> getCachedServices() =>
      _localDataSource.getCachedServices();

  @override
  Future<void> cacheServices(List<EmergencyService> services) =>
      _localDataSource.cacheServices(services);
}
