import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import '../models/emergency_service.dart';

class ApiService {
  final DatabaseService _dbService = DatabaseService();

  /// Fetch nearby services from Overpass API (OpenStreetMap).
  /// Falls back to SQLite cache when offline or API fails.
  Future<List<Map<String, dynamic>>> fetchNearbyServices(
      double lat, double lon, String serviceType,
      {double radiusMeters = 10000}) async {
    // Build multiple Overpass queries per type to maximize results
    List<String> queryLines = _buildQueryLines(serviceType, lat, lon, radiusMeters);
    final String queryBody = queryLines.join('\n');
    final String query = '[out:json][timeout:25];($queryBody);out body center 30;';

    debugPrint('[ApiService] Querying Overpass for "$serviceType" around ($lat,$lon) r=${radiusMeters}m');

    // Use GET with query parameter + User-Agent (required by Overpass API)
    final Uri url = Uri.parse(
      'https://overpass-api.de/api/interpreter?data=${Uri.encodeQueryComponent(query)}',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RoadSoS/1.0 Flutter Emergency App',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'] ?? [];
        debugPrint('[ApiService] Got ${elements.length} results for "$serviceType"');

        final List<Map<String, dynamic>> results = [];
        for (final e in elements) {
          // For ways/relations, use the 'center' coordinates
          double? eLat = e['lat'] ?? e['center']?['lat'];
          double? eLon = e['lon'] ?? e['center']?['lon'];
          if (eLat == null || eLon == null) continue;

          results.add(<String, dynamic>{
            'lat': (eLat as num).toDouble(),
            'lon': (eLon as num).toDouble(),
            'name': (e['tags']?['name'] ?? 'Unknown Location') as String,
            'type': serviceType,
            'phone': (e['tags']?['phone'] ??
                    e['tags']?['contact:phone'] ??
                    e['tags']?['contact:mobile'] ??
                    '') as String,
            'address': _buildAddress(e['tags']),
          });
        }

        // For trauma centres, filter out specialty hospitals that aren't trauma-related
        final filteredResults = serviceType.toLowerCase() == 'trauma centre'
            ? _filterTraumaCentres(results)
            : results;

        debugPrint('[ApiService] After filtering: ${filteredResults.length} results for "$serviceType"');

        // Cache results to SQLite for offline use
        await _cacheServices(filteredResults, serviceType);

        return filteredResults;
      } else {
        debugPrint('[ApiService] Overpass returned status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching from Overpass API: $e');
    }

    // Fallback: serve from SQLite cache when offline
    debugPrint('[ApiService] Falling back to cached data for "$serviceType"');
    return await _getCachedServices(serviceType);
  }

  /// Build Overpass query lines for each service type.
  /// Uses node + way to catch POIs mapped as points or areas.
  List<String> _buildQueryLines(
      String serviceType, double lat, double lon, double radius) {
    // Helper to generate both node and way queries for a filter
    List<String> _nw(String filter) => [
      'node$filter(around:$radius,$lat,$lon);',
      'way$filter(around:$radius,$lat,$lon);',
    ];

    switch (serviceType.toLowerCase()) {
      case 'hospital':
        return [
          ..._nw('["amenity"="hospital"]'),
          ..._nw('["amenity"="clinic"]'),
        ];
      case 'ambulance':
        return [
          ..._nw('["amenity"="hospital"]'),
          ..._nw('["emergency"="ambulance_station"]'),
        ];
      case 'police':
        return [
          ..._nw('["amenity"="police"]'),
        ];
      case 'towing':
        return [
          ..._nw('["shop"="car_repair"]'),
          ..._nw('["shop"="car"]'),
        ];
      case 'trauma centre':
        return [
          // Only hospitals explicitly tagged with emergency services
          ..._nw('["amenity"="hospital"]["emergency"="yes"]'),
          ..._nw('["amenity"="hospital"]["healthcare:speciality"~"emergency|trauma"]'),
          ..._nw('["emergency"="emergency_ward_entrance"]'),
        ];
      case 'puncture shop':
        return [
          ..._nw('["shop"="car_repair"]'),
          ..._nw('["shop"="tyres"]'),
          ..._nw('["shop"="bicycle"]'),
        ];
      default:
        return [
          ..._nw('["amenity"="hospital"]'),
        ];
    }
  }

  /// Filter out specialty hospitals that clearly don't handle road accident trauma.
  /// OSM's emergency=yes tag is too broad — many eye hospitals, dental clinics etc. have it.
  List<Map<String, dynamic>> _filterTraumaCentres(List<Map<String, dynamic>> results) {
    // Keywords that indicate a non-trauma specialty hospital
    const excludeKeywords = [
      'eye', 'ophthal', 'nethra', 'kanna', 'dental', 'dent',
      'skin', 'derma', 'cosmetic', 'beauty',
      'maternity', 'fertility', 'ivf', 'women', 'obstetric', 'gynae',
      'ayurved', 'homeo', 'siddha', 'unani', 'naturo',
      'veterinary', 'vet ', 'animal',
      'psychiatric', 'mental', 'rehab',
      'physiotherapy', 'physio',
      'lab', 'diagnostic', 'scan', 'x-ray', 'xray',
      'pharmacy', 'pharma', 'medical store', 'medicals',
    ];

    return results.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      if (name == 'unknown location') return false;
      for (final keyword in excludeKeywords) {
        if (name.contains(keyword)) return false;
      }
      return true;
    }).toList();
  }

  /// Build a human-readable address from OSM tags
  String _buildAddress(Map<String, dynamic>? tags) {
    if (tags == null) return '';
    final parts = <String>[];
    if (tags['addr:street'] != null) parts.add(tags['addr:street']);
    if (tags['addr:city'] != null) parts.add(tags['addr:city']);
    if (tags['addr:postcode'] != null) parts.add(tags['addr:postcode']);
    if (parts.isEmpty && tags['addr:full'] != null) return tags['addr:full'];
    return parts.join(', ');
  }

  /// Pre-download all service types within a radius for offline use
  Future<void> syncAllServicesForOffline(double lat, double lon,
      {double radiusMeters = 50000}) async {
    final types = [
      'hospital',
      'police',
      'towing',
      'ambulance',
      'trauma centre',
      'puncture shop'
    ];
    for (final type in types) {
      await fetchNearbyServices(lat, lon, type, radiusMeters: radiusMeters);
      // Small delay to avoid hammering the Overpass API
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _cacheServices(
      List<Map<String, dynamic>> services, String type) async {
    // Clear old cached data for this type before inserting fresh results
    await _dbService.clearServicesByType(type);
    for (final s in services) {
      final service = EmergencyService(
        id: '${s['lat']}_${s['lon']}_$type',
        name: s['name'] ?? 'Unknown',
        type: type,
        latitude: s['lat'],
        longitude: s['lon'],
        phoneNumber: s['phone'],
        address: s['address'],
      );
      await _dbService.insertService(service);
    }
  }

  Future<List<Map<String, dynamic>>> _getCachedServices(String type) async {
    final services = await _dbService.getServicesByType(type);
    return services
        .map((s) => <String, dynamic>{
              'lat': s.latitude,
              'lon': s.longitude,
              'name': s.name,
              'type': s.type,
              'phone': s.phoneNumber ?? '',
              'address': s.address ?? '',
            })
        .toList();
  }

  // Cerebras API for Chatbot
  Future<String> chatWithCerebras(String prompt,
      {List<Map<String, String>> history = const []}) async {
    final apiKey = dotenv.env['CEREBRAS_API_KEY'];
    if (apiKey == null || apiKey == 'your_cerebras_api_key_here') {
      return "Hello! I am your RoadSoS assistant. (Note: Cerebras API key is missing from the .env file! Please add it to enable AI responses.)";
    }

    final url = Uri.parse('https://api.cerebras.ai/v1/chat/completions');

    final List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content':
            'You are the intelligent emergency assistant for RoadSoS, an app designed to help users during road accidents. Help them with first aid, locating nearby services, or understanding app functionality. Be concise and empathetic.'
      },
      ...history,
      {'role': 'user', 'content': prompt}
    ];

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'llama3.1-8b',
          'messages': messages,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Sorry, I received an error from the AI server: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("Cerebras API Error: $e");
      return "Sorry, I couldn't connect to the AI service. Please check your internet connection.";
    }
  }
}
