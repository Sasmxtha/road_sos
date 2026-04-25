import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RoadSoS'**
  String get appTitle;

  /// No description provided for @sosButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosButtonLabel;

  /// No description provided for @sosSubtext.
  ///
  /// In en, this message translates to:
  /// **'Tap to send instant alert\nto emergency contacts'**
  String get sosSubtext;

  /// No description provided for @quickServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Services Nearby'**
  String get quickServicesTitle;

  /// No description provided for @hospitalLabel.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get hospitalLabel;

  /// No description provided for @policeLabel.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get policeLabel;

  /// No description provided for @ambulanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get ambulanceLabel;

  /// No description provided for @towingLabel.
  ///
  /// In en, this message translates to:
  /// **'Towing'**
  String get towingLabel;

  /// No description provided for @traumaLabel.
  ///
  /// In en, this message translates to:
  /// **'Trauma'**
  String get traumaLabel;

  /// No description provided for @punctureLabel.
  ///
  /// In en, this message translates to:
  /// **'Puncture'**
  String get punctureLabel;

  /// No description provided for @homeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// No description provided for @mapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapLabel;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode - Using Cached Services'**
  String get offlineBanner;

  /// No description provided for @accidentDetected.
  ///
  /// In en, this message translates to:
  /// **'Accident Detected!'**
  String get accidentDetected;

  /// No description provided for @accidentMessage.
  ///
  /// In en, this message translates to:
  /// **'We detected a possible accident.\nSending SOS automatically in:'**
  String get accidentMessage;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @iAmOk.
  ///
  /// In en, this message translates to:
  /// **'I am OK'**
  String get iAmOk;

  /// No description provided for @sendSosNow.
  ///
  /// In en, this message translates to:
  /// **'Send SOS Now'**
  String get sendSosNow;

  /// No description provided for @noContactsWarning.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts saved! Add some in Settings.'**
  String get noContactsWarning;

  /// No description provided for @sosSent.
  ///
  /// In en, this message translates to:
  /// **'SOS sent to {count} contacts!'**
  String sosSent(Object count);

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @emergencyContactsSubtext.
  ///
  /// In en, this message translates to:
  /// **'These contacts will receive an SMS with your location when you press SOS.'**
  String get emergencyContactsSubtext;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get addContact;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @maxContactsWarning.
  ///
  /// In en, this message translates to:
  /// **'You can only save up to 3 emergency contacts.'**
  String get maxContactsWarning;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageDefault.
  ///
  /// In en, this message translates to:
  /// **'English (Default)'**
  String get languageDefault;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @emergencySettings.
  ///
  /// In en, this message translates to:
  /// **'Emergency Settings'**
  String get emergencySettings;

  /// No description provided for @manageContacts.
  ///
  /// In en, this message translates to:
  /// **'Manage your SOS contacts'**
  String get manageContacts;

  /// No description provided for @syncOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Sync Offline Data'**
  String get syncOfflineData;

  /// No description provided for @syncDescription.
  ///
  /// In en, this message translates to:
  /// **'Download services within 50km'**
  String get syncDescription;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing latest emergency services database...'**
  String get syncing;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'RoadSoS Setup'**
  String get setupTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to RoadSoS'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtext.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile to enable emergency features.'**
  String get welcomeSubtext;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @yourContact.
  ///
  /// In en, this message translates to:
  /// **'Your Contact Number'**
  String get yourContact;

  /// No description provided for @aadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get aadhaarNumber;

  /// No description provided for @primaryEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Primary Emergency Contact'**
  String get primaryEmergencyContact;

  /// No description provided for @primaryContactSubtext.
  ///
  /// In en, this message translates to:
  /// **'This contact will receive SMS alerts when you press SOS.'**
  String get primaryContactSubtext;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get contactName;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumber;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @nearbyServicesMap.
  ///
  /// In en, this message translates to:
  /// **'Nearby Services Map'**
  String get nearbyServicesMap;

  /// No description provided for @chatbotTitle.
  ///
  /// In en, this message translates to:
  /// **'RoadSoS AI Assistant'**
  String get chatbotTitle;

  /// No description provided for @chatbotPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask me about nearby hospitals,\nfirst aid, or emergency tips!'**
  String get chatbotPlaceholder;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @findingServices.
  ///
  /// In en, this message translates to:
  /// **'Finding nearby services...'**
  String get findingServices;

  /// No description provided for @noServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No {type}s found nearby'**
  String noServicesFound(Object type);

  /// No description provided for @tryAgainOnline.
  ///
  /// In en, this message translates to:
  /// **'Try again when you have network connectivity'**
  String get tryAgainOnline;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @tapForList.
  ///
  /// In en, this message translates to:
  /// **'Tap a card for list view • Long press for map view'**
  String get tapForList;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
