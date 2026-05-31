import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/connectivity_banner.dart';
import '../../first_aid/presentation/screens/first_aid_screen.dart';
import '../../offline/presentation/providers/connectivity_provider.dart';
import '../../offline/presentation/screens/offline_dashboard_screen.dart';
import '../../services/presentation/breakdown_screen.dart';
import '../../services/presentation/emergency_services_screen.dart';
import '../../sos/presentation/sos_screen.dart';
import '../../crash_detection/presentation/providers/crash_providers.dart';
import '../../crash_detection/presentation/widgets/crash_alert_dialog.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/sos_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openSos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SosScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);
    final isOffline = networkStatus == NetworkStatus.offline;

    // Watch crash detection state to initialize sensor listener
    final crashState = ref.watch(crashDetectionProvider);

    // Listen to crash detection state to trigger full-screen alert dialog
    ref.listen<CrashDetectionState>(crashDetectionProvider, (previous, next) {
      if (next.status == CrashDetectionStatus.alerting) {
        showGeneralDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.9),
          pageBuilder: (context, anim1, anim2) {
            return const CrashAlertDialog();
          },
        );
      }
    });

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.sosRed),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppTheme.sosRed, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'RoadSOS Premium',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.offline_bolt_outlined, color: Colors.orange),
              title: const Text('Offline Emergency Hub'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const OfflineDashboardScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppTheme.textSecondary, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(text: 'Road', style: TextStyle(color: AppTheme.textPrimary)),
              TextSpan(text: 'SoS', style: TextStyle(color: AppTheme.sosRed)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Network Connectivity Banner
            const ConnectivityBanner(),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Stay Safe. We are here to help.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(flex: 2),

                    // Concentric SOS Button
                    SosButton(onPressed: () => _openSos(context)),

                    const Spacer(flex: 3),

                    // Offline Banner Promo if Offline
                    if (isOffline) ...[
                      Card(
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.orange.shade200),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const OfflineDashboardScreen(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.offline_bolt_rounded, color: Colors.orange.shade800),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Offline Dashboard Active',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Access guides & helplines without connection',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.orange.shade800),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Horizontal Actions Layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        QuickActionCard(
                          title: 'Emergency\nServices',
                          icon: Icons.local_hospital_outlined,
                          color: AppTheme.sosRed,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const EmergencyServicesScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        QuickActionCard(
                          title: 'First Aid\nGuides',
                          icon: Icons.medical_services_outlined,
                          color: Colors.teal,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const FirstAidScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        QuickActionCard(
                          title: 'Breakdown\nAssistance',
                          icon: Icons.car_repair_outlined,
                          color: Colors.blue,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const BreakdownScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
