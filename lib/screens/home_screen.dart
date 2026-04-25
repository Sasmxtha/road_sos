import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/accident_detection_service.dart';
import '../services/sms_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../models/emergency_contact.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/sos_button.dart';
import '../widgets/offline_banner.dart';
import 'map_screen.dart';
import 'services_list_screen.dart';
import 'settings_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isOffline = true;
  final _smsService = SmsService();
  final _dbService = DatabaseService();
  final _locService = LocationService();
  final _apiService = ApiService();
  Timer? _countdownTimer;
  Timer? _connectivityTimer;
  bool _popupShowing = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Check connectivity every 30 seconds
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccidentDetectionService>(context, listen: false)
          .startMonitoring();
    });
  }

  Future<void> _checkConnectivity() async {
    final connected = await hasInternetConnection();
    if (mounted) {
      setState(() => _isOffline = !connected);

      // Auto-sync when online
      if (connected) {
        _syncOfflineData();
      }
    }
  }

  Future<void> _syncOfflineData() async {
    final pos = await _locService.getCurrentLocation();
    if (pos != null) {
      await _apiService.syncAllServicesForOffline(pos.latitude, pos.longitude);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accidentService = Provider.of<AccidentDetectionService>(context);
    if (accidentService.isAccidentDetected && !_popupShowing) {
      _showAccidentPopup(accidentService);
    }
  }

  void _showAccidentPopup(AccidentDetectionService service) {
    _popupShowing = true;
    int countdownSeconds = 30;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          // Start the countdown timer using the dialog's setState
          _countdownTimer?.cancel();
          _countdownTimer =
              Timer.periodic(const Duration(seconds: 1), (timer) {
            if (countdownSeconds > 0) {
              setDialogState(() {
                countdownSeconds--;
              });
            } else {
              timer.cancel();
              if (_popupShowing) {
                Navigator.of(dialogContext).pop();
                _triggerSOS();
                service.resetDetection();
                _popupShowing = false;
              }
            }
          });

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('Accident Detected!',
                    style: TextStyle(color: Colors.red)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We detected a possible accident.\nSending SOS automatically in:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '$countdownSeconds',
                  style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
                const Text('seconds',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  service.resetDetection();
                  _popupShowing = false;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('I am OK',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  service.resetDetection();
                  _popupShowing = false;
                  Navigator.of(dialogContext).pop();
                  _triggerSOS();
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Send SOS Now',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _triggerSOS() async {
    Position? pos = await _locService.getCurrentLocation();
    List<EmergencyContact> contacts = await _dbService.getContacts();

    if (contacts.isEmpty) {
      if (mounted) {
        showMessage(context,
            'No emergency contacts saved! Add some in Settings.',
            backgroundColor: Colors.red);
      }
      return;
    }

    // Send SMS to all emergency contacts
    bool sent = await _smsService.sendSOS(contacts, pos);
    if (mounted) {
      showMessage(
        context,
        sent
            ? 'SOS sent to ${contacts.length} contacts!'
            : 'Opening SMS app to send SOS...',
        backgroundColor: Colors.green,
      );
    }

    // Auto-call nearest hospital/ambulance
    if (pos != null) {
      final nearestHospital =
          await _dbService.getNearestService('hospital', pos.latitude, pos.longitude);
      if (nearestHospital != null &&
          nearestHospital.phoneNumber != null &&
          nearestHospital.phoneNumber!.isNotEmpty) {
        await _smsService.callNumber(nearestHospital.phoneNumber!);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const MapScreen()));
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    }
  }

  Widget _buildQuickCard(
      String title, IconData icon, Color color, String serviceType) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServicesListScreen(serviceType: serviceType),
            ),
          );
        },
        onLongPress: () {
          // Long press opens map view for that type
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapScreen(serviceFilter: serviceType),
            ),
          );
        },
        child: Container(
          width: 85,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoadSoS',
            style:
                TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Online/Offline indicator in app bar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              _isOffline ? Icons.cloud_off : Icons.cloud_done,
              color: _isOffline ? Colors.orange[200] : Colors.green[200],
              size: 22,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(isOffline: _isOffline),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Tap to send instant alert\nto emergency contacts',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    SosButton(onPressed: _triggerSOS),
                    const SizedBox(height: 40),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Quick Services Nearby',
                            style: AppTextStyles.subheader),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _buildQuickCard('Hospital', Icons.local_hospital,
                              Colors.red, 'hospital'),
                          _buildQuickCard('Police', Icons.local_police,
                              Colors.blue, 'police'),
                          _buildQuickCard('Ambulance', Icons.airport_shuttle,
                              Colors.orange, 'ambulance'),
                          _buildQuickCard('Towing', Icons.car_repair,
                              Colors.brown, 'towing'),
                          _buildQuickCard('Trauma', Icons.emergency,
                              Colors.deepPurple, 'trauma centre'),
                          _buildQuickCard('Puncture', Icons.build,
                              Colors.teal, 'puncture shop'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Tap a card for list view • Long press for map view',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryRed,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()));
        },
        backgroundColor: AppColors.primaryRed,
        elevation: 6,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _connectivityTimer?.cancel();
    // Stop accelerometer/GPS monitoring
    Provider.of<AccidentDetectionService>(context, listen: false)
        .stopMonitoring();
    super.dispose();
  }
}
