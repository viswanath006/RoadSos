import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../contacts/presentation/providers/contacts_provider.dart';
import '../application/sos_alert_service.dart';

class SosAlertConfirmationScreen extends ConsumerStatefulWidget {
  const SosAlertConfirmationScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  ConsumerState<SosAlertConfirmationScreen> createState() => _SosAlertConfirmationScreenState();
}

class _SosAlertConfirmationScreenState extends ConsumerState<SosAlertConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsCount = ref.watch(contactsProvider).length;

    // Listen to transmission state
    ref.listen<SosAlertState>(sosAlertProvider, (prev, next) {
      if (next.status == SosAlertStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Emergency alerts sent successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.of(context).pop(); // Back to location view
      } else if (next.status == SosAlertStatus.error) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Transmission Failed'),
            content: Text(next.errorMessage ?? 'An unknown error occurred while sending alerts.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    final alertState = ref.watch(sosAlertProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Send SOS Alert',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Siren animation
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                    CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppTheme.sosRed.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.sosRed.withOpacity(0.15), width: 4),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.sosRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.sosRed.withOpacity(0.4),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Send emergency alert to\n$contactsCount contacts?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 36),

              // Bullet detail lines
              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildBulletItem(
                        icon: Icons.my_location_rounded,
                        text: 'Your location will be shared',
                      ),
                      const SizedBox(height: 16),
                      _buildBulletItem(
                        icon: Icons.sms_rounded,
                        text: 'They will receive an SMS',
                      ),
                      const SizedBox(height: 16),
                      _buildBulletItem(
                        icon: Icons.verified_user_outlined,
                        text: 'You can cancel anytime',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              if (alertState.status == SosAlertStatus.sending) ...[
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.sosRed),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Transmitting alerts...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ] else ...[
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(sosAlertProvider.notifier).sendSosAlert(
                                latitude: widget.latitude,
                                longitude: widget.longitude,
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.sosRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'SEND ALERT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.sosRed.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.sosRed, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
