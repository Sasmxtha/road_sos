import 'package:flutter/material.dart';
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
  
  // Load environment variables safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("No .env file found. Proceeding without it.");
  }

  bool isSignedUp = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    isSignedUp = prefs.getBool('isSignedUp') ?? false;
  } catch (e) {
    debugPrint("Error reading SharedPreferences: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccidentDetectionService()),
      ],
      child: RoadSoSApp(isSignedUp: isSignedUp),
    ),
  );
}

class RoadSoSApp extends StatelessWidget {
  final bool isSignedUp;
  const RoadSoSApp({Key? key, required this.isSignedUp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadSoS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryRed,
        scaffoldBackgroundColor: AppColors.lightGrey,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primaryRed,
          secondary: AppColors.darkGrey,
        ),
        fontFamily: 'Roboto', // Default fallback
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('hi', ''), // Hindi
        Locale('ta', ''), // Tamil
      ],
      home: isSignedUp ? const HomeScreen() : const SignupScreen(),
    );
  }
}
