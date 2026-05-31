import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/location_failure.dart';
import '../data/location_service.dart';
import '../domain/location_info.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final sosLocationProvider =
    AutoDisposeAsyncNotifierProvider<SosLocationNotifier, LocationInfo>(
  SosLocationNotifier.new,
);

class SosLocationNotifier extends AutoDisposeAsyncNotifier<LocationInfo> {
  @override
  Future<LocationInfo> build() async {
    return ref.read(locationServiceProvider).getCurrentLocation();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(locationServiceProvider).getCurrentLocation(),
    );
  }
}
