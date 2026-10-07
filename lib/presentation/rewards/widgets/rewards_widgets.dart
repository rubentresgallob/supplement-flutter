import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/models/rewards_models.dart';
import '../bloc/rewards_cubit.dart';

/// Color de cada rareza (borde y etiqueta de los objetos).
Color rarityColor(String rarity) => switch (rarity) {
      'rare' => AppColors.mint,
      'epic' => AppColors.accent,
      'legendary' => AppColors.pink,
      _ => AppColors.textMuted,
    };

/// Icono de cada objeto de la tienda (el backend manda un emoji; aquí se
/// traduce al set de iconos de la app). Las medallas, banners y protectores
/// no lo usan: se dibujan enteros en `reward_art.dart`.
IconData shopItemIcon(ShopItem item) => switch (item.category) {
      'medal' => LucideIcons.star,
      'banner' => LucideIcons.image,
      'consumable' => LucideIcons.shield,
      'capsu' => LucideIcons.sparkles,
      _ => LucideIcons.gift,
    };

/// Icono de los logros que no son de racha (los de racha llevan su número).
IconData achievementIcon(String code) => switch (code) {
      'first_intake' => LucideIcons.pill,
      'first_day' => LucideIcons.calendarCheck,
      'supplements_3' => LucideIcons.flaskConical,
      'first_friend' => LucideIcons.handshake,
      'friends_5' => LucideIcons.usersRound,
      'first_item' => LucideIcons.shoppingBag,
      _ => LucideIcons.trophy,
    };

/// Dibujo de cada medalla de la tienda: metal, silueta y grabado.
MedalArt shopMedalArt(
  ShopItem item, {
  double size = 64,
  bool ribbon = true,
  bool glow = true,
}) {
  final (metal, shape, label) = switch (item.code) {
    'medal_bronze' => (RewardMetal.bronze, MedalShape.round, null),
    'medal_silver' => (RewardMetal.silver, MedalShape.rosette, null),
    'medal_gold' => (RewardMetal.gold, MedalShape.sunburst, null),
    'medal_capsule' => (RewardMetal.gold, MedalShape.capsule, null),
    'medal_streak_30' => (RewardMetal.rose, MedalShape.flame, '30'),
    'medal_streak_100' => (RewardMetal.mint, MedalShape.hexagon, '100'),
    'medal_streak_365' => (RewardMetal.gold, MedalShape.crown, null),
    'medal_pro_diamond' => (RewardMetal.prism, MedalShape.gem, null),
    _ => (
        switch (item.rarity) {
          'rare' => RewardMetal.silver,
          'epic' => RewardMetal.lavender,
          'legendary' => RewardMetal.prism,
          _ => RewardMetal.bronze,
        },
        MedalShape.round,
        null,
      ),
  };
  return MedalArt(
    metal: metal,
    shape: shape,
    label: label,
    star: label == null,
    size: size,
    ribbon: ribbon,
    glow: glow,
  );
}

/// Dibujo de cada logro: los de racha suben de metal y de forma con los días.
MedalArt achievementArt(Achievement a, {double size = 48}) {
  if (!a.unlocked) {
    return MedalArt(
      metal: RewardMetal.locked,
      icon: LucideIcons.lock,
      size: size,
      ribbon: false,
      glow: false,
    );
  }
  final days = a.code.startsWith('streak_')
      ? int.tryParse(a.code.substring('streak_'.length))
      : null;
  final (metal, shape) = switch (days) {
    null => (
        a.code == 'friends_5' ? RewardMetal.silver : RewardMetal.lavender,
        MedalShape.round,
      ),
    < 14 => (RewardMetal.bronze, MedalShape.round),
    < 30 => (RewardMetal.silver, MedalShape.rosette),
    < 100 => (RewardMetal.gold, MedalShape.sunburst),
    < 365 => (RewardMetal.mint, MedalShape.hexagon),
    _ => (RewardMetal.prism, MedalShape.sunburst),
  };
  return MedalArt(
    metal: metal,
    shape: shape,
    label: days?.toString(),
    icon: days == null ? achievementIcon(a.code) : null,
    size: size,
    ribbon: false,
  );
}

/// Paisaje de cada banner.
BannerScene bannerScene(ShopItem item) => switch (item.code) {
      'banner_sunrise' => BannerScene.sunrise,
      'banner_ocean' => BannerScene.ocean,
      'banner_forest' => BannerScene.forest,
      'banner_galaxy' => BannerScene.galaxy,
      'banner_aurora' => BannerScene.aurora,
      _ => BannerScene.plain,
    };

/// Medalla equipada (perfil, probador, ranking): la pieza sin cinta.
class MedalIcon extends StatelessWidget {
  final ShopItem medal;
  final double size;
  const MedalIcon({super.key, required this.medal, this.size = 28});

  @override
  Widget build(BuildContext context) => ShopRender(
        code: medal.code,
        width: size,
        height: size,
        fallback: shopMedalArt(medal, size: size, ribbon: false, glow: false),
      );
}

/// Render 3D de un objeto de la tienda (`assets/shop/<code>.png`, o `.jpg` los banners; hechos con
/// Blender: ver `tool/shop_art/render_shop.py`). Si un objeto aún no tiene
/// render, se usa el dibujo hecho en código.
class ShopRender extends StatelessWidget {
  final String code;
  final double width;
  final double height;
  final Widget fallback;
  final BoxFit fit;

  const ShopRender({
    super.key,
    required this.code,
    required this.width,
    required this.height,
    required this.fallback,
    this.fit = BoxFit.contain,
  });

  static const rendered = {
    'streak_freeze',
    'medal_bronze',
    'medal_silver',
    'medal_gold',
    'medal_capsule',
    'medal_streak_30',
    'medal_streak_100',
    'medal_streak_365',
    'medal_pro_diamond',
    'banner_sunrise',
    'banner_ocean',
    'banner_forest',
    'banner_galaxy',
    'banner_aurora',
  };

  /// Ruta del render de [code] (los banners no llevan transparencia: JPG).
  static String assetOf(String code) =>
      'assets/shop/$code.${code.startsWith('banner_') ? 'jpg' : 'png'}';

  @override
  Widget build(BuildContext context) {
    if (!rendered.contains(code)) return fallback;
    return Image.asset(
      assetOf(code),
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

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
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.gem, color: AppColors.accent, size: 15),
              const SizedBox(width: 5),
              CountUp(value: points, style: AppText.captionStrong),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista previa de un objeto: Capsu con el accesorio, banner, medalla o escudo.
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
      final art = BannerArt(
        colors: item.colors,
        scene: bannerScene(item),
        width: size * 1.5,
        height: size * 0.82,
      );
      if (!ShopRender.rendered.contains(item.code)) return art;
      return Container(
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.button),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.button),
          child: ShopRender(
            code: item.code,
            width: size * 1.5,
            height: size * 0.82,
            fit: BoxFit.cover,
            fallback: art,
          ),
        ),
      );
    }
    if (item.category == 'medal') {
      return ShopRender(
        code: item.code,
        width: size * 1.1,
        height: size * 1.1,
        fallback: shopMedalArt(item, size: size),
      );
    }
    if (item.category == 'consumable') {
      return ShopRender(
        code: item.code,
        width: size,
        height: size,
        fallback: ShieldArt(size: size * 0.95),
      );
    }
    return IconChip(
      icon: shopItemIcon(item),
      size: size * 0.9,
      highlighted: true,
      color: rarityColor(item.rarity),
    );
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
    _timer = Timer(AppMotion.hero * 6, dismiss);

    final text = celebration.rewards.isNotEmpty
        ? 'Has ganado ${celebration.totalPoints} puntos'
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
          LucideIcons.shieldCheck,
          celebration.repairedDays.length == 1
              ? 'Protector usado: racha salvada'
              : '${celebration.repairedDays.length} protectores usados: racha salvada',
          null as int?,
        ),
      for (final r in celebration.rewards)
        r.points > 0
            ? (LucideIcons.gem, r.reason, r.points)
            : (LucideIcons.gift, r.reason, null as int?),
    ];

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.of(context, AppMotion.hero),
            curve: AppMotion.pop,
            builder: (_, v, child) => Transform.scale(
              scale: 0.8 + 0.2 * v,
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
                    border: Border.all(color: AppColors.ring),
                    boxShadow: AppShadows.glow(AppColors.accentStrong),
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
                                style: AppText.section,
                              ),
                            for (final (icon, text, pts) in lines.take(4))
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(icon, size: 12, color: AppColors.accent),
                                    const SizedBox(width: AppSpace.xs),
                                    Expanded(
                                      child: Text(
                                        pts == null ? text : '$text  +$pts',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.caption
                                            .copyWith(color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
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
        border: Border.all(color: AppColors.ring),
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
                  'Se ha roto tu racha',
                  style: AppText.navTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  days == 1
                      ? 'Fallaste 1 día. Recupérala con $missing protector antes de 48 h.'
                      : 'Fallaste $days días. Te faltan $missing protectores para recuperarla.',
                  style: AppText.caption.copyWith(color: AppColors.textSecondary),
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
