import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Get current location with best possible accuracy
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    } 

    try {
      // Try best accuracy first
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[LocationService] Best accuracy failed, falling back to high: $e');
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 15));
      } catch (e2) {
        debugPrint('[LocationService] High accuracy also failed: $e2');
        // Last resort — medium accuracy
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
        } catch (e3) {
          debugPrint('[LocationService] All accuracy levels failed: $e3');
          return null;
        }
      }
    }
  }

  /// Get a stream of position updates for real-time tracking
  Stream<Position> getPositionStream({
    int distanceFilter = 5,
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Reverse geocode coordinates to a human-readable address
  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1&zoom=18');
      final response = await http.get(url, headers: {
        'User-Agent': 'RoadSoS/1.0 Flutter Emergency App',
      }).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
    } catch (e) {
      debugPrint('[LocationService] Reverse geocode failed: $e');
    }
    return null;
  }

  /// Get structured address details
  Future<Map<String, String>?> getAddressDetails(double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'RoadSoS/1.0 Flutter Emergency App',
      }).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          return {
            'road': addr['road'] ?? addr['pedestrian'] ?? '',
            'suburb': addr['suburb'] ?? addr['neighbourhood'] ?? '',
            'city': addr['city'] ?? addr['town'] ?? addr['village'] ?? '',
            'state': addr['state'] ?? '',
            'postcode': addr['postcode'] ?? '',
            'country': addr['country'] ?? '',
            'display': data['display_name'] ?? '',
          };
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Address details failed: $e');
    }
    return null;
  }

  double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
  }
}
