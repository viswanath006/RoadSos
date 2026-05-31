import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

import '../../../../core/theme/app_theme.dart';
import '../../domain/sos_packet.dart';
import '../providers/satbridge_provider.dart';

class SatBridgeDashboardScreen extends ConsumerStatefulWidget {
  const SatBridgeDashboardScreen({super.key});

  @override
  ConsumerState<SatBridgeDashboardScreen> createState() => _SatBridgeDashboardScreenState();
}

class _SatBridgeDashboardScreenState extends ConsumerState<SatBridgeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _aiReportController = TextEditingController();
  final _latController = TextEditingController(text: '13.0067'); // Default close to IITM
  final _lonController = TextEditingController(text: '80.2206');

  int _persons = 1;
  int _injured = 0;
  int _children = 0;
  int _elderly = 0;
  String _severity = 'M'; // 'H', 'M', 'L'
  bool _hasFood = true;
  bool _hasWater = true;

  bool _isCompressing = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiReportController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLocating = true;
    });
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _latController.text = pos.latitude.toStringAsFixed(4);
      _lonController.text = pos.longitude.toStringAsFixed(4);
    } catch (_) {
      // Keep defaults
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _compressSosReport() async {
    final text = _aiReportController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isCompressing = true;
    });

    final lat = double.tryParse(_latController.text) ?? 13.0067;
    final lon = double.tryParse(_lonController.text) ?? 80.2206;

    try {
      final compressedCode = await ref.read(satBridgeProvider.notifier).compressReport(text, lat, lon);
      
      // Parse compressed code back into form values to pre-populate
      final parsed = SosPacket.fromCompressedString(compressedCode);
      setState(() {
        _persons = parsed.persons;
        _injured = parsed.injured;
        _children = parsed.children;
        _elderly = parsed.elderly;
        _severity = parsed.severity;
        _hasFood = parsed.hasFood;
        _hasWater = parsed.hasWater;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI Compressed Packet: ${parsed.toCompressedString()}'),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to compress with AI, using local parsing rules.'),
          backgroundColor: AppTheme.sosRed,
        ),
      );
    } finally {
      setState(() {
        _isCompressing = false;
      });
    }
  }

  void _submitSos() {
    final lat = double.tryParse(_latController.text) ?? 13.0067;
    final lon = double.tryParse(_lonController.text) ?? 80.2206;

    ref.read(satBridgeProvider.notifier).triggerSOS(
          latitude: lat,
          longitude: lon,
          persons: _persons,
          severity: _severity,
          injured: _injured,
          children: _children,
          elderly: _elderly,
          hasFood: _hasFood,
          hasWater: _hasWater,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('SOS Packet broadcasted over mesh network!'),
        backgroundColor: Colors.green.shade700,
      ),
    );

    // Reset Form
    _aiReportController.clear();
    setState(() {
      _persons = 1;
      _injured = 0;
      _children = 0;
      _elderly = 0;
      _severity = 'M';
      _hasFood = true;
      _hasWater = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bridgeState = ref.watch(satBridgeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark mode for disaster responder theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('SatBridge SECM SDK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Row(
            children: [
              Text(
                bridgeState.isMeshActive ? 'MESH ON' : 'MESH OFF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: bridgeState.isMeshActive ? Colors.green : Colors.grey,
                ),
              ),
              Switch(
                value: bridgeState.isMeshActive,
                activeColor: Colors.green,
                onChanged: (_) {
                  ref.read(satBridgeProvider.notifier).toggleMesh();
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white60),
            onPressed: () {
              ref.read(satBridgeProvider.notifier).clearAll();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.tealAccent,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.tealAccent,
          tabs: const [
            Tab(icon: Icon(Icons.send_rounded), text: 'Create SOS'),
            Tab(icon: Icon(Icons.format_list_numbered_rounded), text: 'Rescue Queue'),
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Clusters'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateSosTab(bridgeState),
          _buildRescueQueueTab(bridgeState),
          _buildClustersTab(),
        ],
      ),
    );
  }

  Widget _buildCreateSosTab(SatBridgeState bridgeState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status Card
          _buildMeshStatusCard(bridgeState),
          const SizedBox(height: 16),

          // AI Helper Text Area
          Card(
            color: const Color(0xFF1E1E1E),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade800),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: Colors.tealAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI SOS Compression Engine',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Type your scenario. AI will compress it to under 100 bytes for low-bandwidth mesh/satellite relay.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiReportController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      hintText: 'e.g., We are trapped on the roof. 3 children, 2 elderly. Water running out...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCompressing ? null : _compressSosReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isCompressing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Icon(Icons.auto_awesome),
                      label: const Text('COMPRESS WITH AI', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SOS Form
          Card(
            color: const Color(0xFF1E1E1E),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade800),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emergency Details Form', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Latitude', labelStyle: TextStyle(color: Colors.white60)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lonController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Longitude', labelStyle: TextStyle(color: Colors.white60)),
                          ),
                        ),
                        IconButton(
                          icon: _isLocating 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Icon(Icons.my_location, color: Colors.tealAccent),
                          onPressed: _fetchLocation,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCounterRow('Affected Persons', _persons, (val) => setState(() => _persons = math.max(1, val))),
                    _buildCounterRow('Injured Count', _injured, (val) => setState(() => _injured = math.max(0, val))),
                    _buildCounterRow('Children Count', _children, (val) => setState(() => _children = math.max(0, val))),
                    _buildCounterRow('Elderly Count', _elderly, (val) => setState(() => _elderly = math.max(0, val))),
                    const SizedBox(height: 16),
                    const Text('Severity', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppTheme.sosRed,
                        selectedForegroundColor: Colors.white,
                        unselectedForegroundColor: Colors.white70,
                      ),
                      segments: const [
                        ButtonSegment(value: 'L', label: Text('Low')),
                        ButtonSegment(value: 'M', label: Text('Medium')),
                        ButtonSegment(value: 'H', label: Text('High')),
                      ],
                      selected: {_severity},
                      onSelectionChanged: (val) => setState(() => _severity = val.first),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Has Food Supply', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: _hasFood,
                          activeColor: Colors.tealAccent,
                          onChanged: (val) => setState(() => _hasFood = val),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Has Water Supply', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: _hasWater,
                          activeColor: Colors.tealAccent,
                          onChanged: (val) => setState(() => _hasWater = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitSos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.sosRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('TRANSMIT SOS OVER MESH', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshStatusCard(SatBridgeState bridgeState) {
    return Card(
      color: bridgeState.isMeshActive ? Colors.green.withOpacity(0.08) : Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: bridgeState.isMeshActive ? Colors.green.withOpacity(0.3) : Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              bridgeState.isMeshActive ? Icons.wifi_tethering_rounded : Icons.portable_wifi_off_rounded,
              color: bridgeState.isMeshActive ? Colors.green : Colors.grey,
              size: 36,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bridgeState.isMeshActive ? 'SatBridge Mesh Protocol Active' : 'Mesh Protocol Idle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: bridgeState.isMeshActive ? Colors.green : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bridgeState.isMeshActive
                        ? 'Discovered ${bridgeState.activeNodeUids.length} active relay nodes nearby'
                        : 'Toggle Mesh above to start local mesh routing',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.tealAccent),
                onPressed: () => onChanged(value - 1),
              ),
              Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRescueQueueTab(SatBridgeState bridgeState) {
    if (bridgeState.packets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl_rounded, size: 50, color: Colors.white30),
            SizedBox(height: 12),
            Text('No active rescue queues recorded', style: TextStyle(color: Colors.white30)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bridgeState.packets.length,
      itemBuilder: (context, index) {
        final packet = bridgeState.packets[index];
        return _buildQueueItemCard(packet, index + 1);
      },
    );
  }

  Widget _buildQueueItemCard(SosPacket packet, int rank) {
    final isCritical = packet.priorityScore >= 10;
    
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isCritical ? AppTheme.sosRed.withOpacity(0.4) : Colors.grey.shade850),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCritical ? AppTheme.sosRed : Colors.teal.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PRIORITY $rank',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'UID: ${packet.uid}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.teal.shade950, shape: BoxShape.circle),
                  child: Text(
                    '${packet.priorityScore}',
                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQueueMetric('People', '${packet.persons}'),
                _buildQueueMetric('Injured', '${packet.injured}'),
                _buildQueueMetric('Kids', '${packet.children}'),
                _buildQueueMetric('Elderly', '${packet.elderly}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GPS: ${packet.latitude.toStringAsFixed(4)}, ${packet.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Food: ${packet.hasFood ? "Yes" : "NO"} | Water: ${packet.hasWater ? "Yes" : "NO"}',
                  style: TextStyle(
                    color: !packet.hasWater || !packet.hasFood ? Colors.orange : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildClustersTab() {
    final notifier = ref.read(satBridgeProvider.notifier);
    final clusters = notifier.getAggregatedDisasterClusters();

    if (clusters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 50, color: Colors.white30),
            SizedBox(height: 12),
            Text('No aggregated disaster coordinates detected yet', style: TextStyle(color: Colors.white30)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clusters.length,
      itemBuilder: (context, index) {
        final cluster = clusters[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade850),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DISASTER CENTER', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        'Score: ${cluster.totalPriorityScore}',
                        style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  cluster.areaDescription,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 12),
                Text(
                  'Center GPS: ${cluster.centerLat.toStringAsFixed(4)}, ${cluster.centerLon.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white55, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
