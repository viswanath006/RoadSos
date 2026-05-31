import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/location_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/connectivity_banner.dart';
import '../../../shared/widgets/error_message.dart';
import '../../contacts/presentation/providers/contacts_provider.dart';
import '../application/sos_provider.dart';
import '../domain/location_info.dart';
import 'sos_alert_confirmation_screen.dart';
import 'widgets/location_map_widget.dart';

class SosScreen extends ConsumerWidget {
  const SosScreen({super.key});

  Future<void> _openExternalMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToConfirmation(BuildContext context, double latitude, double longitude) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SosAlertConfirmationScreen(
          latitude: latitude,
          longitude: longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(sosLocationProvider);

    // Automatically trigger SOS Alert Confirmation screen as soon as location details are loaded
    ref.listen<AsyncValue<LocationInfo>>(sosLocationProvider, (prev, next) {
      if (next is AsyncData<LocationInfo>) {
        final location = next.value;
        final contacts = ref.read(contactsProvider);
        if (contacts.isNotEmpty) {
          // Navigate to full page confirmation
          _navigateToConfirmation(context, location.latitude, location.longitude);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No emergency contacts added. Please add contacts first.'),
              backgroundColor: AppTheme.sosRed,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.sosRed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: locationAsync.when(
              loading: () => const _SosLoadingView(),
              error: (error, _) => _SosErrorView(
                error: error,
                onRetry: () => ref.read(sosLocationProvider.notifier).refresh(),
              ),
              data: (location) => _SosSuccessView(
                location: location,
                onViewOnMap: () => _openExternalMap(location.latitude, location.longitude),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosLoadingView extends StatelessWidget {
  const _SosLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.sosRed),
            SizedBox(height: 24),
            Text(
              'Getting your location…',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Please allow location access',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SosErrorView extends ConsumerWidget {
  const _SosErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = error is LocationFailure
        ? (error as LocationFailure).message
        : error.toString();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ErrorMessage(
            message: message,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _SosSuccessView extends StatelessWidget {
  const _SosSuccessView({
    required this.location,
    required this.onViewOnMap,
  });

  final LocationInfo location;
  final VoidCallback onViewOnMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Interactive map fills the upper area
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LocationMapWidget(
                latitude: location.latitude,
                longitude: location.longitude,
              ),
            ),
          ),
        ),

        // Bottom Details Card & Button
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow('Latitude', location.latitude.toStringAsFixed(4)),
                        const Divider(height: 20),
                        _buildDetailRow('Longitude', location.longitude.toStringAsFixed(4)),
                        const Divider(height: 20),
                        _buildDetailRow('Address', location.address),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onViewOnMap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sosRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'VIEW ON MAP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
