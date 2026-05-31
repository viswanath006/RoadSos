import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/errors/location_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/connectivity_banner.dart';
import '../../../shared/widgets/error_message.dart';
import '../../offline/presentation/providers/connectivity_provider.dart';
import '../../sos/application/sos_provider.dart';
import '../../sos/domain/location_info.dart';
import '../domain/emergency_service.dart';
import '../domain/service_type.dart';
import 'providers/emergency_services_provider.dart';
import 'widgets/service_card_widget.dart';
import 'service_details_screen.dart';

class EmergencyServicesScreen extends ConsumerStatefulWidget {
  const EmergencyServicesScreen({super.key});

  @override
  ConsumerState<EmergencyServicesScreen> createState() =>
      _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends ConsumerState<EmergencyServicesScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(sosLocationProvider).value;
      if (loc != null) {
        setState(() {
          _userLocation = LatLng(loc.latitude, loc.longitude);
        });
      }
    });
  }

  void _centerOn(LatLng point, {double zoom = 14.5}) {
    _mapController.move(point, zoom);
  }

  void _showDetails(EmergencyService service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceDetailsScreen(service: service),
      ),
    );
  }

  IconData _getMarkerIcon(ServiceType type) {
    switch (type) {
      case ServiceType.hospital:
        return Icons.local_hospital;
      case ServiceType.police:
        return Icons.local_police;
      case ServiceType.ambulance:
        return Icons.airport_shuttle;
    }
  }

  Color _getMarkerColor(ServiceType type) {
    switch (type) {
      case ServiceType.hospital:
        return AppTheme.sosRed;
      case ServiceType.police:
        return Colors.blue.shade700;
      case ServiceType.ambulance:
        return Colors.teal.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(sosLocationProvider);
    final servicesAsync = ref.watch(filteredEmergencyServicesProvider);
    final activeFilter = ref.watch(selectedServiceTypeFilterProvider);
    final isOffline = ref.watch(networkStatusProvider) == NetworkStatus.offline;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nearby Services',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppTheme.textSecondary, size: 28),
            onPressed: () {
              ref.read(sosLocationProvider.notifier).refresh();
              ref.invalidate(emergencyServicesListProvider);
            },
          ),
        ],
      ),
      body: locationAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.sosRed),
              SizedBox(height: 16),
              Text(
                'Detecting location…',
                style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorMessage(
            message: error is LocationFailure
                ? error.message
                : 'Unable to retrieve location. Please check GPS settings.',
            onRetry: () => ref.read(sosLocationProvider.notifier).refresh(),
          ),
        ),
        data: (location) {
          final userLatLng = LatLng(location.latitude, location.longitude);

          if (_userLocation == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _userLocation = userLatLng;
              });
            });
          }

          return Column(
            children: [
              const ConnectivityBanner(),

              // Horizontal Chip Filter
              _buildFilterChips(activeFilter),

              // Interactive Map Area
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: servicesAsync.when(
                      data: (services) => _buildMap(userLatLng, services),
                      loading: () => _buildMap(userLatLng, []),
                      error: (_, __) => _buildMap(userLatLng, []),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nearby Services List
              Expanded(
                flex: 5,
                child: servicesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.sosRed),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Failed to fetch nearby services.\n${err.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  data: (services) {
                    if (services.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No emergency services found nearby',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: services.length,
                            itemBuilder: (context, index) {
                              final service = services[index];
                              return ServiceCardWidget(
                                service: service,
                                onTap: () => _showDetails(service),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: InkWell(
                            onTap: () {},
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'View All Services',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.blue, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(LatLng userLatLng, List<EmergencyService> services) {
    final markers = <Marker>[
      Marker(
        point: userLatLng,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.sosRed.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.my_location,
            color: AppTheme.sosRed,
            size: 28,
          ),
        ),
      ),
    ];

    for (final service in services) {
      final markerColor = _getMarkerColor(service.type);
      markers.add(
        Marker(
          point: LatLng(service.latitude, service.longitude),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _showDetails(service),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _getMarkerIcon(service.type),
                color: markerColor,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userLatLng,
        initialZoom: 14.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.roadsos.roadsos',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildFilterChips(ServiceType? activeFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildChip(
            label: 'All',
            isSelected: activeFilter == null,
            onSelected: () =>
                ref.read(selectedServiceTypeFilterProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Hospitals',
            isSelected: activeFilter == ServiceType.hospital,
            onSelected: () =>
                ref.read(selectedServiceTypeFilterProvider.notifier).state =
                    ServiceType.hospital,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Police',
            isSelected: activeFilter == ServiceType.police,
            onSelected: () =>
                ref.read(selectedServiceTypeFilterProvider.notifier).state =
                    ServiceType.police,
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Ambulance',
            isSelected: activeFilter == ServiceType.ambulance,
            onSelected: () =>
                ref.read(selectedServiceTypeFilterProvider.notifier).state =
                    ServiceType.ambulance,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selectedColor: AppTheme.sosRed,
      checkmarkColor: Colors.white,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? AppTheme.sosRed : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
