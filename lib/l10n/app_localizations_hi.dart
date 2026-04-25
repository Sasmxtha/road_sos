// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'RoadSoS';

  @override
  String get sosButtonLabel => 'SOS';

  @override
  String get sosSubtext =>
      'आपातकालीन संपर्कों को तत्काल अलर्ट भेजने के लिए टैप करें';

  @override
  String get quickServicesTitle => 'आस-पास की सेवाएं';

  @override
  String get hospitalLabel => 'अस्पताल';

  @override
  String get policeLabel => 'पुलिस';

  @override
  String get ambulanceLabel => 'एम्बुलेंस';

  @override
  String get towingLabel => 'टोइंग';

  @override
  String get traumaLabel => 'ट्रॉमा';

  @override
  String get punctureLabel => 'पंक्चर';

  @override
  String get homeLabel => 'होम';

  @override
  String get mapLabel => 'मानचित्र';

  @override
  String get settingsLabel => 'सेटिंग्स';

  @override
  String get offlineBanner => 'ऑफ़लाइन मोड - कैश्ड सेवाओं का उपयोग';

  @override
  String get accidentDetected => 'दुर्घटना का पता चला!';

  @override
  String get accidentMessage =>
      'हमने एक संभावित दुर्घटना का पता लगाया।\nSTOS अपने आप भेजी जा रही है:';

  @override
  String get seconds => 'सेकंड';

  @override
  String get iAmOk => 'मैं ठीक हूं';

  @override
  String get sendSosNow => 'अभी SOS भेजें';

  @override
  String get noContactsWarning =>
      'कोई आपातकालीन संपर्क नहीं! सेटिंग्स में जोड़ें।';

  @override
  String sosSent(Object count) {
    return '$count संपर्कों को SOS भेजा गया!';
  }

  @override
  String get emergencyContacts => 'आपातकालीन संपर्क';

  @override
  String get emergencyContactsSubtext =>
      'SOS दबाने पर इन संपर्कों को आपके स्थान के साथ SMS प्राप्त होगा।';

  @override
  String get addContact => 'आपातकालीन संपर्क जोड़ें';

  @override
  String get nameLabel => 'नाम';

  @override
  String get phoneLabel => 'फ़ोन नंबर';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get maxContactsWarning =>
      'आप अधिकतम 3 आपातकालीन संपर्क सहेज सकते हैं।';

  @override
  String get settingsGeneral => 'सामान्य';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get languageDefault => 'अंग्रेज़ी (डिफ़ॉल्ट)';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get emergencySettings => 'आपातकालीन सेटिंग्स';

  @override
  String get manageContacts => 'अपने SOS संपर्क प्रबंधित करें';

  @override
  String get syncOfflineData => 'ऑफ़लाइन डेटा सिंक करें';

  @override
  String get syncDescription => '50 किमी के भीतर सेवाएं डाउनलोड करें';

  @override
  String get syncing => 'नवीनतम आपातकालीन सेवाओं का डेटाबेस सिंक हो रहा है...';

  @override
  String get setupTitle => 'RoadSoS सेटअप';

  @override
  String get welcomeTitle => 'RoadSoS में आपका स्वागत है';

  @override
  String get welcomeSubtext =>
      'आपातकालीन सुविधाओं को सक्षम करने के लिए अपनी प्रोफ़ाइल पूरी करें।';

  @override
  String get personalDetails => 'व्यक्तिगत विवरण';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get yourContact => 'आपका संपर्क नंबर';

  @override
  String get aadhaarNumber => 'आधार नंबर';

  @override
  String get primaryEmergencyContact => 'प्राथमिक आपातकालीन संपर्क';

  @override
  String get primaryContactSubtext =>
      'SOS दबाने पर इस संपर्क को SMS अलर्ट प्राप्त होगा।';

  @override
  String get contactName => 'संपर्क का नाम';

  @override
  String get contactNumber => 'संपर्क नंबर';

  @override
  String get completeSetup => 'सेटअप पूरा करें';

  @override
  String get nearbyServicesMap => 'आस-पास की सेवाओं का मानचित्र';

  @override
  String get chatbotTitle => 'RoadSoS AI सहायक';

  @override
  String get chatbotPlaceholder =>
      'मुझसे पास के अस्पतालों, प्राथमिक चिकित्सा या आपातकालीन सुझावों के बारे में पूछें!';

  @override
  String get typeMessage => 'अपना संदेश लिखें...';

  @override
  String get findingServices => 'आस-पास की सेवाएं खोज रहे हैं...';

  @override
  String noServicesFound(Object type) {
    return 'आस-पास कोई $type नहीं मिला';
  }

  @override
  String get tryAgainOnline => 'नेटवर्क कनेक्टिविटी होने पर फिर से प्रयास करें';

  @override
  String get call => 'कॉल करें';

  @override
  String get directions => 'दिशा-निर्देश';

  @override
  String get tapForList => 'सूची के लिए टैप करें • मानचित्र के लिए लंबा दबाएं';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get tamil => 'तमिल';
}
