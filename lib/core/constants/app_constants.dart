import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Suplementos Tracker';
  static const String disclaimer =
      'La responsabilidad sobre el uso y legalidad del suplemento recae en el usuario. Consulta siempre con un profesional sanitario.';

  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';

  // Legacy (used in old theme seed)
  static const Color primaryColor = AppColors.primary;
  static const Color accentColor = AppColors.gold;
  static const Color errorColor = AppColors.error;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.primary;
  static const Color streakColor = AppColors.primary;
  static const Color goldColor = AppColors.gold;
  static const Color silverColor = Color(0xFFC0C0C0);
  static const Color bronzeColor = Color(0xFFCD7F32);
}

class AppColors {
  // Backgrounds
  static const Color bgDeep    = Color(0xFF070B18);
  static const Color bgCard    = Color(0xFF111827);
  static const Color bgCardElevated = Color(0xFF1A2234);
  static const Color border    = Color(0xFF1E2A45);

  // Brand
  static const Color primary   = Color(0xFFFF6B35);
  static const Color gold      = Color(0xFFFAB437);

  // Neon / glow extras
  static const Color neonOrange = Color(0xFFFF8C42);
  static const Color neonGold   = Color(0xFFFFD166);
  static const Color deepAmber  = Color(0xFFE07B00);
  static const Color fireRed    = Color(0xFFFF3D00);

  // Semantic
  static const Color success   = Color(0xFF4ADE80);
  static const Color error     = Color(0xFFFF4444);

  // Text
  static const Color textPrimary   = Colors.white;
  static const Color textSecondary = Color(0xFF8B9CB5);
  static const Color textMuted     = Color(0xFF4B5A6E);

  // Gradients
  static const List<Color> brandGradient = [primary, gold];
  static const List<Color> bgGradient    = [Color(0xFF070B18), Color(0xFF0D1526)];
  static const List<Color> cardGradient  = [Color(0xFF131C2E), Color(0xFF0F1623)];
  static const List<Color> fireGradient  = [fireRed, primary, gold];
  static const List<Color> neonGradient  = [neonOrange, neonGold];
  static const List<Color> glowGradient  = [Color(0x44FF6B35), Color(0x00FF6B35)];
}

class AppGradients {
  static const brand = LinearGradient(
    colors: AppColors.brandGradient,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const background = LinearGradient(
    colors: AppColors.bgGradient,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const card = LinearGradient(
    colors: AppColors.cardGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const fire = LinearGradient(
    colors: AppColors.fireGradient,
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static const neon = LinearGradient(
    colors: AppColors.neonGradient,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const radialGlow = RadialGradient(
    colors: [Color(0x55FF6B35), Color(0x00070B18)],
    radius: 0.8,
  );
}
