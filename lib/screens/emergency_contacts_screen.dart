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
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _dbService.getContacts();
    setState(() {
      _contacts = contacts;
    });
  }

  void _addContact() async {
    if (_contacts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only save up to 3 emergency contacts.')),
      );
      return;
    }

    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      final newContact = EmergencyContact(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      await _dbService.insertContact(newContact);
      _nameController.clear();
      _phoneController.clear();
      _loadContacts();
      Navigator.pop(context);
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addContact,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'These contacts will receive an SMS with your location when you press SOS.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.lightGrey,
                        child: Icon(Icons.person, color: AppColors.darkGrey),
                      ),
                      title: Text(contact.name),
                      subtitle: Text(contact.phoneNumber),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          if (contact.id != null) {
                            await _dbService.deleteContact(contact.id!);
                            _loadContacts();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
