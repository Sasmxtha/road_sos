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

  Widget _buildTextField(String label, Function(String?) onSave, {TextInputType type = TextInputType.text}) {
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
        ),
        keyboardType: type,
        validator: (value) {
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
              _buildTextField('Your Contact Number', (val) => _contact = val!, type: TextInputType.phone),
              _buildTextField('Aadhaar Number', (val) => _aadhaar = val!, type: TextInputType.number),
              
              const SizedBox(height: 20),
              const Text('Primary Emergency Contact', style: AppTextStyles.subheader),
              const Text('This contact will receive SMS alerts when you press SOS.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              _buildTextField('Contact Name', (val) => _emName = val!),
              _buildTextField('Contact Number', (val) => _emContact = val!, type: TextInputType.phone),
              
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
