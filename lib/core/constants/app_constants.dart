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
  static const Color accentColor = AppColors.accent;
  static const Color errorColor = AppColors.error;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color streakColor = AppColors.accent;
  static const Color goldColor = AppColors.gold;
  static const Color silverColor = Color(0xFFC0C0C0);
  static const Color bronzeColor = Color(0xFFCD7F32);
}

/// Paleta basada en el tema oscuro de coss.com/ui:
/// base neutra, primario casi blanco y el naranja reservado como acento
/// (racha, progreso, celebraciones).
class AppColors {
  // Backgrounds (neutral-950 mezclado con blanco, como coss)
  static const Color bgDeep    = Color(0xFF121212);
  static const Color bgCard    = Color(0xFF181818);
  static const Color bgCardElevated = Color(0xFF1F1F1F);
  static const Color border    = Color(0xFF262626);

  // Primario coss: neutral-100 con texto neutral-900
  static const Color primary   = Color(0xFFF5F5F5);
  static const Color onPrimary = Color(0xFF171717);

  // Acento de marca: solo para racha / progreso / logros
  static const Color accent    = Color(0xFFFF6B35);
  static const Color gold      = Color(0xFFFAB437);

  // Extras del acento
  static const Color neonOrange = Color(0xFFFF8C42);
  static const Color neonGold   = Color(0xFFFFD166);
  static const Color deepAmber  = Color(0xFFE07B00);
  static const Color fireRed    = Color(0xFFFF3D00);

  // Semantic (paleta coss: emerald / red / amber / blue, tonos -400)
  static const Color success   = Color(0xFF34D399);
  static const Color error     = Color(0xFFF87171);
  static const Color warning   = Color(0xFFFBBF24);
  static const Color info      = Color(0xFF60A5FA);

  // Superficies translúcidas (blanco con alpha, como coss)
  static const Color surfaceMuted = Color(0x0AFFFFFF); // 4%
  static const Color input        = Color(0x14FFFFFF); // 8%
  static const Color hairline     = Color(0x0FFFFFFF); // 6%
  static const Color ring         = Color(0x80A3A3A3);

  // Texto (contraste WCAG AA verificado: muted 4.8:1 sobre bgCardElevated)
  static const Color textPrimary   = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA3A3A3);
  static const Color textMuted     = Color(0xFF8A8A8A);

  // Gradients
  static const List<Color> brandGradient  = [Color(0xFFFAFAFA), Color(0xFFE5E5E5)];
  static const List<Color> accentGradient = [accent, gold];
  static const List<Color> bgGradient     = [bgDeep, bgDeep];
  static const List<Color> cardGradient   = [Color(0xFF1A1A1A), Color(0xFF161616)];
  static const List<Color> fireGradient   = [fireRed, accent, gold];
  static const List<Color> neonGradient   = [neonOrange, neonGold];
  static const List<Color> glowGradient   = [Color(0x1AFFFFFF), Color(0x00FFFFFF)];
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

  static const accent = LinearGradient(
    colors: AppColors.accentGradient,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const neon = LinearGradient(
    colors: AppColors.neonGradient,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const radialGlow = RadialGradient(
    colors: [Color(0x14FFFFFF), Color(0x00121212)],
    radius: 0.8,
  );
}
