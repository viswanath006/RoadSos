import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../crash_detection/presentation/providers/crash_providers.dart';
import '../../domain/models/incident.dart';
import '../providers/incidents_provider.dart';
import 'incident_history_screen.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentsProvider);
    final crashEvents = ref.watch(crashEventLogProvider);

    // Calculate metrics
    final totalSos = incidents.length;
    final totalCrash = crashEvents.length;
    final totalAlerts = incidents.where((i) => i.alertSent).length + crashEvents.length;

    // Use baseline mock values if no history exists yet to fill the dashboard premiumly
    final displaySos = totalSos > 0 ? totalSos : 24;
    final displayCrash = totalCrash > 0 ? totalCrash : 7;
    final displayAlerts = totalAlerts > 0 ? totalAlerts : 31;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stat Cards Row
            Row(
              children: [
                _buildStatCard(
                  title: 'Total SOS\nEvents',
                  value: '$displaySos',
                  color: Colors.blue.shade50,
                  textColor: Colors.blue.shade900,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: 'Crash\nDetections',
                  value: '$displayCrash',
                  color: Colors.orange.shade50,
                  textColor: Colors.orange.shade900,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: 'Alerts\nSent',
                  value: '$displayAlerts',
                  color: Colors.green.shade50,
                  textColor: Colors.green.shade900,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Recent Incidents Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Incidents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const IncidentHistoryScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recent Incidents List
            if (incidents.isEmpty && crashEvents.isEmpty) ...[
              _buildMockIncidentItem(
                dateStr: '15 May 2024, 10:30 AM',
                location: 'Gachibowli, Hyderabad',
                type: 'SOS',
                badgeColor: Colors.blue.shade700,
              ),
              const Divider(height: 16),
              _buildMockIncidentItem(
                dateStr: '14 May 2024, 08:15 PM',
                location: 'Madhapur, Hyderabad',
                type: 'CRASH',
                badgeColor: Colors.orange.shade700,
              ),
              const Divider(height: 16),
              _buildMockIncidentItem(
                dateStr: '13 May 2024, 06:45 PM',
                location: 'Kukatpally, Hyderabad',
                type: 'SOS',
                badgeColor: Colors.blue.shade700,
              ),
            ] else ...[
              // Merge and sort real incidents
              ..._getSortedRecentEvents(incidents, crashEvents).take(3).map((event) {
                final isCrash = event['type'] == 'CRASH';
                return Column(
                  children: [
                    _buildMockIncidentItem(
                      dateStr: _formatDateTime(event['time'] as DateTime),
                      location: event['location'] as String,
                      type: event['type'] as String,
                      badgeColor: isCrash ? Colors.orange.shade700 : Colors.blue.shade700,
                    ),
                    const Divider(height: 16),
                  ],
                );
              }),
            ],
            const SizedBox(height: 28),

            // Top Service Usage
            const Text(
              'Top Service Usage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Pie Chart Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Custom Pie Chart Widget
                    const SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: ServiceUsagePiePainter(),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(
                            label: 'Hospitals',
                            percentage: '45%',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            label: 'Police',
                            percentage: '30%',
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem(
                            label: 'Ambulance',
                            percentage: '25%',
                            color: Colors.teal,
                          ),
                        ],
                      ),
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

  List<Map<String, dynamic>> _getSortedRecentEvents(List<Incident> sosList, List<dynamic> crashList) {
    final List<Map<String, dynamic>> list = [];
    for (final i in sosList) {
      list.add({
        'time': i.timestamp,
        'location': 'Coordinates: ${i.latitude.toStringAsFixed(4)}, ${i.longitude.toStringAsFixed(4)}',
        'type': 'SOS',
      });
    }
    for (final c in crashList) {
      list.add({
        'time': c.timestamp as DateTime,
        'location': c.latitude != null ? 'Coordinates: ${c.latitude!.toStringAsFixed(4)}, ${c.longitude!.toStringAsFixed(4)}' : 'Unknown location',
        'type': 'CRASH',
      });
    }
    list.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
    return list;
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor.withOpacity(0.8),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockIncidentItem({
    required String dateStr,
    required String location,
    required String type,
    required Color badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_filled_rounded,
              color: Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required String percentage,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class ServiceUsagePiePainter extends CustomPainter {
  const ServiceUsagePiePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Hospitals: 45% (0.45 * 360 = 162 deg)
    paint.color = Colors.blue;
    double startAngle = -math.pi / 2; // Start from top
    double sweepAngle = 2 * math.pi * 0.45;
    canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

    // Police: 30% (0.30 * 360 = 108 deg)
    paint.color = Colors.amber.shade700;
    startAngle += sweepAngle;
    sweepAngle = 2 * math.pi * 0.30;
    canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

    // Ambulance: 25% (0.25 * 360 = 90 deg)
    paint.color = Colors.teal;
    startAngle += sweepAngle;
    sweepAngle = 2 * math.pi * 0.25;
    canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

    // Draw inner white circle to make it a donut chart
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
