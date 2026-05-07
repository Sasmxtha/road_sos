import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'emergency_contacts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentLanguage = 'English';
  bool _isSyncing = false;

  static const Map<String, Map<String, String>> _languages = {
    'en': {'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
    'hi': {'name': 'Hindi', 'native': 'हिंदी', 'flag': '🇮🇳'},
    'ta': {'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🇮🇳'},
    'te': {'name': 'Telugu', 'native': 'తెలుగు', 'flag': '🇮🇳'},
    'kn': {'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
    'ml': {'name': 'Malayalam', 'native': 'മലയാളം', 'flag': '🇮🇳'},
    'bn': {'name': 'Bengali', 'native': 'বাংলা', 'flag': '🇮🇳'},
    'mr': {'name': 'Marathi', 'native': 'मराठी', 'flag': '🇮🇳'},
    'gu': {'name': 'Gujarati', 'native': 'ગુજરાતી', 'flag': '🇮🇳'},
    'pa': {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
  };

  @override
  void initState() { super.initState(); _loadLanguage(); }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'en';
    setState(() => _currentLanguage = _languages[lang]?['name'] ?? 'English');
  }

  Future<void> _setLanguage(String langCode, String langName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    setState(() => _currentLanguage = langName);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Language changed to $langName. Restart app to apply.')));
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    final locService = LocationService();
    final apiService = ApiService();
    Position? pos = await locService.getCurrentLocation();
    if (pos != null) {
      await apiService.syncAllServicesForOffline(pos.latitude, pos.longitude);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synced emergency services within 50km!'), backgroundColor: AppColors.accentGreen));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not get location. Enable GPS.'), backgroundColor: AppColors.primaryRed));
    }
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: AppColors.darkSurface, foregroundColor: AppColors.textPrimary, elevation: 0),
      body: ListView(children: [
        _buildSection('General', [
          _buildTile(Icons.language, AppColors.accentBlue, 'Language', _currentLanguage, () {
            showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: AppColors.darkCard,
              title: const Text('Select Language', style: TextStyle(color: AppColors.textPrimary)),
              content: SizedBox(width: double.maxFinite, height: 400, child: ListView(
                children: _languages.entries.map((entry) => ListTile(
                  leading: Text(entry.value['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text('${entry.value['native']} (${entry.value['name']})', style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: _currentLanguage == entry.value['name'] ? const Icon(Icons.check_circle, color: AppColors.accentGreen) : null,
                  onTap: () => _setLanguage(entry.key, entry.value['name']!),
                )).toList(),
              )),
            ));
          }),
        ]),
        _buildSection('Emergency', [
          _buildTile(Icons.contact_phone, AppColors.accentGreen, 'Emergency Contacts', 'Manage SOS contacts', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
          }),
          _buildTile(
            _isSyncing ? Icons.hourglass_top : Icons.sync,
            AppColors.accentOrange,
            'Sync Offline Data',
            'Download services within 50km',
            _isSyncing ? null : _syncData,
          ),
        ]),
        _buildSection('About', [
          _buildTile(Icons.info_outline, AppColors.accentPurple, 'Version', '1.0.0', null),
        ]),
      ]),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(title.toUpperCase(), style: AppTextStyles.label),
      ),
      ...children,
    ]);
  }

  Widget _buildTile(IconData icon, Color color, String title, String subtitle, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Container(
        decoration: AppDecorations.glassmorphism(opacity: 0.05, borderRadius: 14),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          trailing: onTap != null ? Icon(Icons.chevron_right, color: AppColors.textTertiary) : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
