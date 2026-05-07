import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryRedDark = Color(0xFFB71C1C);
  static const Color primaryRedLight = Color(0xFFFF6F60);

  // Dark theme colors
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1C2333);
  static const Color darkCardLight = Color(0xFF232D3F);

  // Accent colors
  static const Color accentBlue = Color(0xFF58A6FF);
  static const Color accentGreen = Color(0xFF3FB950);
  static const Color accentOrange = Color(0xFFF0883E);
  static const Color accentPurple = Color(0xFFBC8CFF);
  static const Color accentCyan = Color(0xFF39D2C0);
  static const Color accentPink = Color(0xFFFF6B9D);

  // Text colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF6E7681);

  // Legacy support
  static const Color white = Colors.white;
  static const Color darkGrey = Color(0xFF333333);
  static const Color lightGrey = Color(0xFF0D1117);
  static const Color warningOrange = Color(0xFFF0883E);

  // Gradients
  static const LinearGradient sosGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE53935), Color(0xFFFF6F60)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1117), Color(0xFF161B22)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C2333), Color(0xFF232D3F)],
  );
}

class AppTextStyles {
  static const TextStyle header = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );
  static const TextStyle subheader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    color: AppColors.textTertiary,
  );
  static const TextStyle sosButton = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: AppColors.white,
    letterSpacing: 4,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 1.2,
  );
}

class AppConstants {
  static const double radius50Km = 50000; // in meters
}

class AppDecorations {
  static BoxDecoration glassmorphism({
    Color? color,
    double opacity = 0.08,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.08),
        width: 1,
      ),
    );
  }

  static BoxDecoration cardDecoration = BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withOpacity(0.06),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
