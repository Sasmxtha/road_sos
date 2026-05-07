import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);
  @override
  _EmergencyContactsScreenState createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<EmergencyContact> _contacts = [];
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() { super.initState(); _loadContacts(); }

  Future<void> _loadContacts() async {
    final contacts = await _dbService.getContacts();
    setState(() => _contacts = contacts);
  }

  String? _validatePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) cleaned = cleaned.substring(3);
    else if (cleaned.startsWith('91') && cleaned.length == 12) cleaned = cleaned.substring(2);
    if (cleaned.length != 10) return 'Enter a valid 10-digit mobile number';
    if (!RegExp(r'^[6-9]').hasMatch(cleaned)) return 'Must start with 6, 7, 8 or 9';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(cleaned)) return 'Only digits allowed';
    return null;
  }

  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) cleaned = cleaned.substring(3);
    else if (cleaned.startsWith('91') && cleaned.length == 12) cleaned = cleaned.substring(2);
    return cleaned;
  }

  void _addContact() async {
    if (_contacts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 3 emergency contacts allowed.')));
      return;
    }
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name.'))); return; }
    final err = _validatePhoneNumber(phone);
    if (err != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.primaryRed)); return; }
    await _dbService.insertContact(EmergencyContact(name: name, phoneNumber: '+91${_cleanPhoneNumber(phone)}'));
    _nameController.clear(); _phoneController.clear();
    _loadContacts();
    Navigator.pop(context);
  }

  void _showAddContactDialog() {
    _nameController.clear(); _phoneController.clear();
    showDialog(context: context, builder: (dialogContext) {
      String? localPhoneError;
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_add, color: AppColors.accentGreen, size: 22)),
            const SizedBox(width: 10),
            const Text('Add Contact', style: TextStyle(color: AppColors.textPrimary)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: _nameController, style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppColors.textTertiary),
                prefixIcon: Icon(Icons.person, color: AppColors.textTertiary),
                filled: true, fillColor: AppColors.darkBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: 'Mobile Number', labelStyle: TextStyle(color: AppColors.textTertiary),
                prefixIcon: Icon(Icons.phone, color: AppColors.textTertiary), prefixText: '+91 ',
                prefixStyle: TextStyle(color: AppColors.textSecondary), hintText: '9876543210',
                hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)), errorText: localPhoneError,
                filled: true, fillColor: AppColors.darkBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              keyboardType: TextInputType.phone, maxLength: 10,
              onChanged: (val) { final e = _validatePhoneNumber(val); setDialogState(() => localPhoneError = val.isEmpty ? null : e); }),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: TextStyle(color: AppColors.textTertiary))),
            ElevatedButton(onPressed: _addContact,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save')),
          ],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkSurface, foregroundColor: AppColors.textPrimary, elevation: 0),
      body: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.glassmorphism(opacity: 0.06, borderRadius: 14),
          child: Row(children: [
            Icon(Icons.info_outline, color: AppColors.accentBlue, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('These contacts receive SMS + WhatsApp with your GPS location when SOS is triggered.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(child: _contacts.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text('No contacts yet', style: TextStyle(color: AppColors.textTertiary, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Tap + to add an emergency contact', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ]))
          : ListView.builder(itemCount: _contacts.length, itemBuilder: (context, index) {
              final contact = _contacts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppDecorations.glassmorphism(opacity: 0.06, borderRadius: 14),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.accentBlue.withOpacity(0.2), AppColors.accentPurple.withOpacity(0.2)]),
                      borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                      style: TextStyle(color: AppColors.accentBlue, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                  title: Text(contact.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  subtitle: Text(contact.phoneNumber, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.primaryRed.withOpacity(0.7)),
                    onPressed: () async { if (contact.id != null) { await _dbService.deleteContact(contact.id!); _loadContacts(); } },
                  ),
                ),
              );
            }),
        ),
      ])),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: AppColors.accentGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
