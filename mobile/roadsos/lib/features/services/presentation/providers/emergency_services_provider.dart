import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sos/application/sos_provider.dart';
import '../../data/datasource/emergency_services_datasource.dart';
import '../../data/repositories/emergency_services_repository_impl.dart';
import '../../domain/emergency_service.dart';
import '../../domain/repositories/emergency_services_repository.dart';
import '../../domain/service_type.dart';
import '../../../offline/presentation/providers/connectivity_provider.dart';
import '../../../offline/presentation/providers/cached_services_provider.dart';

final emergencyServicesDataSourceProvider =
    Provider<EmergencyServicesRemoteDataSource>((ref) {
  return EmergencyServicesRemoteDataSourceImpl();
});

final emergencyServicesRepositoryProvider =
    Provider<EmergencyServicesRepository>((ref) {
  final dataSource = ref.watch(emergencyServicesDataSourceProvider);
  return EmergencyServicesRepositoryImpl(remoteDataSource: dataSource);
});

final selectedServiceTypeFilterProvider =
    StateProvider.autoDispose<ServiceType?>((ref) => null);

final emergencyServicesListProvider =
    FutureProvider.autoDispose<List<EmergencyService>>((ref) async {
  final network = ref.watch(networkStatusProvider);

  if (network == NetworkStatus.offline) {
    final cache = ref.read(cachedServicesProvider);
    if (cache.isEmpty) {
      throw Exception('No offline data cached. You need internet connectivity to load services for the first time.');
    }
    return cache;
  }

  // Watch the location provider and wait for a valid LocationInfo
  final location = await ref.watch(sosLocationProvider.future);
  
  final repository = ref.watch(emergencyServicesRepositoryProvider);
  final services = await repository.getNearbyEmergencyServices(
    latitude: location.latitude,
    longitude: location.longitude,
  );

  // Update local cache
  await ref.read(cachedServicesProvider.notifier).updateCache(services);

  return services;
});

final filteredEmergencyServicesProvider =
    Provider.autoDispose<AsyncValue<List<EmergencyService>>>((ref) {
  final servicesAsync = ref.watch(emergencyServicesListProvider);
  final selectedFilter = ref.watch(selectedServiceTypeFilterProvider);

  return servicesAsync.whenData((services) {
    if (selectedFilter == null) return services;
    return services.where((s) => s.type == selectedFilter).toList();
  });
});
