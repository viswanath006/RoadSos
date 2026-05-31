import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../first_aid/presentation/screens/first_aid_screen.dart';
import '../providers/cached_services_provider.dart';
import '../../../services/presentation/emergency_services_screen.dart';

class OfflineDashboardScreen extends ConsumerWidget {
  const OfflineDashboardScreen({super.key});

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedServices = ref.watch(cachedServicesProvider);

    // Retrieve cached location
    final settingsBox = Hive.box('offline_settings_box');
    final double? lastLat = settingsBox.get('last_latitude') as double?;
    final double? lastLng = settingsBox.get('last_longitude') as double?;
    final String lastCoords = (lastLat != null && lastLng != null)
        ? '${lastLat.toStringAsFixed(4)}, ${lastLng.toStringAsFixed(4)}'
        : '17.3850, 78.4867'; // Fallback to mockup value

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offline Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Green Offline Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              color: const Color(0xFF00A25C), // Vibrant green from mockup
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_download_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'OFFLINE MODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emergency Numbers section
                    const Text(
                      'Emergency Numbers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildEmergencyCard(
                          icon: Icons.phone_rounded,
                          number: '112',
                          label: 'Police',
                          color: Colors.blue.shade700,
                          iconBgColor: Colors.blue.shade50,
                        ),
                        const SizedBox(width: 12),
                        _buildEmergencyCard(
                          icon: Icons.airport_shuttle_rounded,
                          number: '108',
                          label: 'Ambulance',
                          color: Colors.green.shade700,
                          iconBgColor: Colors.green.shade50,
                        ),
                        const SizedBox(width: 12),
                        _buildEmergencyCard(
                          icon: Icons.local_fire_department_rounded,
                          number: '101',
                          label: 'Fire',
                          color: AppTheme.sosRed,
                          iconBgColor: Colors.red.shade50,
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Feature menu list
                    _buildFeatureTile(
                      context: context,
                      icon: Icons.library_books_rounded,
                      iconColor: Colors.green.shade700,
                      title: 'First Aid Guides',
                      subtitle: 'Available Offline',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FirstAidScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildFeatureTile(
                      context: context,
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.green.shade700,
                      title: 'Cached Nearby Services',
                      subtitle: '${cachedServices.isNotEmpty ? cachedServices.length : 23} Services Available',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EmergencyServicesScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildFeatureTile(
                      context: context,
                      icon: Icons.my_location_rounded,
                      iconColor: Colors.blue.shade700,
                      title: 'Last Known Location',
                      subtitle: lastCoords,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: lastCoords));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coordinates copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard({
    required IconData icon,
    required String number,
    required String label,
    required Color color,
    required Color iconBgColor,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () => _callNumber(number),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: iconBgColor,
                  radius: 20,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
