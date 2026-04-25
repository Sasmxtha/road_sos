import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/emergency_contact.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // User profile fields
  String _name = '';
  String _contact = '';
  String _aadhaar = '';
  
  // Emergency contact fields
  String _emName = '';
  String _emContact = '';

  final _dbService = DatabaseService();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Save User Profile
      await _dbService.saveUserProfile({
        'name': _name,
        'contact': _contact,
        'aadhaar': _aadhaar,
      });

      // Save Initial Emergency Contact
      await _dbService.insertContact(EmergencyContact(
        name: _emName,
        phoneNumber: _emContact,
      ));

      // Mark as signed up
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSignedUp', true);

      // Navigate to Home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  /// Validates Indian mobile numbers (10 digits starting with 6-9)
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter phone number';
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) cleaned = cleaned.substring(3);
    if (cleaned.startsWith('91') && cleaned.length == 12) cleaned = cleaned.substring(2);
    if (cleaned.length != 10) return 'Enter a valid 10-digit mobile number';
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8 or 9';
    }
    return null;
  }

  /// Cleans phone number to 10 digits
  String _cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) cleaned = cleaned.substring(3);
    if (cleaned.startsWith('91') && cleaned.length == 12) cleaned = cleaned.substring(2);
    return cleaned;
  }

  Widget _buildTextField(String label, Function(String?) onSave, 
      {TextInputType type = TextInputType.text, 
       String? Function(String?)? customValidator,
       int? maxLength,
       String? prefixText,
       String? hintText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
          prefixText: prefixText,
          hintText: hintText,
          counterText: '',
        ),
        keyboardType: type,
        maxLength: maxLength,
        validator: customValidator ?? (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        onSaved: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoadSoS Setup'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Welcome to RoadSoS', style: AppTextStyles.header),
              const SizedBox(height: 10),
              const Text('Please complete your profile to enable emergency features.', style: AppTextStyles.body),
              const SizedBox(height: 20),
              
              const Text('Personal Details', style: AppTextStyles.subheader),
              _buildTextField('Full Name', (val) => _name = val!),
              _buildTextField('Your Contact Number', 
                (val) => _contact = '+91${_cleanPhone(val!)}', 
                type: TextInputType.phone,
                customValidator: _validatePhone,
                maxLength: 10,
                prefixText: '+91 ',
                hintText: '9876543210',
              ),
              _buildTextField('Aadhaar Number', (val) => _aadhaar = val!, 
                type: TextInputType.number,
                maxLength: 12,
                hintText: '1234 5678 9012',
                customValidator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter Aadhaar number';
                  final cleaned = value.replaceAll(' ', '');
                  if (cleaned.length != 12 || !RegExp(r'^[0-9]{12}$').hasMatch(cleaned)) {
                    return 'Aadhaar must be a 12-digit number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              const Text('Primary Emergency Contact', style: AppTextStyles.subheader),
              const Text('This contact will receive SMS alerts when you press SOS.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildTextField('Contact Name', (val) => _emName = val!),
              _buildTextField('Contact Number', 
                (val) => _emContact = '+91${_cleanPhone(val!)}',
                type: TextInputType.phone,
                customValidator: _validatePhone,
                maxLength: 10,
                prefixText: '+91 ',
                hintText: '9876543210',
              ),
              
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Complete Setup', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
