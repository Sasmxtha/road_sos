import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'emergency_contacts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
            child: Text('General', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English (Default)'),
            onTap: () {
              // Placeholder for localization selector
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Select Language'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: const Text('English'), onTap: () => Navigator.pop(context)),
                      ListTile(title: const Text('Hindi'), onTap: () => Navigator.pop(context)),
                      ListTile(title: const Text('Tamil'), onTap: () => Navigator.pop(context)),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Emergency Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Emergency Contacts'),
            subtitle: const Text('Manage your SOS contacts'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Offline Data'),
            subtitle: const Text('Download services within 50km'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing latest emergency services database...')),
              );
            },
          ),
        ],
      ),
    );
  }
}
