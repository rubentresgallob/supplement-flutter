import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../domain/entities/streak.dart';
import '../../../core/design/design.dart';

/// Compact pill badge shown in the Home header top-right.
class StreakBadge extends StatefulWidget {
  final Streak streak;
  const StreakBadge({super.key, required this.streak});

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge> {
  @override
  Widget build(BuildContext context) {
    final days = widget.streak.currentStreak;
    final active = days > 0;

    return Semantics(
      label: 'Racha de $days días',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceSelected : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: active ? AppColors.ring : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.flame,
              color: active ? AppColors.accent : AppColors.textMuted,
              size: 15,
            ),
            const SizedBox(width: AppSpace.xs),
            CountUp(
              value: days,
              style: AppText.captionStrong.copyWith(
                  color: active ? AppColors.textPrimary : AppColors.textMuted),
            ),
            const SizedBox(width: AppSpace.xs),
            const Text('días', style: AppText.micro),
          ],
        ),
      ),
    );
  }
}
