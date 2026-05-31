import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/connectivity_banner.dart';
import '../../../services/presentation/emergency_services_screen.dart';
import '../providers/crash_providers.dart';

class CrashAlertDialog extends ConsumerStatefulWidget {
  const CrashAlertDialog({super.key});

  @override
  ConsumerState<CrashAlertDialog> createState() => _CrashAlertDialogState();
}

class _CrashAlertDialogState extends ConsumerState<CrashAlertDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crashState = ref.watch(crashDetectionProvider);
    final settings = ref.watch(crashSettingsProvider);

    ref.listen<CrashDetectionState>(crashDetectionProvider, (prev, next) {
      if (next.status == CrashDetectionStatus.sosSent) {
        ref.read(crashDetectionProvider.notifier).resetToMonitoring();
        Navigator.of(context).pop(); // Pop dialog
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const EmergencyServicesScreen(),
          ),
        );
      }
    });

    final totalDuration = settings.countdownDuration > 0 ? settings.countdownDuration : 15;
    final displaySeconds = crashState.countdownSecondsLeft;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFE53935), // Vibrant red background
        body: SafeArea(
          child: Column(
            children: [
              const ConnectivityBanner(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Title
                      const Text(
                        'Possible Accident Detected!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Collision Icon Graphics
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car_filled_outlined, color: Colors.white70, size: 48),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning_rounded, color: Color(0xFFE53935), size: 36),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.directions_car_filled_outlined, color: Colors.white70, size: 48),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Are you safe text
                      const Text(
                        'Are you safe?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'We will automatically send SOS\nif we don\'t hear from you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),

                      // Circular countdown
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 6),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$displaySeconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'Seconds',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Safe/Help buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ref.read(crashDetectionProvider.notifier).cancelAlert();
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFE53935),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "I'M SAFE",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ref.read(crashDetectionProvider.notifier).triggerImmediateHelp();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: const Text(
                                'NEED HELP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
