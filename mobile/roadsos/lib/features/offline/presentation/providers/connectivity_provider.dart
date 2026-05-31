import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

final connectivityProvider = StreamProvider.autoDispose<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final networkStatusProvider = Provider.autoDispose<NetworkStatus>((ref) {
  final connectivityAsync = ref.watch(connectivityProvider);

  return connectivityAsync.maybeWhen(
    data: (results) {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        return NetworkStatus.offline;
      }
      return NetworkStatus.online;
    },
    orElse: () => NetworkStatus.online,
  );
});
