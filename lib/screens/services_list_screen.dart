import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/sms_service.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesListScreen extends StatefulWidget {
  final String serviceType;
  const ServicesListScreen({Key? key, required this.serviceType})
      : super(key: key);

  @override
  _ServicesListScreenState createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final _locService = LocationService();
  final _apiService = ApiService();
  final _smsService = SmsService();
  Position? _userPosition;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final pos = await _locService.getCurrentLocation();
    if (pos != null) {
      _userPosition = pos;
      // Use 50km radius to match the sync radius — ensures results are found
      final results = await _apiService.fetchNearbyServices(
          pos.latitude, pos.longitude, widget.serviceType,
          radiusMeters: 50000);

      // Calculate distance for each result and sort
      for (final s in results) {
        final dist = _locService.calculateDistance(
            pos.latitude, pos.longitude, s['lat'], s['lon']);
        s['distance'] = dist;
      }
      results.sort(
          (a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      if (mounted) {
        setState(() {
          _services = results;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  Future<void> _openDirections(double lat, double lon) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  IconData _getServiceIcon() {
    switch (widget.serviceType.toLowerCase()) {
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

  Color _getServiceColor() {
    switch (widget.serviceType.toLowerCase()) {
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
        return AppColors.primaryRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby ${widget.serviceType}s'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryRed),
                  SizedBox(height: 16),
                  Text('Finding nearby services...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No ${widget.serviceType}s found nearby',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try again when you have network connectivity',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Results count header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: _getServiceColor().withOpacity(0.08),
                      child: Text(
                        '${_services.length} ${widget.serviceType}s found nearby',
                        style: TextStyle(
                          color: _getServiceColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final s = _services[index];
                          final hasPhone = s['phone'] != null &&
                              (s['phone'] as String).isNotEmpty;
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            _getServiceColor().withOpacity(0.15),
                                        child: Icon(_getServiceIcon(),
                                            color: _getServiceColor()),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                            if (s['address'] != null &&
                                                (s['address'] as String)
                                                    .isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  s['address'],
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600]),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            // Show phone number inline
                                            if (hasPhone)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.phone,
                                                        size: 14,
                                                        color: Colors.grey[500]),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      s['phone'],
                                                      style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.grey[600]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (s['distance'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryRed
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _formatDistance(s['distance']),
                                            style: const TextStyle(
                                                color: AppColors.primaryRed,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Action buttons row: Call + Directions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (hasPhone)
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _smsService.callNumber(s['phone']),
                                          icon:
                                              const Icon(Icons.call, size: 18),
                                          label: const Text('Call'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green,
                                            side: const BorderSide(
                                                color: Colors.green),
                                          ),
                                        ),
                                      if (hasPhone) const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _openDirections(
                                            s['lat'], s['lon']),
                                        icon: const Icon(Icons.directions,
                                            size: 18),
                                        label: const Text('Directions'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
