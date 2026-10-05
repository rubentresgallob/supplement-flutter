import 'package:flutter/material.dart';

/// Paleta premium oscura: negro puro, azul eléctrico para la acción principal
/// y lavanda como acento (seleccionado, progreso, racha).
class AppColors {
  // Fondos y superficies (grafito frío, nunca gris neutro)
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF16161C);
  static const Color surfaceGlass = Color(0xB316161C); // 70 %
  static const Color surfaceRaised = Color(0xFF25262C);
  static const Color surfaceSelected = Color(0xFF0E0E12);
  static const Color border = Color(0x1AFFFFFF); // blanco 10 %
  static const Color borderStrong = Color(0x38FFFFFF); // blanco 22 %

  // Acción principal: solo el CTA
  static const Color primary = Color(0xFF236BFE);
  static const Color primaryDisabled = Color(0x66236BFE);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Acento: estado seleccionado, progreso, racha
  static const Color accent = Color(0xFFA99BFF);
  static const Color accentStrong = Color(0xFF765DF5);
  static const Color mint = Color(0xFF6EE7D8);
  static const Color pink = Color(0xFFF3A8E6);

  // Estados
  static const Color success = mint;
  static const Color danger = Color(0xFFFF5C7A);
  static const Color error = danger;
  static const Color warning = Color(0xFFFFC76B);
  static const Color info = accent;

  // Podio del ranking
  static const Color silver = Color(0xFFC9CAD6);
  static const Color bronze = Color(0xFFD9A07A);

  // Texto (muted ≥ 4.5:1 sobre negro; tertiary solo para pistas decorativas)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8B95);
  static const Color textMuted = Color(0xFF7C7C86);
  static const Color textTertiary = Color(0xFF4A4A52);

  // Superficies translúcidas
  static const Color surfaceMuted = Color(0x0AFFFFFF); // 4 %
  static const Color input = Color(0x14FFFFFF); // 8 %
  static const Color hairline = Color(0x0FFFFFFF); // 6 %
  static const Color ring = Color(0x80A99BFF);
  static const Color scrim = Color(0xB3000000);
  static const Color glow = Color(0x66765DF5);

  static const List<Color> iridescent = [pink, accent, Color(0xFF7FE3E0)];

  // ── Nombres antiguos (se mantienen para no tocar la lógica de las pantallas)
  static const Color bgDeep = background;
  static const Color bgCard = surface;
  static const Color bgCardElevated = surfaceRaised;
  static const Color gold = accent;
  static const Color neonOrange = accent;
  static const Color neonGold = pink;
  static const Color deepAmber = accentStrong;
  static const Color fireRed = accentStrong;

  static const List<Color> brandGradient = [Color(0xFF3A2F7A), Color(0xFF1B2A55)];
  static const List<Color> accentGradient = [accentStrong, accent];
  static const List<Color> bgGradient = [background, background];
  static const List<Color> cardGradient = [Color(0xFF1E1E25), surface];
  static const List<Color> fireGradient = [accentStrong, accent, pink];
  static const List<Color> neonGradient = [accent, pink];
  static const List<Color> glowGradient = [Color(0x33765DF5), Color(0x00765DF5)];
}

class AppGradients {
  static const brand = LinearGradient(
    colors: AppColors.brandGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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

  static const iridescent = LinearGradient(
    colors: AppColors.iridescent,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const radialGlow = RadialGradient(
    colors: AppColors.glowGradient,
    radius: 0.5,
  );
}

/// Escala de espaciado en rejilla de 4pt.
class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margen horizontal de pantalla.
  static const double screen = 24;
}

/// Nombre antiguo de la escala de espaciado.
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

class AppRadii {
  static const double button = 16;
  static const double card = 18;
  static const double tile = 10;
  static const double chip = 6;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Nombre antiguo de los radios.
class AppRadius {
  static const double sm = AppRadii.chip;
  static const double md = 8;
  static const double lg = AppRadii.tile;
  static const double xl = AppRadii.button;
  static const double xxl = AppRadii.card;
  static const double sheet = AppRadii.sheet;
}

/// Duraciones y curvas: todo responde igual.
class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration base = medium;
  static const Duration slow = Duration(milliseconds: 420);

  /// Momento protagonista (compra, logro).
  static const Duration hero = Duration(milliseconds: 700);

  /// Flotación del hero.
  static const Duration ambient = Duration(seconds: 6);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve pop = Curves.easeOutBack;

  /// Respeta "Reducir movimiento" del sistema.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Sin sombras grises de Material: la profundidad viene de bordes y halos.
class AppShadows {
  static const List<BoxShadow> xs = [];
  static const List<BoxShadow> md = [];

  static List<BoxShadow> glow(Color color, {double strength = 0.35}) => [
        BoxShadow(color: color.withValues(alpha: strength), blurRadius: 18),
      ];
}

/// Decoraciones reutilizables.
class AppDecorations {
  /// Tarjeta opaca: superficie grafito + borde fino.
  static BoxDecoration frame({
    Color? color,
    double radius = AppRadii.card,
    Color border = AppColors.border,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      );
}
