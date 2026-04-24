import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';
import 'package:geolocator/geolocator.dart';

class SmsService {
  Future<bool> sendSOS(List<EmergencyContact> contacts, Position? position) async {
    if (contacts.isEmpty) return false;

    String locationLink = position != null 
        ? "https://maps.google.com/?q=${position.latitude},${position.longitude}"
        : "Unknown location";
        
    String message = "EMERGENCY: I may have had an accident. Please help me. My current location: $locationLink";
    
    // Combining phone numbers with comma (for Android) or semicolon (for iOS)
    // using Android default since this is the primary target
    String numbers = contacts.map((c) => c.phoneNumber).join(',');
    
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: numbers,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      return true;
    } else {
      print("Could not launch SMS intent.");
      return false;
    }
  }

  Future<void> callNumber(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }
}
