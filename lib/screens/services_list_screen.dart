import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/sms_service.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesListScreen extends StatefulWidget {
  final String serviceType;
  const ServicesListScreen({Key? key, required this.serviceType}) : super(key: key);
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
  void initState() { super.initState(); _loadServices(); }

  Future<void> _loadServices() async {
    final pos = await _locService.getCurrentLocation();
    if (pos != null) {
      _userPosition = pos;
      final results = await _apiService.fetchNearbyServices(pos.latitude, pos.longitude, widget.serviceType, radiusMeters: 50000);
      for (final s in results) s['distance'] = _locService.calculateDistance(pos.latitude, pos.longitude, s['lat'], s['lon']);
      results.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      if (mounted) setState(() { _services = results; _isLoading = false; });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDistance(double meters) => meters < 1000 ? '${meters.toStringAsFixed(0)} m' : '${(meters / 1000).toStringAsFixed(1)} km';

  IconData _getServiceIcon() {
    switch (widget.serviceType.toLowerCase()) {
      case 'hospital': return Icons.local_hospital;
      case 'police': return Icons.local_police;
      case 'ambulance': return Icons.airport_shuttle;
      case 'towing': return Icons.car_repair;
      case 'trauma centre': return Icons.emergency;
      case 'puncture shop': return Icons.build;
      default: return Icons.place;
    }
  }

  Color _getServiceColor() {
    switch (widget.serviceType.toLowerCase()) {
      case 'hospital': return AppColors.primaryRed;
      case 'police': return AppColors.accentBlue;
      case 'ambulance': return AppColors.accentOrange;
      case 'towing': return AppColors.accentCyan;
      case 'trauma centre': return AppColors.accentPurple;
      case 'puncture shop': return AppColors.accentGreen;
      default: return AppColors.primaryRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getServiceColor();
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('Nearby ${widget.serviceType}s', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkSurface, foregroundColor: AppColors.textPrimary, elevation: 0,
      ),
      body: _isLoading
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: color),
              const SizedBox(height: 16),
              Text('Finding nearby services...', style: TextStyle(color: AppColors.textTertiary)),
            ]))
          : _services.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No ${widget.serviceType}s found', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Try with network connectivity', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
                ]))
              : Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: color.withOpacity(0.08), border: Border(bottom: BorderSide(color: color.withOpacity(0.15)))),
                    child: Text('${_services.length} ${widget.serviceType}s found nearby',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  Expanded(child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final s = _services[index];
                      final hasPhone = s['phone'] != null && (s['phone'] as String).isNotEmpty;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: AppDecorations.glassmorphism(opacity: 0.06, borderRadius: 14),
                        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                              child: Icon(_getServiceIcon(), color: color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s['name'] ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                              if (s['address'] != null && (s['address'] as String).isNotEmpty)
                                Padding(padding: const EdgeInsets.only(top: 3), child: Text(s['address'], style: TextStyle(fontSize: 12, color: AppColors.textTertiary), maxLines: 2, overflow: TextOverflow.ellipsis)),
                              if (hasPhone)
                                Padding(padding: const EdgeInsets.only(top: 3), child: Row(children: [
                                  Icon(Icons.phone, size: 13, color: AppColors.textTertiary),
                                  const SizedBox(width: 4),
                                  Text(s['phone'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ])),
                            ])),
                            if (s['distance'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                child: Text(_formatDistance(s['distance']), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                          ]),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            if (hasPhone) OutlinedButton.icon(
                              onPressed: () => _smsService.callNumber(s['phone']),
                              icon: const Icon(Icons.call, size: 16), label: const Text('Call'),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentGreen, side: BorderSide(color: AppColors.accentGreen.withOpacity(0.4)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                            if (hasPhone) const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${s['lat']},${s['lon']}');
                                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.directions, size: 16), label: const Text('Navigate'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue, foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                          ]),
                        ])),
                      );
                    },
                  )),
                ]),
    );
  }
}
