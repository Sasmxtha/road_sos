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
  int _selectedMapStyle = 0;

  final Map<String, bool> _visibleTypes = {
    'hospital': true, 'police': true, 'ambulance': true,
    'towing': true, 'trauma centre': true, 'puncture shop': true,
  };

  // Map tile sources
  static const List<Map<String, String>> _mapStyles = [
    {'name': 'Default', 'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'},
    {'name': 'Topo', 'url': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png'},
    {'name': 'Humanitarian', 'url': 'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'},
  ];

  @override
  void initState() { super.initState(); _fetchLocation(); }

  Future<void> _fetchLocation() async {
    Position? pos = await _locService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
      if (widget.serviceFilter != null && widget.serviceFilter!.isNotEmpty) {
        await _fetchServices(pos.latitude, pos.longitude, widget.serviceFilter!);
      } else {
        await _fetchAllServices(pos.latitude, pos.longitude);
      }
    } else if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchServices(double lat, double lon, String type) async {
    final results = await _apiService.fetchNearbyServices(lat, lon, type, radiusMeters: 50000);
    for (final r in results) r['type'] = type;
    if (mounted) setState(() { _nearbyServices.addAll(results); _isLoading = false; });
  }

  Future<void> _fetchAllServices(double lat, double lon) async {
    final types = ['hospital', 'police', 'ambulance', 'towing', 'trauma centre', 'puncture shop'];
    List<Map<String, dynamic>> allResults = [];
    for (final type in types) {
      final results = await _apiService.fetchNearbyServices(lat, lon, type, radiusMeters: 50000);
      for (final r in results) r['type'] = type;
      allResults.addAll(results);
      if (mounted) setState(() => _nearbyServices = List.from(allResults));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'hospital': return Icons.local_hospital;
      case 'police': return Icons.local_police;
      case 'ambulance': return Icons.airport_shuttle;
      case 'towing': return Icons.car_repair;
      case 'trauma centre': return Icons.emergency;
      case 'puncture shop': return Icons.build;
      default: return Icons.place;
    }
  }

  Color _getColorForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'hospital': return AppColors.primaryRed;
      case 'police': return AppColors.accentBlue;
      case 'ambulance': return AppColors.accentOrange;
      case 'towing': return AppColors.accentCyan;
      case 'trauma centre': return AppColors.accentPurple;
      case 'puncture shop': return AppColors.accentGreen;
      default: return AppColors.primaryRed;
    }
  }

  void _showServiceDetail(Map<String, dynamic> service) {
    final hasPhone = service['phone'] != null && (service['phone'] as String).isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(
              backgroundColor: _getColorForType(service['type']).withOpacity(0.15),
              child: Icon(_getIconForType(service['type']), color: _getColorForType(service['type'])),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(service['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text((service['type'] as String? ?? '').toUpperCase(), style: TextStyle(fontSize: 11, color: _getColorForType(service['type']), fontWeight: FontWeight.w700, letterSpacing: 1)),
            ])),
          ]),
          if (hasPhone) ...[const SizedBox(height: 12), Row(children: [Icon(Icons.phone, size: 16, color: AppColors.textTertiary), const SizedBox(width: 8), Text(service['phone'], style: TextStyle(fontSize: 15, color: AppColors.textSecondary))])],
          if (service['address'] != null && (service['address'] as String).isNotEmpty) ...[const SizedBox(height: 8), Row(children: [Icon(Icons.location_on, size: 16, color: AppColors.textTertiary), const SizedBox(width: 8), Expanded(child: Text(service['address'], style: TextStyle(fontSize: 14, color: AppColors.textTertiary)))])],
          const SizedBox(height: 20),
          Row(children: [
            if (hasPhone) Expanded(child: OutlinedButton.icon(
              onPressed: () => _smsService.callNumber(service['phone']),
              icon: const Icon(Icons.call), label: const Text('Call'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentGreen, side: BorderSide(color: AppColors.accentGreen.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            if (hasPhone) const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${service['lat']},${service['lon']}');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.directions), label: const Text('Navigate'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          ]),
        ]),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (_currentPosition != null) {
      markers.add(Marker(point: _currentPosition!, width: 50, height: 50, child: Container(
        decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: AppColors.accentBlue, width: 2)),
        child: const Icon(Icons.my_location, color: AppColors.accentBlue, size: 24),
      )));
    }
    for (final s in _nearbyServices) {
      final sType = s['type'] as String? ?? '';
      if (!(_visibleTypes[sType.toLowerCase()] ?? true)) continue;
      markers.add(Marker(point: LatLng(s['lat'], s['lon']), width: 40, height: 40, child: GestureDetector(
        onTap: () => _showServiceDetail(s),
        child: Container(
          decoration: BoxDecoration(color: _getColorForType(sType), shape: BoxShape.circle, boxShadow: [BoxShadow(color: _getColorForType(sType).withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]),
          child: Icon(_getIconForType(sType), color: Colors.white, size: 18),
        ),
      )));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final filterType = widget.serviceFilter;
    final showFilters = filterType == null;
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(filterType != null ? 'Nearby ${filterType}s' : 'Services Map', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          // Map style switcher
          PopupMenuButton<int>(
            icon: const Icon(Icons.layers_rounded, color: AppColors.textSecondary),
            color: AppColors.darkCard,
            onSelected: (val) => setState(() => _selectedMapStyle = val),
            itemBuilder: (_) => _mapStyles.asMap().entries.map((e) => PopupMenuItem(value: e.key,
              child: Row(children: [
                Icon(e.key == _selectedMapStyle ? Icons.check_circle : Icons.circle_outlined, color: e.key == _selectedMapStyle ? AppColors.accentBlue : AppColors.textTertiary, size: 18),
                const SizedBox(width: 8),
                Text(e.value['name']!, style: TextStyle(color: AppColors.textPrimary)),
              ]),
            )).toList(),
          ),
        ],
      ),
      body: _currentPosition == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(color: AppColors.primaryRed),
              const SizedBox(height: 16),
              Text(_isLoading ? 'Getting location & services...' : 'Could not get location', style: const TextStyle(color: AppColors.textTertiary)),
            ]))
          : Stack(children: [
              FlutterMap(
                options: MapOptions(initialCenter: _currentPosition!, initialZoom: 12.0),
                children: [
                  TileLayer(urlTemplate: _mapStyles[_selectedMapStyle]['url']!, userAgentPackageName: 'com.example.roadsos'),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
              if (showFilters) Positioned(top: 8, left: 8, right: 8, child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _visibleTypes.entries.map((entry) {
                  final type = entry.key; final visible = entry.value;
                  return Padding(padding: const EdgeInsets.only(right: 6), child: FilterChip(
                    avatar: Icon(_getIconForType(type), size: 16, color: visible ? Colors.white : _getColorForType(type)),
                    label: Text(type[0].toUpperCase() + type.substring(1), style: TextStyle(fontSize: 12, color: visible ? Colors.white : AppColors.textPrimary)),
                    selected: visible, selectedColor: _getColorForType(type), checkmarkColor: Colors.white,
                    backgroundColor: AppColors.darkCard, elevation: 2, side: BorderSide(color: _getColorForType(type).withOpacity(0.3)),
                    onSelected: (val) => setState(() => _visibleTypes[type] = val),
                  ));
                }).toList()),
              )),
              Positioned(bottom: 16, left: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 6)]),
                child: Text(
                  _isLoading ? 'Loading...' : '${_nearbyServices.where((s) => _visibleTypes[s['type']?.toLowerCase() ?? ''] ?? true).length} services',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
              )),
              if (_isLoading) Positioned(bottom: 16, right: 12, child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.darkCard, shape: BoxShape.circle, boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primaryRed, strokeWidth: 2)),
              )),
            ]),
    );
  }
}
