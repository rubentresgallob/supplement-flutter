import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_tokens.dart';

/// Estado vacío basado en `Empty` de coss: media + título + descripción + acción.
class AppEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  /// Ilustración personalizada (p. ej. Capsu). Sustituye al icono apilado.
  final Widget? media;

  const AppEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.media,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.standard,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Media: personalizada o icono apilado (tarjeta central + dos rotadas)
            if (media != null) media! else SizedBox(
              width: 120,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _tile(angle: -0.18, offset: const Offset(-26, 6), opacity: 0.5),
                  _tile(angle: 0.18, offset: const Offset(26, 6), opacity: 0.5),
                  _tile(angle: 0, offset: Offset.zero, opacity: 1, withIcon: true),
                ],
              ),
            ),
            SizedBox(height: media != null ? AppSpacing.md : AppSpacing.xxl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.question,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required double angle,
    required Offset offset,
    required double opacity,
    bool withIcon = false,
  }) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.bgCardElevated,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.md,
            ),
            child: withIcon ? Icon(icon, color: AppColors.textPrimary, size: 26) : null,
          ),
        ),
      ),
    );
  }
}
