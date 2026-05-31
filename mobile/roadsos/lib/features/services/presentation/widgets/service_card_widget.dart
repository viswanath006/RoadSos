import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/emergency_service.dart';
import '../../domain/service_type.dart';

class ServiceCardWidget extends StatelessWidget {
  const ServiceCardWidget({
    super.key,
    required this.service,
    required this.onTap,
  });

  final EmergencyService service;
  final VoidCallback onTap;

  Future<void> _launchCall() async {
    final number = service.phone ?? '108';
    final cleanNumber = number.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  IconData _getIcon(ServiceType type) {
    switch (type) {
      case ServiceType.hospital:
        return Icons.local_hospital;
      case ServiceType.police:
        return Icons.local_police;
      case ServiceType.ambulance:
        return Icons.airport_shuttle;
    }
  }

  Color _getColor(ServiceType type) {
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
    final typeColor = _getColor(service.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Avatar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(service.type),
                  color: typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Title and Distance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${service.type.displayName} • ${service.distanceLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Call action button on the right
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: Colors.blue),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: _launchCall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
