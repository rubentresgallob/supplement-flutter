import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/models/rewards_models.dart';
import '../bloc/rewards_cubit.dart';

/// Color de cada rareza (borde y etiqueta de los objetos).
Color rarityColor(String rarity) => switch (rarity) {
      'rare' => AppColors.info,
      'epic' => const Color(0xFFA78BFA),
      'legendary' => AppColors.gold,
      _ => AppColors.textMuted,
    };

String rarityLabel(String rarity) => switch (rarity) {
      'rare' => 'Raro',
      'epic' => 'Épico',
      'legendary' => 'Legendario',
      _ => 'Común',
    };

/// Saldo de puntos en forma de píldora (cabecera de la home y la tienda).
class PointsChip extends StatelessWidget {
  final int points;
  final VoidCallback? onTap;

  const PointsChip({super.key, required this.points, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$points puntos',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.gem, color: AppColors.neonGold, size: 15),
              const SizedBox(width: 5),
              TweenAnimationBuilder<double>(
                tween: Tween(end: points.toDouble()),
                duration: AppMotion.of(context, const Duration(milliseconds: 900)),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  '${v.round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista previa de un objeto: Capsu con el accesorio, degradado del banner o emoji.
class ShopItemPreview extends StatelessWidget {
  final ShopItem item;
  final double size;
  final CapsuOutfit baseOutfit;

  const ShopItemPreview({
    super.key,
    required this.item,
    this.size = 64,
    this.baseOutfit = CapsuOutfit.none,
  });

  @override
  Widget build(BuildContext context) {
    if (item.category == 'capsu' && item.slot != null) {
      return Capsu(
        size: size * 0.8,
        interactive: false,
        outfit: baseOutfit.withSlot(item.slot!, item.code),
      );
    }
    if (item.category == 'banner' && item.colors.length >= 2) {
      return Container(
        width: size * 1.4,
        height: size * 0.8,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: item.colors),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Text(item.icon, style: TextStyle(fontSize: size * 0.38)),
      );
    }
    return Text(item.icon, style: TextStyle(fontSize: size * 0.62));
  }
}

/// Aviso flotante con Capsu celebrando los puntos ganados.
class RewardPopup {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context,
    RewardsCelebration celebration, {
    CapsuOutfit outfit = CapsuOutfit.none,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || celebration.isEmpty) return;

    dismiss();
    HapticFeedback.mediumImpact();
    final entry = OverlayEntry(
      builder: (_) => _RewardPopupView(
        celebration: celebration,
        outfit: outfit,
        onDismiss: dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 4200), dismiss);

    final text = celebration.rewards.isNotEmpty
        ? '¡Has ganado ${celebration.totalPoints} puntos!'
        : 'Tu protector ha salvado la racha';
    SemanticsService.sendAnnouncement(
        View.of(context), text, Directionality.of(context));
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _RewardPopupView extends StatelessWidget {
  final RewardsCelebration celebration;
  final CapsuOutfit outfit;
  final VoidCallback onDismiss;

  const _RewardPopupView({
    required this.celebration,
    required this.outfit,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (celebration.repairedDays.isNotEmpty)
        (
          '🛡️',
          celebration.repairedDays.length == 1
              ? 'Protector usado: racha salvada'
              : '${celebration.repairedDays.length} protectores usados: racha salvada',
          null as int?,
        ),
      for (final r in celebration.rewards)
        r.points > 0 ? ('💎', r.reason, r.points) : ('🎁', r.reason, null as int?),
    ];

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.of(context, const Duration(milliseconds: 500)),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.translate(
              offset: Offset(0, -40 * (1 - v)),
              child: Opacity(opacity: v.clamp(0, 1), child: child),
            ),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardElevated,
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                    boxShadow: [
                      ...AppShadows.md,
                      ...AppShadows.glow(AppColors.gold, strength: 0.2),
                    ],
                  ),
                  child: Row(
                    children: [
                      Capsu(
                        size: 54,
                        mood: CapsuMood.celebrate,
                        interactive: false,
                        outfit: outfit,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (celebration.totalPoints > 0)
                              Text(
                                '+${celebration.totalPoints} puntos',
                                style: const TextStyle(
                                  color: AppColors.neonGold,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            for (final (icon, text, pts) in lines.take(4))
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  pts == null ? '$icon $text' : '$icon $text  +$pts',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de la home cuando la racha se ha roto pero aún se puede recuperar.
class StreakRepairCard extends StatelessWidget {
  final StreakRepair repair;
  final VoidCallback onGoToShop;

  const StreakRepairCard({
    super.key,
    required this.repair,
    required this.onGoToShop,
  });

  @override
  Widget build(BuildContext context) {
    final missing = repair.missingProtectors;
    final days = repair.missedDays.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.bgCardElevated,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Capsu(size: 64, mood: CapsuMood.sad, interactive: false),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Se ha roto tu racha!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  days == 1
                      ? 'Fallaste 1 día. Recupérala con $missing protector 🛡️ antes de 48 h.'
                      : 'Fallaste $days días. Te faltan $missing protectores 🛡️ para recuperarla.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Recuperar racha',
                  icon: LucideIcons.shieldCheck,
                  size: AppButtonSize.sm,
                  onPressed: onGoToShop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
