import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/domain/emergency_service.dart';
import '../../data/datasource/cached_services_local_datasource.dart';
import '../../data/repositories/cached_services_repository_impl.dart';
import '../../domain/repositories/cached_services_repository.dart';

final cachedServicesDataSourceProvider = Provider<CachedServicesLocalDataSource>((ref) {
  return CachedServicesLocalDataSourceImpl();
});

final cachedServicesRepositoryProvider = Provider<CachedServicesRepository>((ref) {
  final dataSource = ref.watch(cachedServicesDataSourceProvider);
  return CachedServicesRepositoryImpl(localDataSource: dataSource);
});

final cachedServicesProvider =
    StateNotifierProvider.autoDispose<CachedServicesNotifier, List<EmergencyService>>((ref) {
  final repository = ref.watch(cachedServicesRepositoryProvider);
  return CachedServicesNotifier(repository);
});

class CachedServicesNotifier extends StateNotifier<List<EmergencyService>> {
  CachedServicesNotifier(this._repository) : super([]) {
    loadCache();
  }

  final CachedServicesRepository _repository;

  void loadCache() {
    state = _repository.getCachedServices();
  }

  Future<void> updateCache(List<EmergencyService> services) async {
    await _repository.cacheServices(services);
    loadCache();
  }
}
