import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/sms_service.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final String? serviceFilter;
  const MapScreen({Key? key, this.serviceFilter}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _locService = LocationService();
  final _apiService = ApiService();
  final _smsService = SmsService();
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _nearbyServices = [];
  bool _isLoading = true;

  // Which types are visible (toggle filters)
  final Map<String, bool> _visibleTypes = {
    'hospital': true,
    'police': true,
    'ambulance': true,
    'towing': true,
    'trauma centre': true,
    'puncture shop': true,
  };

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
          // Single type from long-press
          await _fetchServices(pos.latitude, pos.longitude, widget.serviceFilter!);
        } else {
          // Load ALL service types for the general map view
          await _fetchAllServices(pos.latitude, pos.longitude);
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchServices(double lat, double lon, String type) async {
    final results = await _apiService.fetchNearbyServices(lat, lon, type, radiusMeters: 50000);
    // Tag each result with its type
    for (final r in results) {
      r['type'] = type;
    }
    if (mounted) {
      setState(() {
        _nearbyServices.addAll(results);
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllServices(double lat, double lon) async {
    final types = ['hospital', 'police', 'ambulance', 'towing', 'trauma centre', 'puncture shop'];
    List<Map<String, dynamic>> allResults = [];

    for (final type in types) {
      final results = await _apiService.fetchNearbyServices(lat, lon, type, radiusMeters: 50000);
      for (final r in results) {
        r['type'] = type;
      }
      allResults.addAll(results);

      // Update incrementally so markers appear as they load
      if (mounted) {
        setState(() {
          _nearbyServices = List.from(allResults);
        });
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'ambulance':
        return Icons.airport_shuttle;
      case 'towing':
        return Icons.car_repair;
      case 'trauma centre':
        return Icons.emergency;
      case 'puncture shop':
        return Icons.build;
      default:
        return Icons.place;
    }
  }

  Color _getColorForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'ambulance':
        return Colors.orange;
      case 'towing':
        return Colors.brown;
      case 'trauma centre':
        return Colors.deepPurple;
      case 'puncture shop':
        return Colors.teal;
      default:
        return Colors.red;
    }
  }

  void _showServiceDetail(Map<String, dynamic> service) {
    final hasPhone = service['phone'] != null && (service['phone'] as String).isNotEmpty;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getColorForType(service['type']).withOpacity(0.15),
                  child: Icon(_getIconForType(service['type']),
                      color: _getColorForType(service['type'])),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service['name'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text((service['type'] as String? ?? '').toUpperCase(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500],
                              fontWeight: FontWeight.w600, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
            if (hasPhone) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(service['phone'], style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                ],
              ),
            ],
            if (service['address'] != null && (service['address'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(service['address'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (hasPhone)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _smsService.callNumber(service['phone']),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (hasPhone) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${service['lat']},${service['lon']}',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // User location
    if (_currentPosition != null) {
      markers.add(Marker(
        point: _currentPosition!,
        width: 50,
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
        ),
      ));
    }

    // Service markers (filtered by visibility toggles)
    for (final s in _nearbyServices) {
      final sType = s['type'] as String? ?? '';
      if (!(_visibleTypes[sType.toLowerCase()] ?? true)) continue;

      markers.add(Marker(
        point: LatLng(s['lat'], s['lon']),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showServiceDetail(s),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getColorForType(sType).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              _getIconForType(sType),
              color: _getColorForType(sType),
              size: 20,
            ),
          ),
        ),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final filterType = widget.serviceFilter;
    final showFilters = filterType == null; // Show filter chips only on general map

    return Scaffold(
      appBar: AppBar(
        title: Text(filterType != null
            ? 'Nearby ${filterType}s'
            : 'Nearby Services Map'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _currentPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryRed),
                  const SizedBox(height: 16),
                  Text(
                    _isLoading
                        ? 'Getting location & services...'
                        : 'Could not get location',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.roadsos',
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                // Filter chips (only on general map view)
                if (showFilters)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _visibleTypes.entries.map((entry) {
                          final type = entry.key;
                          final visible = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              avatar: Icon(
                                _getIconForType(type),
                                size: 16,
                                color: visible
                                    ? Colors.white
                                    : _getColorForType(type),
                              ),
                              label: Text(
                                type[0].toUpperCase() + type.substring(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: visible ? Colors.white : Colors.black87,
                                ),
                              ),
                              selected: visible,
                              selectedColor: _getColorForType(type),
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.white,
                              elevation: 2,
                              onSelected: (val) {
                                setState(() {
                                  _visibleTypes[type] = val;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Results count badge
                Positioned(
                  bottom: 16,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      _isLoading
                          ? 'Loading services...'
                          : '${_nearbyServices.where((s) => _visibleTypes[s['type']?.toLowerCase() ?? ''] ?? true).length} services shown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ),
                ),

                // Loading spinner
                if (_isLoading)
                  Positioned(
                    bottom: 16,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.primaryRed, strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
