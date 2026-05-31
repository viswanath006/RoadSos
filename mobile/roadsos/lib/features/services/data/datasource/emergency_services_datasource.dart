import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class EmergencyServicesRemoteDataSource {
  Future<Map<String, dynamic>> fetchNearbyServices({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000,
  });
}

class EmergencyServicesRemoteDataSourceImpl
    implements EmergencyServicesRemoteDataSource {
  EmergencyServicesRemoteDataSourceImpl({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Map<String, dynamic>> fetchNearbyServices({
    required double latitude,
    required double longitude,
    double radiusInMeters = 5000,
  }) async {
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:$radiusInMeters,$latitude,$longitude);
  way["amenity"="hospital"](around:$radiusInMeters,$latitude,$longitude);
  relation["amenity"="hospital"](around:$radiusInMeters,$latitude,$longitude);
  
  node["amenity"="police"](around:$radiusInMeters,$latitude,$longitude);
  way["amenity"="police"](around:$radiusInMeters,$latitude,$longitude);
  relation["amenity"="police"](around:$radiusInMeters,$latitude,$longitude);
  
  node["emergency"="ambulance_station"](around:$radiusInMeters,$latitude,$longitude);
  way["emergency"="ambulance_station"](around:$radiusInMeters,$latitude,$longitude);
  relation["emergency"="ambulance_station"](around:$radiusInMeters,$latitude,$longitude);
  
  node["amenity"="ambulance_station"](around:$radiusInMeters,$latitude,$longitude);
  way["amenity"="ambulance_station"](around:$radiusInMeters,$latitude,$longitude);
  relation["amenity"="ambulance_station"](around:$radiusInMeters,$latitude,$longitude);
);
out center;
''';

    final uri = Uri.parse('https://overpass-api.de/api/interpreter');
    try {
      final response = await _client.post(
        uri,
        body: {'data': query},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to load emergency services. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or API Error: $e');
    }
  }
}
