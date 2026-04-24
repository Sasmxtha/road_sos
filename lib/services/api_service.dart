import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Overpass API for OpenStreetMap POI fetching (Hospitals, Police, etc.)
  Future<List<Map<String, dynamic>>> fetchNearbyServices(double lat, double lon, String serviceType) async {
    String queryTags = '';
    
    switch (serviceType.toLowerCase()) {
      case 'hospital':
      case 'ambulance':
        queryTags = 'node["amenity"~"hospital|clinic"]';
        break;
      case 'police':
        queryTags = 'node["amenity"="police"]';
        break;
      case 'towing':
        queryTags = 'node["shop"="car_repair"]';
        break;
      default:
        queryTags = 'node["amenity"="hospital"]';
    }

    final String query = '''
      [out:json];
      (
        $queryTags(around:5000, $lat, $lon);
      );
      out 20; // limit to 20 results for performance
    ''';

    final Uri url = Uri.parse('https://overpass-api.de/api/interpreter');

    try {
      final response = await http.post(url, body: query);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'] ?? [];
        return elements.map((e) => {
          'lat': e['lat'],
          'lon': e['lon'],
          'name': e['tags']?['name'] ?? 'Unknown Location',
          'type': serviceType,
        }).toList();
      }
    } catch (e) {
      print("Error fetching from Overpass API: $e");
    }
    return []; // fallback empty list
  }

  // Cerebras API for Chatbot
  Future<String> chatWithCerebras(String prompt, {List<Map<String, String>> history = const []}) async {
    final apiKey = dotenv.env['CEREBRAS_API_KEY'];
    if (apiKey == null || apiKey == 'your_cerebras_api_key_here') {
      return "Hello! I am your RoadSoS assistant. (Note: Cerebras API key is missing from the .env file! Please add it to enable AI responses.)";
    }

    final url = Uri.parse('https://api.cerebras.ai/v1/chat/completions');
    
    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': 'You are the intelligent emergency assistant for RoadSoS, an app designed to help users during road accidents. Help them with first aid, locating nearby services, or understanding app functionality. Be concise and empathetic.'},
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
          'model': 'llama3.1-8b', // using a fast Cerebras model
          'messages': messages,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "Sorry, I received an error from the AI server: \${response.statusCode}";
      }
    } catch (e) {
      print("Cerebras API Error: $e");
      return "Sorry, I couldn't connect to the AI service. Please check your internet connection.";
    }
  }
}
