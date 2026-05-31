import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../domain/sos_packet.dart';

class SatBridgeRepository {
  final http.Client _client;
  SatBridgeRepository({http.Client? client}) : _client = client ?? http.Client();

  Box<SosPacket>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<SosPacket>('satbridge_packets_box');
  }

  List<SosPacket> getSavedPackets() {
    if (_box == null) return [];
    return _box!.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> savePacket(SosPacket packet) async {
    await _box?.put(packet.uid, packet);
  }

  Future<void> clearPackets() async {
    await _box?.clear();
  }

  String get _baseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8000/api/v1';
  }

  /// AI SOS Compression Engine
  /// POSTs a natural language emergency report to the server to return the highly compressed SECM packet code.
  Future<String> compressSosWithAi(String reportText, double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/ai/compress-sos');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'report': reportText,
          'latitude': lat,
          'longitude': lon,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['compressed_code'] as String;
      }
    } catch (_) {}
    
    // Offline Heuristic Local Backup
    return _localCompressionFallback(reportText, lat, lon);
  }

  String _localCompressionFallback(String text, double lat, double lon) {
    final lowerText = text.toLowerCase();
    
    int persons = 1;
    String severity = 'M';
    int injured = 0;
    int children = 0;
    int elderly = 0;
    bool hasFood = true;
    bool hasWater = true;

    if (lowerText.contains('severe') || 
        lowerText.contains('critical') || 
        lowerText.contains('emergency') || 
        lowerText.contains('trapped') || 
        lowerText.contains('flood')) {
      severity = 'H';
    } else if (lowerText.contains('minor') || lowerText.contains('stable')) {
      severity = 'L';
    }

    final injuredMatch = RegExp(r'(\d+)\s*(?:injured|injury|hurt)').firstMatch(lowerText);
    if (injuredMatch != null) {
      injured = int.parse(injuredMatch.group(1)!);
    } else if (lowerText.contains('injured') || lowerText.contains('injury')) {
      injured = 1;
    }

    final childrenMatch = RegExp(r'(\d+)\s*(?:children|kid|child)').firstMatch(lowerText);
    if (childrenMatch != null) {
      children = int.parse(childrenMatch.group(1)!);
    }

    final elderlyMatch = RegExp(r'(\d+)\s*(?:elderly|old|senior)').firstMatch(lowerText);
    if (elderlyMatch != null) {
      elderly = int.parse(elderlyMatch.group(1)!);
    }

    final personsMatch = RegExp(r'(\d+)\s*(?:people|person|persons|trapped|members)').firstMatch(lowerText);
    if (personsMatch != null) {
      persons = int.parse(personsMatch.group(1)!);
    } else {
      persons = 1 + injured + children + elderly;
    }

    if (lowerText.contains('no food') || lowerText.contains('out of food') || lowerText.contains('need food')) {
      hasFood = false;
    }
    if (lowerText.contains('no water') || lowerText.contains('out of water') || lowerText.contains('thirsty') || lowerText.contains('need water')) {
      hasWater = false;
    }

    final uid = 'SB${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final epoch = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final foodVal = hasFood ? 1 : 0;
    final waterVal = hasWater ? 1 : 0;

    return '$uid|'
        '${lat.toStringAsFixed(4)}|'
        '${lon.toStringAsFixed(4)}|'
        'P$persons|'
        '$severity|'
        'I$injured|'
        'C$children|'
        'E$elderly|'
        'F$foodVal|'
        'W$waterVal|'
        'T$epoch';
  }
}
