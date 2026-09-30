import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Tokens de diseño inspirados en coss.com/ui (--radius: 0.625rem = 10px).
class AppRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 14;
  static const double xxl = 20;
  static const double sheet = 24;
}

/// Escala de espaciado en rejilla de 4pt.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Tamaño mínimo de zona táctil (Apple HIG 44pt / WCAG 2.5.8).
  static const double minTouch = 44;
}

/// Duraciones y curvas. Mismas curvas que los toasts de coss.
class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.5, 1, 0.89, 1);

  /// Respeta "Reducir movimiento" del sistema.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

class AppShadows {
  /// Sombra suave tipo coss `shadow-xs/5`.
  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static List<BoxShadow> glow(Color color, {double strength = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: strength),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}

/// Decoraciones reutilizables.
class AppDecorations {
  /// Superficie "frame" de coss: fondo card + borde fino + brillo superior.
  static BoxDecoration frame({
    Color? color,
    double radius = AppRadius.xxl,
    Color border = AppColors.border,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
        boxShadow: AppShadows.xs,
      );
}
