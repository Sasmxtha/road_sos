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
  String _name = '', _contact = '', _aadhaar = '', _emName = '', _emContact = '';
  final _dbService = DatabaseService();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _dbService.saveUserProfile({'name': _name, 'contact': _contact, 'aadhaar': _aadhaar});
      await _dbService.insertContact(EmergencyContact(name: _emName, phoneNumber: _emContact));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSignedUp', true);
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter phone number';
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) cleaned = cleaned.substring(3);
    if (cleaned.startsWith('91') && cleaned.length == 12) cleaned = cleaned.substring(2);
    if (cleaned.length != 10) return 'Enter a valid 10-digit number';
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleaned)) return 'Must start with 6, 7, 8 or 9';
    return null;
  }

  String _cleanPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+91')) cleaned = cleaned.substring(3);
    if (cleaned.startsWith('91') && cleaned.length == 12) cleaned = cleaned.substring(2);
    return cleaned;
  }

  Widget _buildField(String label, Function(String?) onSave,
      {TextInputType type = TextInputType.text, String? Function(String?)? customValidator,
       int? maxLength, String? prefixText, String? hintText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: AppColors.textTertiary),
          filled: true, fillColor: AppColors.darkCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primaryRed, width: 1.5)),
          prefixText: prefixText, prefixStyle: TextStyle(color: AppColors.textSecondary),
          hintText: hintText, hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5)),
          counterText: '',
        ),
        keyboardType: type, maxLength: maxLength,
        validator: customValidator ?? (value) => (value == null || value.trim().isEmpty) ? 'Please enter $label' : null,
        onSaved: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppColors.sosGradient, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.emergency, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('RoadSoS', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                  Text('Emergency Setup', style: TextStyle(fontSize: 14, color: Colors.white70)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Complete your profile to enable\nemergency features.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 24),

            Row(children: [
              Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.accentBlue, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Personal Details', style: AppTextStyles.subheader),
            ]),
            const SizedBox(height: 8),
            _buildField('Full Name', (val) => _name = val!),
            _buildField('Your Contact Number', (val) => _contact = '+91${_cleanPhone(val!)}',
              type: TextInputType.phone, customValidator: _validatePhone, maxLength: 10, prefixText: '+91 ', hintText: '9876543210'),
            _buildField('Aadhaar Number', (val) => _aadhaar = val!,
              type: TextInputType.number, maxLength: 12, hintText: '1234 5678 9012',
              customValidator: (value) {
                if (value == null || value.trim().isEmpty) return 'Please enter Aadhaar';
                final cleaned = value.replaceAll(' ', '');
                if (cleaned.length != 12 || !RegExp(r'^[0-9]{12}$').hasMatch(cleaned)) return 'Must be 12 digits';
                return null;
              }),

            const SizedBox(height: 20),
            Row(children: [
              Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.accentGreen, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Emergency Contact', style: AppTextStyles.subheader),
            ]),
            const SizedBox(height: 4),
            Text('This contact receives SMS & WhatsApp SOS alerts.', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            _buildField('Contact Name', (val) => _emName = val!),
            _buildField('Contact Number', (val) => _emContact = '+91${_cleanPhone(val!)}',
              type: TextInputType.phone, customValidator: _validatePhone, maxLength: 10, prefixText: '+91 ', hintText: '9876543210'),

            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(gradient: AppColors.sosGradient, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primaryRed.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Complete Setup', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ])),
        ),
      ),
    );
  }
}
