// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RoadSoS';

  @override
  String get sosButtonLabel => 'SOS';

  @override
  String get sosSubtext => 'Tap to send instant alert\nto emergency contacts';

  @override
  String get quickServicesTitle => 'Quick Services Nearby';

  @override
  String get hospitalLabel => 'Hospital';

  @override
  String get policeLabel => 'Police';

  @override
  String get ambulanceLabel => 'Ambulance';

  @override
  String get towingLabel => 'Towing';

  @override
  String get traumaLabel => 'Trauma';

  @override
  String get punctureLabel => 'Puncture';

  @override
  String get homeLabel => 'Home';

  @override
  String get mapLabel => 'Map';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get offlineBanner => 'Offline Mode - Using Cached Services';

  @override
  String get accidentDetected => 'Accident Detected!';

  @override
  String get accidentMessage =>
      'We detected a possible accident.\nSending SOS automatically in:';

  @override
  String get seconds => 'seconds';

  @override
  String get iAmOk => 'I am OK';

  @override
  String get sendSosNow => 'Send SOS Now';

  @override
  String get noContactsWarning =>
      'No emergency contacts saved! Add some in Settings.';

  @override
  String sosSent(Object count) {
    return 'SOS sent to $count contacts!';
  }

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get emergencyContactsSubtext =>
      'These contacts will receive an SMS with your location when you press SOS.';

  @override
  String get addContact => 'Add Emergency Contact';

  @override
  String get nameLabel => 'Name';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get maxContactsWarning =>
      'You can only save up to 3 emergency contacts.';

  @override
  String get settingsGeneral => 'General';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageDefault => 'English (Default)';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get emergencySettings => 'Emergency Settings';

  @override
  String get manageContacts => 'Manage your SOS contacts';

  @override
  String get syncOfflineData => 'Sync Offline Data';

  @override
  String get syncDescription => 'Download services within 50km';

  @override
  String get syncing => 'Syncing latest emergency services database...';

  @override
  String get setupTitle => 'RoadSoS Setup';

  @override
  String get welcomeTitle => 'Welcome to RoadSoS';

  @override
  String get welcomeSubtext =>
      'Please complete your profile to enable emergency features.';

  @override
  String get personalDetails => 'Personal Details';

  @override
  String get fullName => 'Full Name';

  @override
  String get yourContact => 'Your Contact Number';

  @override
  String get aadhaarNumber => 'Aadhaar Number';

  @override
  String get primaryEmergencyContact => 'Primary Emergency Contact';

  @override
  String get primaryContactSubtext =>
      'This contact will receive SMS alerts when you press SOS.';

  @override
  String get contactName => 'Contact Name';

  @override
  String get contactNumber => 'Contact Number';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get nearbyServicesMap => 'Nearby Services Map';

  @override
  String get chatbotTitle => 'RoadSoS AI Assistant';

  @override
  String get chatbotPlaceholder =>
      'Ask me about nearby hospitals,\nfirst aid, or emergency tips!';

  @override
  String get typeMessage => 'Type your message...';

  @override
  String get findingServices => 'Finding nearby services...';

  @override
  String noServicesFound(Object type) {
    return 'No ${type}s found nearby';
  }

  @override
  String get tryAgainOnline => 'Try again when you have network connectivity';

  @override
  String get call => 'Call';

  @override
  String get directions => 'Directions';

  @override
  String get tapForList => 'Tap a card for list view • Long press for map view';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get tamil => 'Tamil';
}
