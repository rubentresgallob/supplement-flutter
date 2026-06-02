import 'package:flutter/material.dart';
import '../../../domain/entities/streak.dart';
import '../../../core/constants/app_constants.dart';

/// Compact pill badge shown in the Home header top-right.
class StreakBadge extends StatefulWidget {
  final Streak streak;
  const StreakBadge({super.key, required this.streak});

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _glowAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.streak.currentStreak;
    final active = days > 0;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => ScaleTransition(
        scale: _pulseScale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? [
                      AppColors.fireRed.withValues(alpha: 0.25),
                      AppColors.gold.withValues(alpha: 0.18),
                    ]
                  : [
                      AppColors.bgCardElevated,
                      AppColors.bgCardElevated,
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? AppColors.primary
                      .withValues(alpha: 0.35 + 0.2 * _glowAnim.value)
                  : AppColors.border,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: 0.1 + 0.15 * _glowAnim.value),
                      blurRadius: 14 + 6 * _glowAnim.value,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: child,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: active ? AppColors.neonGold : AppColors.textMuted,
            size: 16,
          ),
          const SizedBox(width: 5),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: days.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${v.round()}',
              style: TextStyle(
                color: active ? Colors.white : AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.02,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'días',
            style: TextStyle(
              color: active
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
