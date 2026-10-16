import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens.dart';
import '../typography.dart';

/// Feedback táctil común: escala + háptica. Sustituye al ripple de Material.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap != null && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed && !AppMotion.reduced(context) ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}

/// Tarjeta de cristal. `BackdropFilter` es caro: `blur: true` solo en la
/// tarjeta destacada de una pantalla, nunca en filas de listas.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.blur = false,
    this.radius = AppRadii.card,
    this.borderColor = AppColors.border,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool blur;
  final double radius;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: blur
              ? const [Color(0xCC1E1E25), AppColors.surfaceGlass]
              : AppColors.cardGradient,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!blur) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: content,
      ),
    );
  }
}

/// Fondo negro con halos radiales muy tenues. Para pantallas de flujo
/// (onboarding, acceso, tienda); en listas densas, negro liso.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: AppColors.background),
      const Positioned(
          top: -140, left: -120, child: _Glow(color: Color(0x33402A9E), size: 380)),
      const Positioned(
          top: 180, right: -160, child: _Glow(color: Color(0x1F236BFE), size: 360)),
      child,
    ]);
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}

/// Halo de color detrás del protagonista de la pantalla.
class HeroGlow extends StatelessWidget {
  const HeroGlow({super.key, required this.child, this.size = 220});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.radialGlow,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Flotación senoidal del protagonista; se detiene con "reducir movimiento".
class Floating extends StatefulWidget {
  const Floating({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.phase = 0,
    this.period = AppMotion.ambient,
  });
  final Widget child;
  final double amplitude;
  final double phase; // 0..1, desfasa varios objetos
  final Duration period;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = AppMotion.reduced(context);
    if (reduced && _c.isAnimating) _c.stop();
    if (!reduced && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = (_c.value + widget.phase) * 2 * math.pi;
          return Transform.translate(
              offset: Offset(0, math.sin(t) * widget.amplitude), child: child);
        },
      ),
    );
  }
}

/// Orbe iridiscente: sustituto digno de un render 3D.
class IridescentOrb extends StatelessWidget {
  const IridescentOrb({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
            colors: [...AppColors.iridescent, AppColors.iridescent.first]),
        boxShadow: [BoxShadow(color: AppColors.glow, blurRadius: size * 0.6)],
      ),
      foregroundDecoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 0.9,
          colors: [Color(0x80FFFFFF), Color(0x00FFFFFF)],
        ),
      ),
    );
  }
}

/// Icono dentro de un chip circular: sustituye a los emojis.
class IconChip extends StatelessWidget {
  const IconChip({
    super.key,
    required this.icon,
    this.size = 36,
    this.highlighted = false,
    this.color,
  });
  final IconData icon;
  final double size;
  final bool highlighted;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? null : AppColors.surfaceRaised,
        border: Border.all(color: AppColors.border),
        gradient: highlighted ? AppGradients.brand : null,
      ),
      child: Icon(icon,
          size: size * 0.5,
          color: color ??
              (highlighted ? AppColors.accent : AppColors.textPrimary)),
    );
  }
}

/// Etiqueta pequeña (estado, precio, rareza).
class AppPill extends StatelessWidget {
  const AppPill({super.key, required this.text, this.icon, this.color});
  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: AppSpace.xs),
        ],
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.micro.copyWith(color: fg)),
        ),
      ]),
    );
  }
}

/// Lista que se desvanece arriba y abajo para sugerir scroll.
class FadeEdges extends StatelessWidget {
  const FadeEdges({super.key, required this.child, this.fraction = 0.08});
  final Widget child;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, fraction, 1 - fraction, 1],
        colors: const [
          Color(0x00000000),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0x00000000),
        ],
      ).createShader(rect),
      child: child,
    );
  }
}
