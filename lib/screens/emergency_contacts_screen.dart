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

  /// Validates Indian mobile numbers:
  /// - Must be 10 digits starting with 6, 7, 8, or 9
  /// - Optionally prefixed with +91 or 91
  String? _validatePhoneNumber(String phone) {
    // Remove all spaces, dashes, and parentheses
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Strip +91 or 91 prefix
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }

    // Must be exactly 10 digits
    if (cleaned.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }

    // Must start with 6, 7, 8, or 9
    if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8 or 9';
    }

    // Must be all digits
    if (!RegExp(r'^[0-9]{10}$').hasMatch(cleaned)) {
      return 'Phone number must contain only digits';
    }

    return null; // valid
  }

  /// Returns the cleaned 10-digit number
  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }
    return cleaned;
  }

  String? _phoneError;

  void _addContact() async {
    if (_contacts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only save up to 3 emergency contacts.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a contact name.')),
      );
      return;
    }

    final phoneValidation = _validatePhoneNumber(phone);
    if (phoneValidation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneValidation), backgroundColor: Colors.red),
      );
      return;
    }

    final cleanedPhone = _cleanPhoneNumber(phone);
    final newContact = EmergencyContact(
      name: name,
      phoneNumber: '+91$cleanedPhone',
    );
    await _dbService.insertContact(newContact);
    _nameController.clear();
    _phoneController.clear();
    _loadContacts();
    Navigator.pop(context);
  }

  void _showAddContactDialog() {
    _nameController.clear();
    _phoneController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {
        String? localPhoneError;
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Emergency Contact'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: '+91 ',
                    hintText: '9876543210',
                    errorText: localPhoneError,
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: (val) {
                    final err = _validatePhoneNumber(val);
                    setDialogState(() {
                      localPhoneError = val.isEmpty ? null : err;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
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
