import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/connectivity_banner.dart';
import '../../offline/presentation/providers/connectivity_provider.dart';
import '../../sos/application/sos_provider.dart';

enum BreakdownServiceType {
  mechanic,
  towing,
  fuel,
  tireRepair;

  String get displayName {
    switch (this) {
      case BreakdownServiceType.mechanic:
        return 'Mechanic';
      case BreakdownServiceType.towing:
        return 'Towing';
      case BreakdownServiceType.fuel:
        return 'Fuel';
      case BreakdownServiceType.tireRepair:
        return 'Tire Repair';
    }
  }
}

class BreakdownService {
  final String id;
  final String name;
  final BreakdownServiceType type;
  final double latitude;
  final double longitude;
  final String phone;

  BreakdownService({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.phone,
  });
}

class BreakdownScreen extends ConsumerStatefulWidget {
  const BreakdownScreen({super.key});

  @override
  ConsumerState<BreakdownScreen> createState() => _BreakdownScreenState();
}

class _BreakdownScreenState extends ConsumerState<BreakdownScreen> {
  final MapController _mapController = MapController();
  BreakdownServiceType? _selectedFilter;
  LatLng? _userLocation;

  // Static list of breakdown services positioned near IIT Madras (default location)
  // These will be shifted dynamically to the user's actual location if available.
  List<BreakdownService> _getServices(LatLng center) {
    return [
      BreakdownService(
        id: 'b1',
        name: 'Sri Sai Motors (Mechanic)',
        type: BreakdownServiceType.mechanic,
        latitude: center.latitude + 0.009,
        longitude: center.longitude + 0.007,
        phone: '+91 98765 43210',
      ),
      BreakdownService(
        id: 'b2',
        name: 'Safe Tow Services',
        type: BreakdownServiceType.towing,
        latitude: center.latitude - 0.018,
        longitude: center.longitude + 0.015,
        phone: '+91 99999 88888',
      ),
      BreakdownService(
        id: 'b3',
        name: 'Quick Tire Repair',
        type: BreakdownServiceType.tireRepair,
        latitude: center.latitude + 0.008,
        longitude: center.longitude - 0.006,
        phone: '+91 95555 44444',
      ),
      BreakdownService(
        id: 'b4',
        name: 'HP Fuel Station',
        type: BreakdownServiceType.fuel,
        latitude: center.latitude - 0.014,
        longitude: center.longitude - 0.011,
        phone: '+91 90000 11111',
      ),
    ];
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  Future<void> _makeCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  IconData _getIcon(BreakdownServiceType type) {
    switch (type) {
      case BreakdownServiceType.mechanic:
        return Icons.construction_rounded;
      case BreakdownServiceType.towing:
        return Icons.rv_hookup_rounded;
      case BreakdownServiceType.fuel:
        return Icons.local_gas_station_rounded;
      case BreakdownServiceType.tireRepair:
        return Icons.build_circle_rounded;
    }
  }

  Color _getColor(BreakdownServiceType type) {
    switch (type) {
      case BreakdownServiceType.mechanic:
        return Colors.red.shade700;
      case BreakdownServiceType.towing:
        return Colors.blue.shade700;
      case BreakdownServiceType.fuel:
        return Colors.green.shade700;
      case BreakdownServiceType.tireRepair:
        return Colors.purple.shade700;
    }
  }

  void _centerOn(LatLng point) {
    _mapController.move(point, 14.5);
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(sosLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Breakdown Assistance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: locationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.sosRed)),
        error: (err, _) => const Center(
          child: Text('Unable to detect location. Please enable GPS permissions.'),
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

          final allServices = _getServices(userLatLng);
          final filteredServices = allServices
              .where((s) => _selectedFilter == null || s.type == _selectedFilter)
              .toList();

          return Column(
            children: [
              const ConnectivityBanner(),

              // Horizontal Chip Filter
              _buildFilterChips(),

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
                    child: _buildMap(userLatLng, filteredServices),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // List of nearby providers
              Expanded(
                flex: 5,
                child: filteredServices.isEmpty
                    ? const Center(child: Text('No breakdown services found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          final distance = _calculateDistance(
                            userLatLng.latitude,
                            userLatLng.longitude,
                            service.latitude,
                            service.longitude,
                          );
                          final color = _getColor(service.type);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200, width: 1),
                            ),
                            child: InkWell(
                              onTap: () => _centerOn(LatLng(service.latitude, service.longitude)),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getIcon(service.type),
                                        color: color,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${distance.toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.phone_rounded, color: Colors.blue),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
                                        padding: const EdgeInsets.all(10),
                                      ),
                                      onPressed: () => _makeCall(service.phone),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildMap(LatLng userLatLng, List<BreakdownService> services) {
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
      final markerColor = _getColor(service.type);
      markers.add(
        Marker(
          point: LatLng(service.latitude, service.longitude),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _centerOn(LatLng(service.latitude, service.longitude)),
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
                _getIcon(service.type),
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

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildChip(
            label: 'All',
            isSelected: _selectedFilter == null,
            onSelected: () => setState(() => _selectedFilter = null),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Mechanics',
            isSelected: _selectedFilter == BreakdownServiceType.mechanic,
            onSelected: () => setState(() => _selectedFilter = BreakdownServiceType.mechanic),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Towing',
            isSelected: _selectedFilter == BreakdownServiceType.towing,
            onSelected: () => setState(() => _selectedFilter = BreakdownServiceType.towing),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Fuel',
            isSelected: _selectedFilter == BreakdownServiceType.fuel,
            onSelected: () => setState(() => _selectedFilter = BreakdownServiceType.fuel),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Tire Repair',
            isSelected: _selectedFilter == BreakdownServiceType.tireRepair,
            onSelected: () => setState(() => _selectedFilter = BreakdownServiceType.tireRepair),
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
