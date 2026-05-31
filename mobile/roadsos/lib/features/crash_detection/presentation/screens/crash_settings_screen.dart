import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/crash_settings.dart';
import '../../domain/models/crash_event.dart';
import '../providers/crash_providers.dart';

class CrashSettingsScreen extends ConsumerWidget {
  const CrashSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(crashSettingsProvider);
    final history = ref.watch(crashEventLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crash Detection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Master Enable Toggle
            _buildEnableCard(context, ref, settings),
            const SizedBox(height: 16),

            if (settings.enabled) ...[
              // Sensitivity Preset Selector
              _buildSensitivityCard(context, ref, settings),
              const SizedBox(height: 16),

              // Countdown Duration Settings
              _buildTimerCard(context, ref, settings),
              const SizedBox(height: 16),

              // Recent Crash Events Log
              _buildLogsCard(context, ref, history),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnableCard(BuildContext context, WidgetRef ref, CrashSettings settings) {
    return Card(
      elevation: 0,
      color: settings.enabled ? AppTheme.sosRed.withOpacity(0.06) : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: settings.enabled ? AppTheme.sosRed.withOpacity(0.2) : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: settings.enabled ? AppTheme.sosRed : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.leak_add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto SOS Trigger',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: settings.enabled ? AppTheme.sosRed : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Automatically send emergency messages on sudden deceleration or impact.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.enabled,
              activeColor: AppTheme.sosRed,
              onChanged: (value) {
                ref.read(crashSettingsProvider.notifier).toggleEnabled(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivityCard(BuildContext context, WidgetRef ref, CrashSettings settings) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impact Sensitivity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'High sensitivity triggers more easily (safer for lower speeds), while Low sensitivity reduces false positives on rough roads.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            SegmentedButton<CrashSensitivity>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.sosRed,
                selectedForegroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: CrashSensitivity.low, label: Text('Low')),
                ButtonSegment(value: CrashSensitivity.medium, label: Text('Medium')),
                ButtonSegment(value: CrashSensitivity.high, label: Text('High')),
                ButtonSegment(value: CrashSensitivity.custom, label: Text('Custom')),
              ],
              selected: {settings.sensitivity},
              onSelectionChanged: (selection) {
                ref.read(crashSettingsProvider.notifier).setSensitivity(selection.first);
              },
            ),
            if (settings.sensitivity == CrashSensitivity.custom) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _buildSliderRow(
                title: 'Impact Threshold',
                value: settings.impactThreshold,
                min: 1.5,
                max: 10.0,
                suffix: ' G',
                subtitle: 'Trigger force in G-forces (1G ≈ 9.8 m/s²)',
                onChanged: (val) {
                  ref.read(crashSettingsProvider.notifier).setCustomThresholds(
                        impact: val,
                        speed: settings.speedChangeThreshold,
                        rotation: settings.rotationThreshold,
                      );
                },
              ),
              const SizedBox(height: 12),
              _buildSliderRow(
                title: 'Speed Change Threshold',
                value: settings.speedChangeThreshold,
                min: 2.0,
                max: 20.0,
                suffix: ' m/s',
                subtitle: 'Estimated change in velocity during crash',
                onChanged: (val) {
                  ref.read(crashSettingsProvider.notifier).setCustomThresholds(
                        impact: settings.impactThreshold,
                        speed: val,
                        rotation: settings.rotationThreshold,
                      );
                },
              ),
              const SizedBox(height: 12),
              _buildSliderRow(
                title: 'Rotation Threshold',
                value: settings.rotationThreshold,
                min: 1.0,
                max: 10.0,
                suffix: ' rad/s',
                subtitle: 'Minimum device spin to confirm rollover',
                onChanged: (val) {
                  ref.read(crashSettingsProvider.notifier).setCustomThresholds(
                        impact: settings.impactThreshold,
                        speed: settings.speedChangeThreshold,
                        rotation: val,
                      );
                },
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildThresholdInfo('Min Impact Force', '${settings.impactThreshold} G'),
                    const SizedBox(height: 6),
                    _buildThresholdInfo('Min Velocity Shift', '${settings.speedChangeThreshold} m/s (~${(settings.speedChangeThreshold * 3.6).toStringAsFixed(0)} km/h)'),
                    const SizedBox(height: 6),
                    _buildThresholdInfo('Min Spin Rotation', '${settings.rotationThreshold} rad/s'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildSliderRow({
    required String title,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required String subtitle,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(1)}$suffix',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.sosRed)),
          ],
        ),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(),
          activeColor: AppTheme.sosRed,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimerCard(BuildContext context, WidgetRef ref, CrashSettings settings) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Safety Confirmation Timer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Time allowed to confirm you are safe before the app triggers emergency notifications.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.countdownDuration.toDouble(),
                    min: 5.0,
                    max: 60.0,
                    divisions: 11,
                    activeColor: AppTheme.sosRed,
                    onChanged: (val) {
                      ref.read(crashSettingsProvider.notifier).setCountdownDuration(val.toInt());
                    },
                  ),
                ),
                Container(
                  width: 50,
                  alignment: Alignment.center,
                  child: Text(
                    '${settings.countdownDuration}s',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.sosRed),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard(BuildContext context, WidgetRef ref, List<CrashEvent> history) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Crash Incident Log',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                if (history.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppTheme.sosRed, visualDensity: VisualDensity.compact),
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear Crash History?'),
                          content: const Text('This will delete all saved crash logs. This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                ref.read(crashEventLogProvider.notifier).clearHistory();
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Clear All', style: TextStyle(color: AppTheme.sosRed)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No collision events logged yet',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final event = history[index];
                  return _buildLogItem(context, event);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, CrashEvent event) {
    IconData icon;
    Color color;
    String statusLabel;

    switch (event.userResponse) {
      case 'safe':
        icon = Icons.check_circle_outline;
        color = Colors.green.shade600;
        statusLabel = 'User safe (Alert Cancelled)';
        break;
      case 'help_needed':
        icon = Icons.error_outline;
        color = AppTheme.sosRed;
        statusLabel = 'Immediate Help Requested';
        break;
      default:
        icon = Icons.timer_off_outlined;
        color = Colors.orange.shade700;
        statusLabel = 'No response (Auto SOS Sent)';
    }

    final dateStr = '${event.timestamp.day}/${event.timestamp.month} ${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Metrics: Max Force: ${event.peakAcceleration.toStringAsFixed(1)}G | Speed Shift: ${event.speedChange.toStringAsFixed(1)}m/s | Spin: ${event.peakGyroscope.toStringAsFixed(1)}rad/s',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              if (event.latitude != null && event.longitude != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Location: ${event.latitude!.toStringAsFixed(4)}, ${event.longitude!.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
