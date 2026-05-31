import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/connectivity_banner.dart';
import '../../first_aid/presentation/screens/first_aid_screen.dart';
import '../../offline/presentation/providers/connectivity_provider.dart';
import '../../offline/presentation/screens/offline_dashboard_screen.dart';
import '../../services/presentation/breakdown_screen.dart';
import '../../services/presentation/emergency_services_screen.dart';
import '../../sos/presentation/sos_screen.dart';
import '../../contacts/presentation/screens/contact_list_screen.dart';
import '../../crash_detection/presentation/providers/crash_providers.dart';
import '../../crash_detection/presentation/widgets/crash_alert_dialog.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/sos_button.dart';
import '../../satbridge/presentation/screens/satbridge_dashboard_screen.dart';

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
            ListTile(
              leading: const Icon(Icons.wifi_tethering_rounded, color: Colors.teal),
              title: const Text('SatBridge SECM Mesh'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SatBridgeDashboardScreen()),
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
          ValueListenableBuilder(
            valueListenable: Hive.box('offline_settings_box').listenable(keys: ['voice_sos_enabled']),
            builder: (context, Box box, _) {
              final isEnabled = box.get('voice_sos_enabled', defaultValue: false) as bool;
              return IconButton(
                icon: Icon(
                  isEnabled ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: isEnabled ? Colors.teal : AppTheme.textSecondary,
                  size: 28,
                ),
                onPressed: () => _showVoiceSosSheet(context),
              );
            },
          ),
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
                    const SizedBox(height: 20),
                    // RoadSoS Logo & Shield
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.shield, color: AppTheme.sosRed, size: 36),
                            const Icon(Icons.add, color: Colors.white, size: 18),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'RoadSoS',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Golden Hour • One Tap Emergency',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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

                    // 2x2 Grid Actions Layout
                    Column(
                      children: [
                        Row(
                          children: [
                            QuickActionCard(
                              title: 'Emergency\nServices',
                              icon: Icons.emergency_outlined,
                              color: AppTheme.sosRed,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const EmergencyServicesScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            QuickActionCard(
                              title: 'First Aid\nGuides',
                              icon: Icons.medical_services_outlined,
                              color: Colors.green.shade700,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const FirstAidScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            QuickActionCard(
                              title: 'Breakdown\nAssistance',
                              icon: Icons.car_repair_outlined,
                              color: Colors.orange.shade850,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BreakdownScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            QuickActionCard(
                              title: 'Emergency\nContacts',
                              icon: Icons.people_outline_rounded,
                              color: Colors.blue.shade700,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ContactListScreen(),
                                ),
                              ),
                            ),
                          ],
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

  void _showVoiceSosSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final box = Hive.box('offline_settings_box');
            bool isEnabled = box.get('voice_sos_enabled', defaultValue: false) as bool;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hands-Free Voice SOS',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'When active, RoadSoS continuously listens for emergency keywords like "Help Help" or "Emergency" to automatically trigger SOS notifications hands-free.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isEnabled ? Colors.teal.withOpacity(0.06) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEnabled ? Colors.teal.withOpacity(0.3) : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                              color: isEnabled ? Colors.teal : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEnabled ? 'Listening Active' : 'Voice SOS Disabled',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isEnabled ? Colors.teal : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isEnabled,
                          activeColor: Colors.teal,
                          onChanged: (value) async {
                            await box.put('voice_sos_enabled', value);
                            setModalState(() {
                              isEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isEnabled) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openSos(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sosRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.record_voice_over_rounded),
                      label: const Text(
                        'SIMULATE VOICE TRIGGER ("HELP")',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
