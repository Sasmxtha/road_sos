import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../models/emergency_contact.dart';
import 'package:geolocator/geolocator.dart';

class SmsService {
  /// Reverse geocode coordinates to a human-readable address
  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'RoadSoS/1.0 Flutter Emergency App',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? '';
      }
    } catch (e) {
      debugPrint('Reverse geocode failed: $e');
    }
    return '';
  }

  /// Build the emergency message with coordinates and map links
  Future<String> _buildEmergencyMessage(Position? position) async {
    String locationInfo = "Unknown location";
    String googleMapsLink = "";
    String coordsText = "";

    if (position != null) {
      final lat = position.latitude;
      final lon = position.longitude;
      coordsText = "📍 Coordinates: $lat, $lon";
      googleMapsLink =
          "https://maps.google.com/?q=$lat,$lon";

      // Try to get readable address
      String address = await _reverseGeocode(lat, lon);
      if (address.isNotEmpty) {
        locationInfo = address;
      } else {
        locationInfo = "Lat: $lat, Lon: $lon";
      }
    }

    return "🚨 EMERGENCY SOS - RoadSoS 🚨\n\n"
        "I may have had a road accident and need immediate help!\n\n"
        "${position != null ? '📍 Address: $locationInfo\n\n' : ''}"
        "${coordsText.isNotEmpty ? '$coordsText\n\n' : ''}"
        "${googleMapsLink.isNotEmpty ? '🗺️ Google Maps: $googleMapsLink\n\n' : ''}"
        "Please send help immediately!";
  }

  /// Send SOS via SMS to all emergency contacts
  Future<bool> sendSOS(List<EmergencyContact> contacts, Position? position) async {
    if (contacts.isEmpty) return false;

    String message = await _buildEmergencyMessage(position);

    // Combining phone numbers with comma (for Android) or semicolon (for iOS)
    String numbers = contacts.map((c) => c.phoneNumber).join(',');

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: numbers,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      return true;
    } else {
      debugPrint("Could not launch SMS intent.");
      return false;
    }
  }

  /// Send SOS via WhatsApp to a specific contact
  Future<bool> sendWhatsAppSOS(
      EmergencyContact contact, Position? position) async {
    String message = await _buildEmergencyMessage(position);

    // Clean the phone number for WhatsApp (needs country code without +)
    String phone = contact.phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    // If number doesn't start with country code, prepend 91 (India)
    if (phone.length == 10) {
      phone = '91$phone';
    }

    final Uri whatsappUri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      debugPrint("WhatsApp launch failed: $e");
    }

    // Fallback: Try whatsapp:// scheme
    try {
      final Uri fallbackUri = Uri.parse(
          'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri);
        return true;
      }
    } catch (e) {
      debugPrint("WhatsApp fallback also failed: $e");
    }

    return false;
  }

  /// Send SOS via both SMS and WhatsApp
  Future<Map<String, bool>> sendSOSAll(
      List<EmergencyContact> contacts, Position? position) async {
    bool smsSent = await sendSOS(contacts, position);

    bool whatsappSent = false;
    if (contacts.isNotEmpty) {
      // Send WhatsApp to first contact
      whatsappSent = await sendWhatsAppSOS(contacts.first, position);
    }

    return {
      'sms': smsSent,
      'whatsapp': whatsappSent,
    };
  }

  Future<void> callNumber(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }
}
