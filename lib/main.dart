import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/signup_screen.dart';
import 'services/accident_detection_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.darkSurface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("No .env file found. Proceeding without it.");
  }

  bool isSignedUp = false;
  String savedLocale = 'en';
  try {
    final prefs = await SharedPreferences.getInstance();
    isSignedUp = prefs.getBool('isSignedUp') ?? false;
    savedLocale = prefs.getString('language') ?? 'en';
  } catch (e) {
    debugPrint("Error reading SharedPreferences: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccidentDetectionService()),
      ],
      child: RoadSoSApp(isSignedUp: isSignedUp, locale: savedLocale),
    ),
  );
}

class RoadSoSApp extends StatelessWidget {
  final bool isSignedUp;
  final String locale;
  const RoadSoSApp({Key? key, required this.isSignedUp, required this.locale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadSoS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primaryRed,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryRed,
          secondary: AppColors.accentBlue,
          surface: AppColors.darkSurface,
          error: AppColors.primaryRed,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkCard,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.textTertiary,
        ),
      ),
      locale: Locale(locale, ''),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), Locale('hi', ''), Locale('ta', ''),
        Locale('te', ''), Locale('kn', ''), Locale('ml', ''),
        Locale('bn', ''), Locale('mr', ''), Locale('gu', ''),
        Locale('pa', ''),
      ],
      home: isSignedUp ? const HomeScreen() : const SignupScreen(),
    );
  }
}
