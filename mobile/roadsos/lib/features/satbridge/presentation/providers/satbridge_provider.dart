import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/sos_packet.dart';
import '../../data/repositories/satbridge_repository.dart';
import '../../application/satbridge_sdk.dart';

class SatBridgeState {
  final List<SosPacket> packets;
  final bool isMeshActive;
  final Set<String> activeNodeUids;
  final bool isLoading;

  SatBridgeState({
    required this.packets,
    required this.isMeshActive,
    required this.activeNodeUids,
    required this.isLoading,
  });

  factory SatBridgeState.initial() => SatBridgeState(
        packets: [],
        isMeshActive: false,
        activeNodeUids: {},
        isLoading: false,
      );

  SatBridgeState copyWith({
    List<SosPacket>? packets,
    bool? isMeshActive,
    Set<String>? activeNodeUids,
    bool? isLoading,
  }) {
    return SatBridgeState(
      packets: packets ?? this.packets,
      isMeshActive: isMeshActive ?? this.isMeshActive,
      activeNodeUids: activeNodeUids ?? this.activeNodeUids,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final satBridgeRepositoryProvider = Provider<SatBridgeRepository>((ref) {
  return SatBridgeRepository();
});

final satBridgeProvider = StateNotifierProvider.autoDispose<SatBridgeNotifier, SatBridgeState>((ref) {
  final repository = ref.read(satBridgeRepositoryProvider);
  return SatBridgeNotifier(repository);
});

class SatBridgeNotifier extends StateNotifier<SatBridgeState> {
  final SatBridgeRepository _repository;

  SatBridgeNotifier(this._repository) : super(SatBridgeState.initial()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _repository.init();
    final saved = _repository.getSavedPackets();
    state = state.copyWith(
      packets: saved..sort((a, b) => b.priorityScore.compareTo(a.priorityScore)),
      isLoading: false,
    );
  }

  /// Toggles the SECM local network UDP multicast mesh network
  Future<void> toggleMesh() async {
    final sdk = SatBridge.instance;
    if (state.isMeshActive) {
      sdk.stopMesh();
      state = state.copyWith(isMeshActive: false);
    } else {
      state = state.copyWith(isMeshActive: true);
      await sdk.startMesh(onPacketReceived: (packet) {
        _handlePacketReceived(packet);
      });
    }
  }

  void _handlePacketReceived(SosPacket packet) {
    // Record sender node
    final updatedNodes = Set<String>.from(state.activeNodeUids)..add(packet.uid);
    
    // Save to database
    _repository.savePacket(packet);

    // Update state list and sort by Priority Score descending
    final list = List<SosPacket>.from(state.packets);
    final idx = list.indexWhere((p) => p.uid == packet.uid);
    if (idx >= 0) {
      list[idx] = packet;
    } else {
      list.add(packet);
    }
    list.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    state = state.copyWith(
      packets: list,
      activeNodeUids: updatedNodes,
    );
  }

  /// Emits a local SOS packet over mesh & local storage
  Future<void> triggerSOS({
    required double latitude,
    required double longitude,
    required int persons,
    required String severity,
    required int injured,
    required int children,
    required int elderly,
    required bool hasFood,
    required bool hasWater,
    String? customUid,
  }) async {
    final uid = customUid ?? 'SB${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
    
    final packet = SosPacket(
      uid: uid,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      persons: persons,
      severity: severity,
      injured: injured,
      children: children,
      elderly: elderly,
      hasFood: hasFood,
      hasWater: hasWater,
    );

    // Save locally
    await _repository.savePacket(packet);

    // Add to list and sort
    final list = List<SosPacket>.from(state.packets)..add(packet);
    list.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    state = state.copyWith(packets: list);

    // Broadcast over UDP Multicast mesh
    SatBridge.instance.broadcastSOS(packet);
  }

  /// AI SOS Compression Engine
  Future<String> compressReport(String text, double lat, double lon) async {
    return await _repository.compressSosWithAi(text, lat, lon);
  }

  /// Disaster Report Aggregator Heuristic
  /// Groups multiple nearby reports (within 5km cluster) and returns a summary
  List<DisasterCluster> getAggregatedDisasterClusters() {
    final List<DisasterCluster> clusters = [];
    final List<SosPacket> unclustered = List<SosPacket>.from(state.packets);

    for (final packet in unclustered) {
      bool matched = false;
      for (final cluster in clusters) {
        if (cluster.isWithinRange(packet.latitude, packet.longitude)) {
          cluster.addPacket(packet);
          matched = true;
          break;
        }
      }
      if (!matched) {
        clusters.add(DisasterCluster(centerPacket: packet));
      }
    }
    return clusters..sort((a, b) => b.totalPriorityScore.compareTo(a.totalPriorityScore));
  }

  Future<void> clearAll() async {
    await _repository.clearPackets();
    state = state.copyWith(packets: [], activeNodeUids: {});
  }
}

class DisasterCluster {
  final List<SosPacket> members = [];
  final double centerLat;
  final double centerLon;

  DisasterCluster({required SosPacket centerPacket})
      : centerLat = centerPacket.latitude,
        centerLon = centerPacket.longitude {
    members.add(centerPacket);
  }

  void addPacket(SosPacket packet) {
    members.add(packet);
  }

  // Approx ~5km coordinate tolerance matching threshold
  bool isWithinRange(double lat, double lon) {
    final diffLat = (lat - centerLat).abs();
    final diffLon = (lon - centerLon).abs();
    return diffLat < 0.045 && diffLon < 0.045;
  }

  int get totalPersons => members.fold(0, (sum, p) => sum + p.persons);
  int get totalInjured => members.fold(0, (sum, p) => sum + p.injured);
  int get totalPriorityScore => members.fold(0, (sum, p) => sum + p.priorityScore);

  String get areaDescription {
    return 'Area cluster Alert: $totalPersons people affected, $totalInjured injuries reported across ${members.length} nearby signals.';
  }
}
