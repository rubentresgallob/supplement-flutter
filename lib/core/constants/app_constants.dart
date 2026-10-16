import 'package:flutter/widgets.dart';
import '../design/tokens.dart';

export '../design/tokens.dart' show AppColors, AppGradients;
export '../design/typography.dart';

class AppConstants {
  static const String appName = 'Supplement Tracker';
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
  static const Color silverColor = AppColors.silver;
  static const Color bronzeColor = AppColors.bronze;
}
