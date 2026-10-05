import 'package:flutter/material.dart';
import 'tokens.dart';

/// Escala tipográfica (Poppins empaquetada en assets/fonts).
/// En las pantallas solo se usa `copyWith` para cambiar el color.
class AppText {
  static const family = 'Poppins';
  static const _tabular = [FontFeature.tabularFigures()];

  static const logo = TextStyle(fontFamily: family, fontSize: 28, fontWeight: FontWeight.w500, height: 1.1, letterSpacing: -0.5, color: AppColors.textPrimary);
  static const hero = TextStyle(fontFamily: family, fontSize: 40, fontWeight: FontWeight.w600, height: 1.05, letterSpacing: -0.8, color: AppColors.textPrimary, fontFeatures: _tabular);
  static const display = TextStyle(fontFamily: family, fontSize: 28, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.3, color: AppColors.textPrimary, fontFeatures: _tabular);
  static const title = TextStyle(fontFamily: family, fontSize: 22, fontWeight: FontWeight.w500, height: 1.25, letterSpacing: -0.2, color: AppColors.textPrimary);
  static const question = TextStyle(fontFamily: family, fontSize: 20, fontWeight: FontWeight.w500, height: 1.3, color: AppColors.textPrimary);
  static const section = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w500, height: 1.3, color: AppColors.textPrimary);
  static const navTitle = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w500, height: 1.2, color: AppColors.textPrimary);
  static const body = TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w400, height: 1.55, color: AppColors.textSecondary);
  static const label = TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w500, height: 1.2, color: AppColors.textPrimary);
  static const button = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w500, height: 1.0, color: AppColors.textPrimary);
  static const buttonSmall = TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w500, height: 1.0, color: AppColors.textPrimary);
  static const caption = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w400, height: 1.35, color: AppColors.textMuted);
  static const captionStrong = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500, height: 1.35, color: AppColors.textPrimary, fontFeatures: _tabular);
  static const micro = TextStyle(fontFamily: family, fontSize: 11, fontWeight: FontWeight.w500, height: 1.2, color: AppColors.textMuted, fontFeatures: _tabular);
  static const brandSubtitle = TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w500, height: 1.3, color: AppColors.accent);

  /// Campo de texto: 16 para que iOS Safari no haga zoom al enfocar.
  static const input = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w400, height: 1.3, color: AppColors.textPrimary);
}
