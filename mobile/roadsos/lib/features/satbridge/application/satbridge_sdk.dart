import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/sos_packet.dart';

class SatBridge {
  static final SatBridge instance = SatBridge._internal();
  SatBridge._internal();

  static const int multicastPort = 45824;
  static final InternetAddress multicastAddress = InternetAddress('224.0.0.1');

  RawDatagramSocket? _socket;
  bool _isMeshStarted = false;
  final Set<String> _seenPacketUids = {};
  
  void Function(SosPacket)? _onPacketReceived;

  bool get isMeshActive => _isMeshStarted;

  static Future<void> initialize() async {
    // Initializer hook for SatBridge SDK
  }

  /// Starts the Bluetooth/WiFi UDP multicast mesh listener
  Future<void> startMesh({required void Function(SosPacket) onPacketReceived}) async {
    if (_isMeshStarted) return;
    _onPacketReceived = onPacketReceived;
    _isMeshStarted = true;

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        multicastPort,
        reuseAddress: true,
      );
      _socket?.multicastLoopback = true;
      _socket?.joinMulticast(multicastAddress);

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            try {
              final rawStr = utf8.decode(datagram.data);
              final packet = SosPacket.fromCompressedString(rawStr);
              _handleIncomingPacket(packet);
            } catch (e) {
              debugPrint('Failed to decode/parse mesh packet: $e');
            }
          }
        }
      });
      debugPrint('SatBridge SECM Mesh active on port $multicastPort');
    } catch (e) {
      debugPrint('Failed to initialize mesh socket: $e');
      _isMeshStarted = false;
    }
  }

  void _handleIncomingPacket(SosPacket packet) {
    if (_seenPacketUids.contains(packet.uid)) {
      // Deduplicate to prevent loops
      return;
    }
    _seenPacketUids.add(packet.uid);

    // Alert provider state listener
    _onPacketReceived?.call(packet);

    // Multi-Hop Relay: automatically forward to next hop
    relaySOS(packet);
  }

  /// Broadcasts a newly created local SOS packet
  void broadcastSOS(SosPacket packet) {
    _seenPacketUids.add(packet.uid);
    final rawData = packet.toCompressedString();
    final data = utf8.encode(rawData);
    try {
      _socket?.send(data, multicastAddress, multicastPort);
      debugPrint('SatBridge Broadcasted: $rawData');
    } catch (e) {
      debugPrint('Mesh broadcast failed: $e');
    }
  }

  /// Relays an incoming packet from another node
  void relaySOS(SosPacket packet) {
    final rawData = packet.toCompressedString();
    final data = utf8.encode(rawData);
    try {
      _socket?.send(data, multicastAddress, multicastPort);
      debugPrint('SatBridge Hopped/Relayed: $rawData');
    } catch (e) {
      debugPrint('Mesh relay failed: $e');
    }
  }

  /// Stops mesh operations and cleans up socket
  void stopMesh() {
    _socket?.close();
    _socket = null;
    _isMeshStarted = false;
    _seenPacketUids.clear();
  }
}
