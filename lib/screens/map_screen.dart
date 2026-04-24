import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class MapScreen extends StatefulWidget {
  final String? serviceFilter;
  const MapScreen({Key? key, this.serviceFilter}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _locService = LocationService();
  final _apiService = ApiService();
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _nearbyServices = [];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    Position? pos = await _locService.getCurrentLocation();
    if (pos != null) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
        if (widget.serviceFilter != null && widget.serviceFilter!.isNotEmpty) {
          _fetchServices(pos.latitude, pos.longitude, widget.serviceFilter!);
        }
      }
    }
  }

  Future<void> _fetchServices(double lat, double lon, String type) async {
    final results = await _apiService.fetchNearbyServices(lat, lon, type);
    if (mounted) {
      setState(() {
        _nearbyServices = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Services Map'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.roadsos',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                    ..._nearbyServices.map((s) {
                      return Marker(
                        point: LatLng(s['lat'], s['lon']),
                        width: 120,
                        height: 60,
                        child: Column(
                           children: [
                             Icon(
                               widget.serviceFilter?.toLowerCase() == 'police' ? Icons.local_police :
                               widget.serviceFilter?.toLowerCase() == 'towing' ? Icons.car_repair :
                               Icons.local_hospital,
                               color: widget.serviceFilter?.toLowerCase() == 'police' ? Colors.blue : Colors.red,
                               size: 30,
                             ),
                             Text(s['name'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.white70), overflow: TextOverflow.ellipsis),
                           ]
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
    );
  }
}
