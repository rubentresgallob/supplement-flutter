import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
import '../constants/app_constants.dart';

/// Idioma de la app.
///
/// Desde Flutter 3.47 Material vive también en el paquete `material_ui`, que es
/// el que usa forui. La app sigue usando `package:flutter/material.dart`, así que
/// hay que registrar las traducciones de AMBOS: si falta alguna, los TextField
/// lanzan "No MaterialLocalizations found" (pantalla roja).
class AppLocalization {
  static const locale = Locale('es', 'ES');

  static const List<LocalizationsDelegate<dynamic>> delegates = [
    ...FLocalizations.localizationsDelegates, // forui + material_ui + cupertino_ui
    GlobalMaterialLocalizations.delegate, // Material del framework (la app)
    GlobalCupertinoLocalizations.delegate,
  ];

  static const supportedLocales = [Locale('es', 'ES'), Locale('es'), Locale('en')];
}

/// Tema de forui (shadcn para Flutter) conectado a los tokens de la app,
/// para que sus componentes (diálogos, selector de hora, sheets…) encajen
/// con el resto del diseño.
class AppForuiTheme {
  static final FThemeData data = FThemeData(
    touch: true,
    debugLabel: 'Supplement Tracker Dark',
    colors: FColors.neutralDark.copyWith(
      background: AppColors.bgDeep,
      foreground: AppColors.textPrimary,
      card: AppColors.bgCard,
      primary: AppColors.primary,
      primaryForeground: AppColors.onPrimary,
      secondary: AppColors.bgCardElevated,
      secondaryForeground: AppColors.textPrimary,
      muted: AppColors.bgCardElevated,
      mutedForeground: AppColors.textSecondary,
      destructive: AppColors.error,
      error: AppColors.error,
      border: AppColors.border,
    ),
  );
}
