class SosPacket {
  final String uid;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final int persons;
  final String severity; // 'H' (High), 'M' (Medium), 'L' (Low)
  final int injured;
  final int children;
  final int elderly;
  final bool hasFood;
  final bool hasWater;

  SosPacket({
    required this.uid,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.persons,
    required this.severity,
    required this.injured,
    required this.children,
    required this.elderly,
    required this.hasFood,
    required this.hasWater,
  });

  /// Priority Score calculation based on SECM heuristics
  /// Score = (Injuries * 5) + (Children * 3) + (Elderly * 2) + (No Water ? 4 : 0)
  int get priorityScore {
    int score = 0;
    score += injured * 5;
    score += children * 3;
    score += elderly * 2;
    if (!hasWater) {
      score += 4;
    }
    return score;
  }

  /// Compressed serialization under 100 bytes suitable for mesh/satellite
  /// Format: uid|lat|lon|P<persons>|<severity>|I<injured>|C<children>|E<elderly>|F<food>|W<water>|T<epochSeconds>
  /// Example: A234|16.50|80.64|P4|H|I1|C2|E0|F1|W0|T17165842
  String toCompressedString() {
    final foodVal = hasFood ? 1 : 0;
    final waterVal = hasWater ? 1 : 0;
    final epoch = (timestamp.millisecondsSinceEpoch / 1000).round();
    
    return '$uid|'
        '${latitude.toStringAsFixed(4)}|'
        '${longitude.toStringAsFixed(4)}|'
        'P$persons|'
        '$severity|'
        'I$injured|'
        'C$children|'
        'E$elderly|'
        'F$foodVal|'
        'W$waterVal|'
        'T$epoch';
  }

  /// Parses compressed SECM packets
  factory SosPacket.fromCompressedString(String raw) {
    final parts = raw.split('|');
    if (parts.length < 11) {
      throw const FormatException('Invalid compressed SECM packet format');
    }

    final uid = parts[0];
    final lat = double.parse(parts[1]);
    final lon = double.parse(parts[2]);
    final persons = int.parse(parts[3].replaceAll('P', ''));
    final severity = parts[4];
    final injured = int.parse(parts[5].replaceAll('I', ''));
    final children = int.parse(parts[6].replaceAll('C', ''));
    final elderly = int.parse(parts[7].replaceAll('E', ''));
    final hasFood = parts[8].replaceAll('F', '') == '1';
    final hasWater = parts[9].replaceAll('W', '') == '1';
    final epoch = int.parse(parts[10].replaceAll('T', ''));
    
    final timestamp = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);

    return SosPacket(
      uid: uid,
      timestamp: timestamp,
      latitude: lat,
      longitude: lon,
      persons: persons,
      severity: severity,
      injured: injured,
      children: children,
      elderly: elderly,
      hasFood: hasFood,
      hasWater: hasWater,
    );
  }
}
