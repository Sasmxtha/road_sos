// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'RoadSoS';

  @override
  String get sosButtonLabel => 'SOS';

  @override
  String get sosSubtext =>
      'அவசரத் தொடர்புகளுக்கு உடனடி எச்சரிக்கை அனுப்ப தட்டவும்';

  @override
  String get quickServicesTitle => 'அருகிலுள்ள சேவைகள்';

  @override
  String get hospitalLabel => 'மருத்துவமனை';

  @override
  String get policeLabel => 'காவல்';

  @override
  String get ambulanceLabel => 'ஆம்புலன்ஸ்';

  @override
  String get towingLabel => 'இழுவை';

  @override
  String get traumaLabel => 'அதிர்ச்சி';

  @override
  String get punctureLabel => 'பஞ்சர்';

  @override
  String get homeLabel => 'முகப்பு';

  @override
  String get mapLabel => 'வரைபடம்';

  @override
  String get settingsLabel => 'அமைப்புகள்';

  @override
  String get offlineBanner => 'ஆஃப்லைன் பயன்முறை - சேமிக்கப்பட்ட சேவைகள்';

  @override
  String get accidentDetected => 'விபத்து கண்டறியப்பட்டது!';

  @override
  String get accidentMessage =>
      'சாத்தியமான விபத்தை கண்டறிந்தோம்.\nSOS தானாக அனுப்பப்படுகிறது:';

  @override
  String get seconds => 'வினாடிகள்';

  @override
  String get iAmOk => 'நான் நலம்';

  @override
  String get sendSosNow => 'இப்போது SOS அனுப்பு';

  @override
  String get noContactsWarning =>
      'அவசரத் தொடர்புகள் சேமிக்கப்படவில்லை! அமைப்புகளில் சேர்க்கவும்.';

  @override
  String sosSent(Object count) {
    return '$count தொடர்புகளுக்கு SOS அனுப்பப்பட்டது!';
  }

  @override
  String get emergencyContacts => 'அவசரத் தொடர்புகள்';

  @override
  String get emergencyContactsSubtext =>
      'நீங்கள் SOS அழுத்தும்போது இந்த தொடர்புகளுக்கு உங்கள் இருப்பிடத்துடன் SMS வரும்.';

  @override
  String get addContact => 'அவசரத் தொடர்பு சேர்';

  @override
  String get nameLabel => 'பெயர்';

  @override
  String get phoneLabel => 'தொலைபேசி எண்';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get save => 'சேமி';

  @override
  String get maxContactsWarning =>
      'நீங்கள் அதிகபட்சம் 3 அவசரத் தொடர்புகளை மட்டுமே சேமிக்க முடியும்.';

  @override
  String get settingsGeneral => 'பொதுவான';

  @override
  String get languageLabel => 'மொழி';

  @override
  String get languageDefault => 'ஆங்கிலம் (இயல்புநிலை)';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get emergencySettings => 'அவசர அமைப்புகள்';

  @override
  String get manageContacts => 'உங்கள் SOS தொடர்புகளை நிர்வகிக்கவும்';

  @override
  String get syncOfflineData => 'ஆஃப்லைன் தரவை ஒத்திசை';

  @override
  String get syncDescription => '50 கி.மீ சுற்றளவில் சேவைகளைப் பதிவிறக்கு';

  @override
  String get syncing => 'சமீபத்திய அவசர சேவைகள் தரவுத்தளத்தை ஒத்திசைக்கிறது...';

  @override
  String get setupTitle => 'RoadSoS அமைப்பு';

  @override
  String get welcomeTitle => 'RoadSoS-க்கு வரவேற்கிறோம்';

  @override
  String get welcomeSubtext =>
      'அவசர அம்சங்களை இயக்க உங்கள் சுயவிவரத்தை நிறைவு செய்யவும்.';

  @override
  String get personalDetails => 'தனிப்பட்ட விவரங்கள்';

  @override
  String get fullName => 'முழு பெயர்';

  @override
  String get yourContact => 'உங்கள் தொடர்பு எண்';

  @override
  String get aadhaarNumber => 'ஆதார் எண்';

  @override
  String get primaryEmergencyContact => 'முதன்மை அவசரத் தொடர்பு';

  @override
  String get primaryContactSubtext =>
      'SOS அழுத்தும்போது இந்த தொடர்புக்கு SMS எச்சரிக்கை வரும்.';

  @override
  String get contactName => 'தொடர்பு பெயர்';

  @override
  String get contactNumber => 'தொடர்பு எண்';

  @override
  String get completeSetup => 'அமைப்பை நிறைவு செய்';

  @override
  String get nearbyServicesMap => 'அருகிலுள்ள சேவைகள் வரைபடம்';

  @override
  String get chatbotTitle => 'RoadSoS AI உதவியாளர்';

  @override
  String get chatbotPlaceholder =>
      'அருகிலுள்ள மருத்துவமனைகள், முதலுதவி அல்லது அவசர குறிப்புகள் பற்றி கேளுங்கள்!';

  @override
  String get typeMessage => 'உங்கள் செய்தியை உள்ளிடுக...';

  @override
  String get findingServices => 'அருகிலுள்ள சேவைகளைத் தேடுகிறது...';

  @override
  String noServicesFound(Object type) {
    return 'அருகில் $type எதுவும் கிடைக்கவில்லை';
  }

  @override
  String get tryAgainOnline =>
      'நெட்வொர்க் இணைப்பு இருக்கும்போது மீண்டும் முயற்சிக்கவும்';

  @override
  String get call => 'அழை';

  @override
  String get directions => 'வழிகாட்டி';

  @override
  String get tapForList =>
      'பட்டியலுக்கு தட்டவும் • வரைபடத்திற்கு நீண்டது அழுத்தவும்';

  @override
  String get english => 'ஆங்கிலம்';

  @override
  String get hindi => 'இந்தி';

  @override
  String get tamil => 'தமிழ்';
}
