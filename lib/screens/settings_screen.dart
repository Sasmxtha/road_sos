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

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  // All supported languages: code → (nativeName, flag)
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

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'en';
    setState(() {
      _currentLanguage = _languages[lang]?['name'] ?? 'English';
    });
  }

  Future<void> _setLanguage(String langCode, String langName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    setState(() {
      _currentLanguage = langName;
    });
    if (mounted) {
      Navigator.pop(context); // close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language changed to $langName. Restart app to apply.')),
      );
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);

    final locService = LocationService();
    final apiService = ApiService();
    Position? pos = await locService.getCurrentLocation();

    if (pos != null) {
      await apiService.syncAllServicesForOffline(pos.latitude, pos.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully synced emergency services within 50km!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please enable GPS.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('General',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_currentLanguage),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Select Language'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: ListView(
                      shrinkWrap: true,
                      children: _languages.entries.map((entry) {
                        final code = entry.key;
                        final info = entry.value;
                        return ListTile(
                          leading: Text(info['flag']!, style: const TextStyle(fontSize: 24)),
                          title: Text('${info['native']} (${info['name']})'),
                          trailing: _currentLanguage == info['name']
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () => _setLanguage(code, info['name']!),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Emergency Settings',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Emergency Contacts'),
            subtitle: const Text('Manage your SOS contacts'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmergencyContactsScreen()));
            },
          ),
          ListTile(
            leading: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            title: const Text('Sync Offline Data'),
            subtitle: const Text('Download services within 50km'),
            enabled: !_isSyncing,
            onTap: _syncData,
          ),
        ],
      ),
    );
  }
}
