import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens.dart';

/// Metal de una medalla: [luz, medio, sombra].
class RewardMetal {
  final List<Color> shades;

  /// Iridiscente: el borde gira por rosa → lavanda → cian.
  final bool iridescent;

  const RewardMetal(this.shades, {this.iridescent = false});

  static const bronze = RewardMetal([Color(0xFFF3C7A4), Color(0xFFC98958), Color(0xFF7A4A2B)]);
  static const silver = RewardMetal([Color(0xFFF4F5FB), Color(0xFFB9BBCB), Color(0xFF6E7186)]);
  static const gold = RewardMetal([Color(0xFFFFEDB0), Color(0xFFE9B949), Color(0xFF9A6A14)]);
  static const lavender = RewardMetal([Color(0xFFE4DEFF), Color(0xFFA99BFF), Color(0xFF4B36C4)]);
  static const rose = RewardMetal([Color(0xFFFFD9F6), Color(0xFFF3A8E6), Color(0xFF9B4FB0)]);
  static const mint = RewardMetal([Color(0xFFD6FFF8), Color(0xFF6EE7D8), Color(0xFF1F8F86)]);
  static const prism = RewardMetal(
      [Color(0xFFFFFFFF), Color(0xFFC9BEFF), Color(0xFF5A46D6)],
      iridescent: true);

  /// Sin conseguir: grafito apagado.
  static const locked = RewardMetal([Color(0xFF4A4B55), Color(0xFF2E2F37), Color(0xFF1B1B21)]);

  Color get light => shades[0];
  Color get mid => shades[1];
  Color get dark => shades[2];
}

/// Medalla: disco de metal biselado con el icono grabado y, si cabe, su cinta.
class MedalArt extends StatelessWidget {
  const MedalArt({
    super.key,
    required this.metal,
    required this.icon,
    this.size = 64,
    this.ribbon = true,
    this.glow = true,
  });

  final RewardMetal metal;
  final IconData icon;
  final double size;
  final bool ribbon;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final discRadius = size * (ribbon ? 0.31 : 0.46);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MedalPainter(metal: metal, ribbon: ribbon, glow: glow),
            ),
          ),
          Align(
            alignment: Alignment(0, ribbon ? 0.26 : 0),
            child: Icon(
              icon,
              size: discRadius * 0.95,
              color: Color.lerp(metal.dark, AppColors.background, 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter({required this.metal, required this.ribbon, required this.glow});
  final RewardMetal metal;
  final bool ribbon;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, ribbon ? h * 0.63 : h / 2);
    final r = w * (ribbon ? 0.31 : 0.46);

    if (ribbon) {
      // Dos cintas en V que bajan hasta el disco
      void tail(double x0, double x1, List<Color> colors) {
        final path = Path()
          ..moveTo(w * x0, 0)
          ..lineTo(w * x1, 0)
          ..lineTo(center.dx + (x1 - 0.5) * w * 0.25, center.dy - r * 0.55)
          ..lineTo(center.dx + (x0 - 0.5) * w * 0.25, center.dy - r * 0.55)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ).createShader(Rect.fromLTWH(0, 0, w, center.dy)),
        );
      }

      tail(0.20, 0.44, const [AppColors.accentStrong, Color(0xFF3A2A9E)]);
      tail(0.56, 0.80, const [AppColors.accent, AppColors.accentStrong]);
    }

    final rect = Rect.fromCircle(center: center, radius: r);

    if (glow) {
      canvas.drawCircle(
        center,
        r * 0.95,
        Paint()
          ..color = metal.mid.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
      );
    }

    // Canto exterior
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = (metal.iridescent
                ? const SweepGradient(colors: [
                    AppColors.pink,
                    AppColors.accent,
                    Color(0xFF7FE3E0),
                    AppColors.accent,
                    AppColors.pink,
                  ])
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [metal.light, metal.mid, metal.dark],
                  ) as Gradient)
            .createShader(rect),
    );
    // Bisel: el degradado al revés crea el escalón
    canvas.drawCircle(
      center,
      r * 0.84,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [metal.dark, metal.mid],
        ).createShader(rect),
    );
    // Cara
    canvas.drawCircle(
      center,
      r * 0.76,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: [metal.light, metal.mid, metal.dark],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.76)),
    );
    // Reflejo superior
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.62),
      math.pi * 1.05,
      math.pi * 0.5,
      false,
      Paint()
        ..color = const Color(0x73FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.07,
    );
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.metal != metal || old.ribbon != ribbon || old.glow != glow;
}

/// Protector de racha: escudo iridiscente con el icono dentro.
class ShieldArt extends StatelessWidget {
  const ShieldArt({super.key, this.size = 64, this.icon});
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _ShieldPainter())),
          if (icon != null)
            Align(
              alignment: const Alignment(0, -0.06),
              child: Icon(icon, size: size * 0.34, color: AppColors.textPrimary),
            ),
        ],
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  Path _shield(Size s, double inset) {
    final w = s.width;
    final h = s.height;
    double x(double v) => w * (0.5 + (v - 0.5) * (1 - inset));
    double y(double v) => h * (0.5 + (v - 0.5) * (1 - inset));
    return Path()
      ..moveTo(x(0.5), y(0.06))
      ..lineTo(x(0.88), y(0.2))
      ..lineTo(x(0.88), y(0.5))
      ..quadraticBezierTo(x(0.86), y(0.8), x(0.5), y(0.95))
      ..quadraticBezierTo(x(0.14), y(0.8), x(0.12), y(0.5))
      ..lineTo(x(0.12), y(0.2))
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = _shield(size, 0);
    canvas.drawPath(
      outer,
      Paint()
        ..color = AppColors.glow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.14),
    );
    canvas.drawPath(
        outer, Paint()..shader = AppGradients.iridescent.createShader(rect));
    // Panel interior
    canvas.drawPath(
      _shield(size, 0.2),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A3BA8), Color(0xFF1B2A55)],
        ).createShader(rect),
    );
    // Reflejo lateral
    canvas.save();
    canvas.clipPath(outer);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.12, 0)
        ..lineTo(size.width * 0.5, 0)
        ..lineTo(size.width * 0.2, size.height)
        ..lineTo(size.width * 0.12, size.height)
        ..close(),
      Paint()..color = const Color(0x24FFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => false;
}

/// Banner de perfil: tira con el degradado del banner, brillo y su motivo.
class BannerArt extends StatelessWidget {
  const BannerArt({
    super.key,
    required this.colors,
    required this.icon,
    this.width = 96,
    this.height = 56,
  });

  final List<Color> colors;
  final IconData icon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.button),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.45),
            blurRadius: height * 0.35,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            CustomPaint(painter: _BannerSheenPainter()),
            Align(
              alignment: const Alignment(-0.72, 0),
              child: Icon(icon, size: height * 0.44, color: AppColors.textPrimary),
            ),
            // Líneas de "texto" para que se lea como una cabecera de perfil
            Align(
              alignment: const Alignment(0.55, 0),
              child: FractionallySizedBox(
                widthFactor: 0.46,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(height * 0.11, 1, 0.9),
                    SizedBox(height: height * 0.1),
                    _line(height * 0.08, 0.6, 0.5),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.button),
                border: Border.all(color: AppColors.borderStrong),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(double h, double widthFactor, double alpha) =>
      FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: h,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      );
}

class _BannerSheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Círculos suaves de fondo
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.05),
        size.height * 0.6, Paint()..color = const Color(0x24FFFFFF));
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 1.05),
        size.height * 0.5, Paint()..color = const Color(0x1F000000));
    // Brillo diagonal
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.30, 0)
        ..lineTo(size.width * 0.44, 0)
        ..lineTo(size.width * 0.24, size.height)
        ..lineTo(size.width * 0.10, size.height)
        ..close(),
      Paint()..color = const Color(0x1FFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_BannerSheenPainter old) => false;
}
