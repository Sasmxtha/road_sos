import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isOffline = true;
  final _smsService = SmsService();
  final _dbService = DatabaseService();
  final _locService = LocationService();
  final _apiService = ApiService();
  Timer? _countdownTimer;
  Timer? _connectivityTimer;
  bool _popupShowing = false;

  // Live location info
  String _currentAddress = 'Fetching location...';
  Position? _lastPosition;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeController.forward();
    _checkConnectivity();
    _fetchCurrentAddress();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkConnectivity());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccidentDetectionService>(context, listen: false).startMonitoring();
    });
  }

  Future<void> _fetchCurrentAddress() async {
    final pos = await _locService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _lastPosition = pos);
      final address = await _locService.reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) setState(() => _currentAddress = address ?? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}');
    } else if (mounted) {
      setState(() => _currentAddress = 'Location unavailable');
    }
  }

  Future<void> _checkConnectivity() async {
    final connected = await hasInternetConnection();
    if (mounted) {
      setState(() => _isOffline = !connected);
      if (connected) _syncOfflineData();
    }
  }

  Future<void> _syncOfflineData() async {
    final pos = await _locService.getCurrentLocation();
    if (pos != null) await _apiService.syncAllServicesForOffline(pos.latitude, pos.longitude);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final accidentService = Provider.of<AccidentDetectionService>(context);
    if (accidentService.isAccidentDetected && !_popupShowing) _showAccidentPopup(accidentService);
  }

  void _showAccidentPopup(AccidentDetectionService service) {
    _popupShowing = true;
    int countdownSeconds = 30;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          _countdownTimer?.cancel();
          _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (countdownSeconds > 0) {
              setDialogState(() => countdownSeconds--);
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
            backgroundColor: AppColors.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.primaryRed, size: 28),
              ),
              const SizedBox(width: 12),
              const Text('Accident Detected!', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Possible accident detected.\nSending SOS automatically in:', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryRed, width: 3)),
                child: Center(child: Text('$countdownSeconds', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primaryRed))),
              ),
              const SizedBox(height: 8),
              const Text('seconds', style: TextStyle(color: AppColors.textTertiary)),
            ]),
            actions: [
              TextButton(
                onPressed: () { _countdownTimer?.cancel(); service.resetDetection(); _popupShowing = false; Navigator.of(dialogContext).pop(); },
                child: const Text('I\'m OK', style: TextStyle(color: AppColors.accentGreen, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () { _countdownTimer?.cancel(); service.resetDetection(); _popupShowing = false; Navigator.of(dialogContext).pop(); _triggerSOS(); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Send SOS Now', style: TextStyle(color: Colors.white, fontSize: 16)),
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
      if (mounted) showMessage(context, 'No emergency contacts! Add some in Settings.', backgroundColor: AppColors.primaryRed);
      return;
    }
    bool sent = await _smsService.sendSOS(contacts, pos);
    if (mounted) showMessage(context, sent ? 'SOS sent to ${contacts.length} contacts!' : 'Opening SMS to send SOS...', backgroundColor: AppColors.accentGreen);
    if (pos != null) {
      final nearest = await _dbService.getNearestService('hospital', pos.latitude, pos.longitude);
      if (nearest != null && nearest.phoneNumber != null && nearest.phoneNumber!.isNotEmpty) await _smsService.callNumber(nearest.phoneNumber!);
    }
  }

  Future<void> _triggerWhatsAppSOS() async {
    Position? pos = await _locService.getCurrentLocation();
    List<EmergencyContact> contacts = await _dbService.getContacts();
    if (contacts.isEmpty) {
      if (mounted) showMessage(context, 'No emergency contacts! Add some in Settings.', backgroundColor: AppColors.primaryRed);
      return;
    }
    bool sent = await _smsService.sendWhatsAppSOS(contacts.first, pos);
    if (mounted) showMessage(context, sent ? 'WhatsApp SOS opened!' : 'Could not open WhatsApp', backgroundColor: sent ? AppColors.accentGreen : AppColors.primaryRed);
  }

  void _onItemTapped(int index) {
    if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
    else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar
            _buildAppBar(),
            OfflineBanner(isOffline: _isOffline),
            Expanded(
              child: FadeTransition(
                opacity: _fadeController,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildLocationCard(),
                      const SizedBox(height: 16),
                      _buildSOSSection(),
                      const SizedBox(height: 24),
                      _buildServicesSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
        backgroundColor: AppColors.accentPurple,
        elevation: 8,
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: AppColors.sosGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.emergency, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('RoadSoS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (_isOffline ? AppColors.accentOrange : AppColors.accentGreen).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _isOffline ? AppColors.accentOrange : AppColors.accentGreen)),
              const SizedBox(width: 6),
              Text(_isOffline ? 'Offline' : 'Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _isOffline ? AppColors.accentOrange : AppColors.accentGreen)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecorations.glassmorphism(opacity: 0.06, borderRadius: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.accentBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.my_location, color: AppColors.accentBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CURRENT LOCATION', style: AppTextStyles.label),
                const SizedBox(height: 3),
                Text(_currentAddress, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textTertiary, size: 20),
              onPressed: _fetchCurrentAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSSection() {
    return Column(
      children: [
        Text('Emergency? Tap the button below', style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
        const SizedBox(height: 16),
        SosButton(onPressed: _triggerSOS, onWhatsAppPressed: _triggerWhatsAppSOS),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Nearby Services', style: AppTextStyles.subheader),
          ]),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          physics: const BouncingScrollPhysics(),
          child: Row(children: [
            _buildServiceTile('Hospital', Icons.local_hospital, AppColors.primaryRed, 'hospital'),
            _buildServiceTile('Police', Icons.local_police, AppColors.accentBlue, 'police'),
            _buildServiceTile('Ambulance', Icons.airport_shuttle, AppColors.accentOrange, 'ambulance'),
            _buildServiceTile('Towing', Icons.car_repair, AppColors.accentCyan, 'towing'),
            _buildServiceTile('Trauma', Icons.emergency, AppColors.accentPurple, 'trauma centre'),
            _buildServiceTile('Puncture', Icons.build, AppColors.accentGreen, 'puncture shop'),
          ]),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Tap → list view  •  Long press → map view', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ),
      ],
    );
  }

  Widget _buildServiceTile(String title, IconData icon, Color color, String serviceType) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServicesListScreen(serviceType: serviceType))),
        onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(serviceFilter: serviceType))),
        child: Container(
          width: 90, height: 100,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.textTertiary,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _connectivityTimer?.cancel();
    _fadeController.dispose();
    Provider.of<AccidentDetectionService>(context, listen: false).stopMonitoring();
    super.dispose();
  }
}
