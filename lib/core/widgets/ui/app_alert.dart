import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_tokens.dart';

enum AppAlertVariant { info, success, warning, error }

/// Aviso en línea basado en `Alert` de coss.
class AppAlert extends StatelessWidget {
  final String message;
  final String? title;
  final AppAlertVariant variant;

  const AppAlert({
    super.key,
    required this.message,
    this.title,
    this.variant = AppAlertVariant.info,
  });

  (Color, IconData) get _visual => switch (variant) {
        AppAlertVariant.info => (AppColors.info, LucideIcons.info),
        AppAlertVariant.success => (AppColors.success, LucideIcons.circleCheck),
        AppAlertVariant.warning => (AppColors.warning, LucideIcons.triangleAlert),
        AppAlertVariant.error => (AppColors.error, LucideIcons.circleAlert),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _visual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                ],
                Text(message,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
