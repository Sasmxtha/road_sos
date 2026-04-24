import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/accident_detection_service.dart';
import '../services/sms_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../models/emergency_contact.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';
import '../widgets/offline_banner.dart';
import 'map_screen.dart';
import 'settings_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isOffline = true; // defaulting to offline for demo
  final _smsService = SmsService();
  final _dbService = DatabaseService();
  final _locService = LocationService();
  Timer? _countdownTimer;
  int _countdownSeconds = 30;
  bool _popupShowing = false;

  @override
  void initState() {
    super.initState();
    // Simulate checking network
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isOffline = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccidentDetectionService>(context, listen: false).startMonitoring();
    });
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
    _countdownSeconds = 30;
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        if (_popupShowing) {
          Navigator.of(context).pop(); // trigger SOS
          _triggerSOS();
          service.resetDetection();
          _popupShowing = false;
        }
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateBuilder) {
          return AlertDialog(
            title: const Text('Accident Detected!', style: TextStyle(color: Colors.red)),
            content: Text('Calling SOS in $_countdownSeconds seconds...'),
            actions: [
              TextButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  service.resetDetection();
                  _popupShowing = false;
                  Navigator.of(context).pop();
                },
                child: const Text('I am OK', style: TextStyle(color: Colors.green)),
              ),
              ElevatedButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  service.resetDetection();
                  _popupShowing = false;
                  Navigator.of(context).pop();
                  _triggerSOS();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Send SOS Now', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      }
    );
  }

  Future<void> _triggerSOS() async {
    Position? pos = await _locService.getCurrentLocation();
    List<EmergencyContact> contacts = await _dbService.getContacts();
    
    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emergency contacts saved! Add some in Settings.')),
        );
      }
      return;
    }
    
    bool sent = await _smsService.sendSOS(contacts, pos);
    if (!sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulated sending SOS to contacts...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    }
  }

  Widget _buildQuickCard(String title, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapScreen(serviceFilter: title),
            ),
          );
        },
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
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
        title: const Text('RoadSoS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          OfflineBanner(isOffline: _isOffline),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tap to send instant alert\nto emergency contacts', textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  SosButton(onPressed: _triggerSOS),
                  const SizedBox(height: 60),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Quick Services nearby', style: AppTextStyles.subheader),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildQuickCard('Hospital', Icons.local_hospital, Colors.red),
                        _buildQuickCard('Police', Icons.local_police, Colors.blue),
                        _buildQuickCard('Ambulance', Icons.airport_shuttle, Colors.orange),
                        _buildQuickCard('Towing', Icons.car_repair, Colors.black54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryRed,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen()));
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
    super.dispose();
  }
}
