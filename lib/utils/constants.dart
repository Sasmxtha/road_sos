import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color white = Colors.white;
  static const Color darkGrey = Color(0xFF333333);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color warningOrange = Color(0xFFF57C00);
}

class AppTextStyles {
  static const TextStyle header = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.darkGrey,
  );
  static const TextStyle subheader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGrey,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.darkGrey,
  );
  static const TextStyle sosButton = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.white,
    letterSpacing: 2,
  );
}

class AppConstants {
  static const double radius50Km = 50000; // in meters
}
