import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';

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

/// Silueta de la medalla. Las cuatro primeras son placas con un grabado en el
/// centro; las demás son el propio objeto (una cápsula, una llama…).
enum MedalShape { round, rosette, sunburst, hexagon, capsule, flame, crown, gem }

const _cyan = Color(0xFF7FE3E0);

/// Medalla dibujada: pieza de metal biselado con su grabado y, si cabe, su cinta.
class MedalArt extends StatelessWidget {
  const MedalArt({
    super.key,
    required this.metal,
    this.shape = MedalShape.round,
    this.star = false,
    this.label,
    this.icon,
    this.size = 64,
    this.ribbon = true,
    this.glow = true,
  });

  final RewardMetal metal;
  final MedalShape shape;

  /// Grabado del centro (solo uno): estrella, número o icono.
  final bool star;
  final String? label;
  final IconData? icon;

  final double size;
  final bool ribbon;
  final bool glow;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _MedalPainter(this),
      );
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.art);
  final MedalArt art;

  RewardMetal get metal => art.metal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final ribbon = art.ribbon;
    final center = Offset(w / 2, ribbon ? size.height * 0.63 : size.height / 2);
    final r = w * (ribbon ? 0.31 : 0.46);

    if (ribbon) _paintRibbon(canvas, w, center, r);
    if (art.glow) {
      canvas.drawCircle(
        center,
        r * 0.9,
        Paint()
          ..color = metal.mid.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
      );
    }

    switch (art.shape) {
      case MedalShape.capsule:
        _paintCapsule(canvas, center, r);
      case MedalShape.flame:
        _paintFlame(canvas, center, r);
      case MedalShape.crown:
        _paintCrown(canvas, center, r);
      case MedalShape.gem:
        _paintGem(canvas, center, r);
      default:
        _paintPlate(canvas, center, r);
    }
  }

  // Dos cintas en V que bajan hasta la anilla
  void _paintRibbon(Canvas canvas, double w, Offset center, double r) {
    final bottom = center.dy - r * 0.9;
    void tail(double x0, double x1, List<Color> colors) {
      final path = Path()
        ..moveTo(w * x0, 0)
        ..lineTo(w * x1, 0)
        ..lineTo(center.dx + (x1 - 0.5) * w * 0.25, bottom)
        ..lineTo(center.dx + (x0 - 0.5) * w * 0.25, bottom)
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
    canvas.drawCircle(
      Offset(center.dx, bottom),
      r * 0.17,
      Paint()
        ..color = metal.mid
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08,
    );
  }

  Shader _rim(Rect rect) => (metal.iridescent
          ? const SweepGradient(colors: [
              AppColors.pink,
              AppColors.accent,
              _cyan,
              AppColors.accent,
              AppColors.pink,
            ])
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [metal.light, metal.mid, metal.dark],
            ) as Gradient)
      .createShader(rect);

  /// Canto, escalón (degradado al revés) y cara de una pieza con forma [outline].
  void _bevel(Canvas canvas, Path outline, Path inner, Offset pivot, Rect rect) {
    canvas.drawPath(outline, Paint()..shader = _rim(rect));
    canvas.drawPath(
      _scaled(inner, pivot, 0.87),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [metal.dark, metal.mid],
        ).createShader(rect),
    );
    canvas.drawPath(
      _scaled(inner, pivot, 0.79),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: [metal.light, metal.mid, metal.dark],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  Color get _engraved => Color.lerp(metal.dark, AppColors.background, 0.3)!;
  Color get _engravedEdge => metal.light.withValues(alpha: 0.7);

  // ── Placas (redonda, roseta, sol, hexágono) ────────────────────────────
  void _paintPlate(Canvas canvas, Offset c, double r) {
    final rect = Rect.fromCircle(center: c, radius: r);
    final circle = Path()..addOval(rect);
    final (outline, inner) = switch (art.shape) {
      MedalShape.rosette => (
          _polar(c, (a) => r * (0.94 + 0.06 * math.cos(a * 12))),
          _scaled(circle, c, 0.92),
        ),
      MedalShape.sunburst => (_star(c, r, r * 0.86, 16), _scaled(circle, c, 0.92)),
      MedalShape.hexagon => () {
          final hex = _roundedPolygon(c, r, 6);
          return (hex, hex);
        }(),
      _ => (circle, circle),
    };
    _bevel(canvas, outline, inner, c, rect);

    final faceR = r * (art.shape == MedalShape.round ? 0.79 : 0.72);
    if (r >= 12) {
      // Reflejo superior
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: faceR * 0.84),
        math.pi * 1.05,
        math.pi * 0.5,
        false,
        Paint()
          ..color = const Color(0x73FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.06,
      );
    }
    _paintEngraving(canvas, c, faceR);
  }

  void _paintEngraving(Canvas canvas, Offset c, double faceR) {
    final d = Offset(faceR * 0.045, faceR * 0.045);
    if (art.star) {
      final star = _star(c, faceR * 0.62, faceR * 0.27, 5);
      canvas.drawPath(star.shift(d), Paint()..color = _engravedEdge);
      canvas.drawPath(star, Paint()..color = _engraved);
      return;
    }
    final label = art.label;
    final icon = art.icon;
    if (label == null && icon == null) return;

    final TextStyle style;
    final String text;
    if (label != null) {
      final fs = faceR * (label.length >= 3 ? 0.72 : 0.98);
      text = label;
      style = TextStyle(
        fontFamily: AppText.family,
        fontWeight: FontWeight.w600,
        fontSize: fs,
        height: 1,
        letterSpacing: -fs * 0.04,
      );
    } else {
      text = String.fromCharCode(icon!.codePoint);
      style = TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: faceR * 1.1,
        height: 1,
      );
    }
    _glyph(canvas, text, style.copyWith(color: _engravedEdge), c + d);
    _glyph(canvas, text, style.copyWith(color: _engraved), c);
  }

  // ── Cápsula ────────────────────────────────────────────────────────────
  void _paintCapsule(Canvas canvas, Offset c, double r) {
    final len = r * 2.0;
    final th = r * 0.94;
    final rect = Rect.fromCenter(center: Offset.zero, width: len, height: th);
    final body = RRect.fromRectAndRadius(rect, Radius.circular(th / 2));
    Shader vertical(List<Color> colors) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-math.pi / 4.5);
    canvas.drawRRect(body, Paint()..shader = vertical([metal.mid, metal.dark]));
    canvas.clipRRect(body.deflate(th * 0.08));
    // Mitad de metal y mitad clara
    canvas.drawRect(
      Rect.fromLTRB(-len / 2, -th / 2, 0, th / 2),
      Paint()..shader = vertical([metal.light, metal.mid, metal.dark]),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, -th / 2, len / 2, th / 2),
      Paint()
        ..shader = vertical([
          const Color(0xFFFFFFFF),
          Color.lerp(const Color(0xFFFFFFFF), metal.light, 0.7)!,
          metal.mid,
        ]),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: th * 0.06, height: th),
      Paint()..color = metal.dark.withValues(alpha: 0.7),
    );
    // Brillo a lo largo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-len / 2 + th * 0.32, -th * 0.30, len - th * 0.64, th * 0.13),
        Radius.circular(th),
      ),
      Paint()..color = const Color(0x99FFFFFF),
    );
    canvas.restore();
    if (r >= 12) _sparkle(canvas, c + Offset(r * 0.78, -r * 0.72), r * 0.24);
  }

  // ── Llama ──────────────────────────────────────────────────────────────
  void _paintFlame(Canvas canvas, Offset c, double r) {
    final outline = flamePath(c, r);
    final pivot = c + Offset(0, r * 0.25);
    _bevel(canvas, outline, outline, pivot, Rect.fromCircle(center: c, radius: r));
    final heart = c + Offset(-r * 0.02, r * 0.36);
    if (art.label != null || art.icon != null) {
      _paintEngraving(canvas, heart, r * 0.52);
    } else {
      canvas.drawPath(
        flamePath(heart + Offset(0, r * 0.08), r * 0.42),
        Paint()..color = metal.light.withValues(alpha: 0.85),
      );
    }
  }

  // ── Corona ─────────────────────────────────────────────────────────────
  void _paintCrown(Canvas canvas, Offset c, double r) {
    final o = c + Offset(0, r * 0.1);
    Offset p(double x, double y) => o + Offset(x * r, y * r);
    final tips = [p(-0.86, -0.45), p(0, -0.78), p(0.86, -0.45)];
    final crown = Path()
      ..moveTo(tips[0].dx, tips[0].dy)
      ..lineTo(p(-0.42, 0.02).dx, p(-0.42, 0.02).dy)
      ..lineTo(tips[1].dx, tips[1].dy)
      ..lineTo(p(0.42, 0.02).dx, p(0.42, 0.02).dy)
      ..lineTo(tips[2].dx, tips[2].dy)
      ..lineTo(p(0.7, 0.72).dx, p(0.7, 0.72).dy)
      ..lineTo(p(-0.7, 0.72).dx, p(-0.7, 0.72).dy)
      ..close();
    final rect = Rect.fromCircle(center: o, radius: r);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [metal.light, metal.mid, metal.dark],
    ).createShader(rect);
    // El trazo con uniones redondas suaviza las puntas
    canvas.drawPath(
      crown,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = r * 0.1,
    );
    canvas.drawPath(crown, Paint()..shader = shader);
    // Lado en sombra
    canvas.save();
    canvas.clipPath(crown);
    canvas.drawRect(
      Rect.fromLTRB(o.dx, o.dy - r, o.dx + r, o.dy + r),
      Paint()..color = metal.dark.withValues(alpha: 0.28),
    );
    canvas.restore();
    // Banda con joyas
    final band = RRect.fromRectAndRadius(
      Rect.fromLTRB(p(-0.7, 0).dx, p(0, 0.4).dy, p(0.7, 0).dx, p(0, 0.72).dy),
      Radius.circular(r * 0.08),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [metal.dark, metal.mid],
        ).createShader(band.outerRect),
    );
    const jewels = [AppColors.pink, _cyan, AppColors.accent];
    for (var i = 0; i < 3; i++) {
      final j = p(-0.4 + i * 0.4, 0.56);
      canvas.drawCircle(j, r * 0.1, Paint()..color = jewels[i]);
      canvas.drawCircle(j - Offset(r * 0.03, r * 0.03), r * 0.035,
          Paint()..color = const Color(0xCCFFFFFF));
    }
    for (final tip in tips) {
      canvas.drawCircle(tip, r * 0.13, Paint()..color = metal.light);
      canvas.drawCircle(tip, r * 0.13,
          Paint()
            ..color = metal.dark.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.03);
    }
  }

  // ── Diamante ───────────────────────────────────────────────────────────
  void _paintGem(Canvas canvas, Offset c, double r) {
    final o = c - Offset(0, r * 0.06);
    Offset p(double x, double y) => o + Offset(x * r, y * r);
    final a = p(-0.52, -0.72), b = p(0.52, -0.72);
    final right = p(0.98, -0.2), left = p(-0.98, -0.2);
    final g1 = p(-0.36, -0.2), g2 = p(0.36, -0.2);
    final tip = p(0, 0.98);
    final lilac = Color.lerp(metal.light, metal.mid, 0.6)!;
    final prism = metal.iridescent;

    void facet(List<Offset> pts, Color color) =>
        canvas.drawPath(Path()..addPolygon(pts, true), Paint()..color = color);

    facet([a, g1, left], prism ? const Color(0xFFFFD9F6) : lilac);
    facet([a, b, g2, g1], metal.light);
    facet([b, right, g2], lilac);
    facet([left, g1, tip], prism ? AppColors.accent : metal.mid);
    facet([g1, g2, tip], prism ? _cyan : Color.lerp(metal.light, metal.mid, 0.3)!);
    facet([g2, right, tip], prism ? AppColors.accentStrong : metal.dark);

    final edge = Paint()
      ..color = const Color(0x99FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(0.6, r * 0.035);
    canvas.drawPath(
      Path()
        ..addPolygon([a, b, right, tip, left], true)
        ..addPolygon([left, right], false)
        ..addPolygon([a, g1, tip, g2, b], false),
      edge,
    );
    if (r >= 12) _sparkle(canvas, p(0.8, -0.82), r * 0.26);
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.art.metal != art.metal ||
      old.art.shape != art.shape ||
      old.art.star != art.star ||
      old.art.label != art.label ||
      old.art.icon != art.icon ||
      old.art.ribbon != art.ribbon ||
      old.art.glow != art.glow;
}

// ── Geometría compartida ───────────────────────────────────────────────────

Path _scaled(Path path, Offset pivot, double s) => path.transform(Float64List.fromList([
      s, 0, 0, 0, //
      0, s, 0, 0, //
      0, 0, 1, 0, //
      pivot.dx * (1 - s), pivot.dy * (1 - s), 0, 1,
    ]));

Path _polar(Offset c, double Function(double angle) radius) {
  const steps = 144;
  final path = Path();
  for (var i = 0; i < steps; i++) {
    final a = i / steps * math.pi * 2;
    final p = c + Offset(math.cos(a), math.sin(a)) * radius(a);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// Estrella de [points] puntas mirando hacia arriba.
Path _star(Offset c, double outer, double inner, int points) {
  final pts = [
    for (var i = 0; i < points * 2; i++)
      c +
          Offset.fromDirection(
              -math.pi / 2 + i * math.pi / points, i.isEven ? outer : inner),
  ];
  return Path()..addPolygon(pts, true);
}

Path _roundedPolygon(Offset c, double r, int sides, {double round = 0.2}) {
  final v = [
    for (var i = 0; i < sides; i++)
      c + Offset.fromDirection(-math.pi / 2 + i * math.pi * 2 / sides, r),
  ];
  final path = Path();
  for (var i = 0; i < sides; i++) {
    final before = Offset.lerp(v[i], v[(i - 1 + sides) % sides], round)!;
    final after = Offset.lerp(v[i], v[(i + 1) % sides], round)!;
    i == 0 ? path.moveTo(before.dx, before.dy) : path.lineTo(before.dx, before.dy);
    path.quadraticBezierTo(v[i].dx, v[i].dy, after.dx, after.dy);
  }
  return path..close();
}

/// Llama con la punta arriba, inscrita en un círculo de radio [r].
Path flamePath(Offset c, double r) {
  double x(double v) => c.dx + v * r;
  double y(double v) => c.dy + v * r;
  return Path()
    ..moveTo(x(0.05), y(-1))
    ..cubicTo(x(0.10), y(-0.55), x(0.78), y(-0.25), x(0.72), y(0.35))
    ..cubicTo(x(0.68), y(0.80), x(0.30), y(1), x(0), y(1))
    ..cubicTo(x(-0.38), y(1), x(-0.74), y(0.72), x(-0.72), y(0.28))
    ..cubicTo(x(-0.71), y(0.02), x(-0.55), y(-0.15), x(-0.42), y(-0.30))
    ..cubicTo(x(-0.38), y(-0.12), x(-0.30), y(0), x(-0.18), y(0.02))
    ..cubicTo(x(-0.30), y(-0.40), x(-0.15), y(-0.78), x(0.05), y(-1))
    ..close();
}

/// Destello de cuatro puntas.
void _sparkle(Canvas canvas, Offset c, double r, {Color color = const Color(0xFFFFFFFF)}) =>
    canvas.drawPath(_star(c, r, r * 0.28, 4), Paint()..color = color);

void _glyph(Canvas canvas, String text, TextStyle style, Offset center) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  tp.dispose();
}

/// Estrellas repartidas siempre igual (misma semilla) por la zona [area].
void _stars(Canvas canvas, Rect area, int count, double maxRadius, {int seed = 7}) {
  final rnd = math.Random(seed);
  for (var i = 0; i < count; i++) {
    final p = Offset(
      area.left + rnd.nextDouble() * area.width,
      area.top + rnd.nextDouble() * area.height,
    );
    canvas.drawCircle(
      p,
      maxRadius * (0.35 + 0.65 * rnd.nextDouble()),
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 + 0.65 * rnd.nextDouble()),
    );
  }
}

/// Protector de racha: escudo iridiscente con una llama a salvo dentro.
class ShieldArt extends StatelessWidget {
  const ShieldArt({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ShieldPainter());
}

class _ShieldPainter extends CustomPainter {
  Path _shield(Size s, double inset) {
    final w = s.width;
    final h = s.height;
    double x(double v) => w * (0.5 + (v - 0.5) * (1 - inset));
    double y(double v) => h * (0.5 + (v - 0.5) * (1 - inset));
    return Path()
      ..moveTo(x(0.5), y(0.05))
      ..quadraticBezierTo(x(0.72), y(0.17), x(0.9), y(0.17))
      ..lineTo(x(0.9), y(0.48))
      ..cubicTo(x(0.9), y(0.74), x(0.7), y(0.88), x(0.5), y(0.96))
      ..cubicTo(x(0.3), y(0.88), x(0.1), y(0.74), x(0.1), y(0.48))
      ..lineTo(x(0.1), y(0.17))
      ..quadraticBezierTo(x(0.28), y(0.17), x(0.5), y(0.05))
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final outer = _shield(size, 0);
    final panel = _shield(size, 0.17);

    canvas.drawPath(
      outer,
      Paint()
        ..color = AppColors.glow
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.14),
    );
    // Canto iridiscente y escalón oscuro
    canvas.drawPath(outer, Paint()..shader = AppGradients.iridescent.createShader(rect));
    canvas.drawPath(_shield(size, 0.1), Paint()..color = const Color(0xFF2A1F6E));
    canvas.drawPath(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A3BA8), Color(0xFF1B2A55)],
        ).createShader(rect),
    );
    // Mitad derecha en sombra, como un escudo con arista central
    canvas.save();
    canvas.clipPath(panel);
    canvas.drawRect(Rect.fromLTRB(w / 2, 0, w, h), Paint()..color = const Color(0x2E000000));
    canvas.restore();

    // La llama
    final fc = Offset(w * 0.5, h * 0.49);
    final fr = w * 0.23;
    final flame = flamePath(fc, fr);
    canvas.drawPath(
      flame,
      Paint()
        ..color = AppColors.pink.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, fr * 0.35),
    );
    canvas.drawPath(
      flame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.pink, Color(0xFFFFE9FB), Color(0xFFFFFFFF)],
        ).createShader(Rect.fromCircle(center: fc, radius: fr)),
    );
    canvas.drawPath(
      flamePath(fc + Offset(-fr * 0.02, fr * 0.42), fr * 0.5),
      Paint()..color = AppColors.accentStrong,
    );

    // Reflejo lateral
    canvas.save();
    canvas.clipPath(outer);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.1, 0)
        ..lineTo(w * 0.4, 0)
        ..lineTo(w * 0.2, h)
        ..lineTo(w * 0.1, h)
        ..close(),
      Paint()..color = const Color(0x24FFFFFF),
    );
    canvas.restore();
    if (w >= 40) _sparkle(canvas, Offset(w * 0.88, h * 0.1), w * 0.08);
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => false;
}

/// Paisaje de un banner de perfil.
enum BannerScene { plain, sunrise, ocean, forest, galaxy, aurora }

/// Banner de perfil: una tarjeta apaisada con su paisaje pintado con los
/// colores del banner.
class BannerArt extends StatelessWidget {
  const BannerArt({
    super.key,
    required this.colors,
    this.scene = BannerScene.plain,
    this.width = 96,
    this.height = 56,
  });

  final List<Color> colors;
  final BannerScene scene;
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
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: CustomPaint(painter: _BannerPainter(scene, colors)),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  _BannerPainter(this.scene, this.colors);
  final BannerScene scene;
  final List<Color> colors;

  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    final a = colors.first;
    final b = colors.last;
    switch (scene) {
      case BannerScene.sunrise:
        _sunrise(canvas, size, a, b);
      case BannerScene.ocean:
        _ocean(canvas, size, a, b);
      case BannerScene.forest:
        _forest(canvas, size, a, b);
      case BannerScene.galaxy:
        _galaxy(canvas, size, a, b);
      case BannerScene.aurora:
        _aurora(canvas, size, a, b);
      case BannerScene.plain:
        _plain(canvas, size);
    }
  }

  void _sky(Canvas canvas, Size s, List<Color> sky, {bool diagonal = false}) {
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: diagonal ? Alignment.topLeft : Alignment.topCenter,
          end: diagonal ? Alignment.bottomRight : Alignment.bottomCenter,
          colors: sky,
        ).createShader(rect),
    );
  }

  /// Franja de terreno: de la curva que pasa por [ys] (alturas repartidas a lo
  /// ancho, en fracción del alto) hasta el borde inferior.
  Path _ground(Size s, List<double> ys) {
    final step = s.width / (ys.length - 1);
    final path = Path()..moveTo(0, ys.first * s.height);
    for (var i = 1; i < ys.length; i++) {
      final x0 = (i - 1) * step, x1 = i * step;
      final y0 = ys[i - 1] * s.height, y1 = ys[i] * s.height;
      path.cubicTo(x0 + step / 2, y0, x1 - step / 2, y1, x1, y1);
    }
    return path
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
  }

  void _sunrise(Canvas canvas, Size s, Color a, Color b) {
    final w = s.width, h = s.height;
    _sky(canvas, s, [
      Color.lerp(a, const Color(0xFF3A1D5C), 0.6)!,
      a,
      b,
      Color.lerp(b, _white, 0.4)!,
    ]);
    final sun = Offset(w * 0.5, h * 0.8);
    // Rayos
    for (var i = 0; i < 9; i++) {
      final angle = -math.pi + (i + 0.5) * math.pi / 9;
      canvas.drawPath(
        Path()
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(sun.dx + math.cos(angle - 0.05) * w, sun.dy + math.sin(angle - 0.05) * w)
          ..lineTo(sun.dx + math.cos(angle + 0.05) * w, sun.dy + math.sin(angle + 0.05) * w)
          ..close(),
        Paint()..color = const Color(0x1FFFFFFF),
      );
    }
    canvas.drawCircle(
      sun,
      h * 0.5,
      Paint()
        ..color = const Color(0x55FFF1C2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.16),
    );
    canvas.drawCircle(
      sun,
      h * 0.33,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBEA), Color(0xFFFFD98A)],
        ).createShader(Rect.fromCircle(center: sun, radius: h * 0.33)),
    );
    canvas.drawPath(_ground(s, const [0.80, 0.66, 0.84, 0.72]),
        Paint()..color = Color.lerp(a, const Color(0xFF2A1238), 0.6)!);
    canvas.drawPath(_ground(s, const [0.94, 0.82, 0.93, 0.86]),
        Paint()..color = Color.lerp(a, const Color(0xFF1A0B26), 0.82)!);
  }

  void _ocean(Canvas canvas, Size s, Color a, Color b) {
    final w = s.width, h = s.height;
    _sky(canvas, s, [Color.lerp(b, _white, 0.55)!, b]);
    final sun = Offset(w * 0.76, h * 0.27);
    canvas.drawCircle(
      sun,
      h * 0.24,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.1),
    );
    canvas.drawCircle(sun, h * 0.13, Paint()..color = _white);

    void wave(double base, double amp, double phase, Color color) {
      final crest = Path();
      const steps = 36;
      for (var i = 0; i <= steps; i++) {
        final x = w * i / steps;
        final y = h * base + h * amp * math.sin(i / steps * math.pi * 4 + phase);
        i == 0 ? crest.moveTo(x, y) : crest.lineTo(x, y);
      }
      canvas.drawPath(
        Path.from(crest)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = color,
      );
      canvas.drawPath(
        crest,
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.022,
      );
    }

    wave(0.52, 0.045, 0, Color.lerp(b, a, 0.4)!);
    wave(0.66, 0.055, 1.9, a);
    wave(0.82, 0.045, 3.6, Color.lerp(a, const Color(0xFF0B2A4A), 0.55)!);
  }

  void _forest(Canvas canvas, Size s, Color a, Color b) {
    final w = s.width, h = s.height;
    _sky(canvas, s, [Color.lerp(b, _white, 0.6)!, Color.lerp(b, a, 0.15)!]);
    canvas.drawCircle(Offset(w * 0.2, h * 0.28), h * 0.12, Paint()..color = const Color(0xE6FFFFFF));
    // Montañas al fondo
    canvas.drawPath(
      Path()
        ..addPolygon([
          Offset(0, h * 0.7),
          Offset(w * 0.2, h * 0.46),
          Offset(w * 0.38, h * 0.64),
          Offset(w * 0.6, h * 0.34),
          Offset(w * 0.82, h * 0.62),
          Offset(w, h * 0.48),
          Offset(w, h),
          Offset(0, h),
        ], true),
      Paint()..color = Color.lerp(a, b, 0.65)!,
    );
    // Ladera con pinos pequeños
    final mid = Color.lerp(a, b, 0.25)!;
    canvas.drawPath(_ground(s, const [0.74, 0.70, 0.76, 0.71]), Paint()..color = mid);
    const row = [0.07, 0.19, 0.3, 0.44, 0.63, 0.74, 0.9];
    for (var i = 0; i < row.length; i++) {
      _pine(canvas, Offset(w * row[i], h * 0.76), h * (i.isEven ? 0.26 : 0.2), mid);
    }
    // Primer plano
    final front = Color.lerp(a, _black, 0.4)!;
    canvas.drawPath(_ground(s, const [0.90, 0.86, 0.92, 0.88]), Paint()..color = front);
    _pine(canvas, Offset(w * 0.13, h * 0.94), h * 0.46, front);
    _pine(canvas, Offset(w * 0.54, h * 0.96), h * 0.38, front);
    _pine(canvas, Offset(w * 0.84, h * 0.95), h * 0.5, front);
  }

  void _pine(Canvas canvas, Offset base, double height, Color color) {
    final paint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromCenter(
        center: base - Offset(0, height * 0.06),
        width: height * 0.08,
        height: height * 0.12,
      ),
      paint,
    );
    for (var i = 0; i < 3; i++) {
      final bottom = base.dy - height * (0.1 + i * 0.26);
      final half = height * (0.3 - i * 0.07);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - half, bottom)
          ..lineTo(base.dx, bottom - height * 0.42)
          ..lineTo(base.dx + half, bottom)
          ..close(),
        paint,
      );
    }
  }

  void _galaxy(Canvas canvas, Size s, Color a, Color b) {
    final w = s.width, h = s.height;
    _sky(canvas, s, [Color.lerp(a, _black, 0.6)!, Color.lerp(b, _black, 0.45)!],
        diagonal: true);
    void nebula(double x, double y, double r, Color color) => canvas.drawCircle(
          Offset(w * x, h * y),
          h * r,
          Paint()
            ..color = color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.2),
        );
    nebula(0.25, 0.45, 0.4, AppColors.pink.withValues(alpha: 0.3));
    nebula(0.8, 0.75, 0.35, _cyan.withValues(alpha: 0.22));
    nebula(0.55, 0.15, 0.3, a.withValues(alpha: 0.4));
    _stars(canvas, Offset.zero & s, 30, h * 0.022);

    // Planeta con anillo: el anillo pasa por detrás y luego por delante
    final planet = Offset(w * 0.7, h * 0.46);
    final pr = h * 0.2;
    final ringRect = Rect.fromCenter(center: Offset.zero, width: pr * 3.6, height: pr * 0.9);
    final ring = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.028;
    canvas.save();
    canvas.translate(planet.dx, planet.dy);
    canvas.rotate(-0.38);
    canvas.drawOval(ringRect, ring);
    canvas.drawCircle(
      Offset.zero,
      pr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Color.lerp(b, _white, 0.7)!, b, Color.lerp(a, _black, 0.35)!],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: pr)),
    );
    canvas.drawArc(ringRect, 0, math.pi, false, ring);
    canvas.restore();

    _sparkle(canvas, Offset(w * 0.2, h * 0.26), h * 0.09);
    _sparkle(canvas, Offset(w * 0.4, h * 0.78), h * 0.055);
  }

  void _aurora(Canvas canvas, Size s, Color a, Color b) {
    final w = s.width, h = s.height;
    _sky(canvas, s, [const Color(0xFF050B1F), Color.lerp(b, _black, 0.62)!]);
    _stars(canvas, Rect.fromLTWH(0, 0, w, h * 0.6), 20, h * 0.02, seed: 11);

    // Cortinas: brillan por el borde inferior y se apagan hacia arriba
    void curtain(double base, double amp, double freq, double phase, double tall, Color color) {
      const steps = 36;
      double edge(int i) =>
          h * base + h * amp * math.sin(i / steps * math.pi * 2 * freq + phase);
      final path = Path()..moveTo(0, edge(0));
      for (var i = 1; i <= steps; i++) {
        path.lineTo(w * i / steps, edge(i));
      }
      for (var i = steps; i >= 0; i--) {
        path.lineTo(w * i / steps, edge(i) - h * tall);
      }
      path.close();
      final top = h * (base - amp - tall);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.9)],
          ).createShader(Rect.fromLTRB(0, top, w, h * (base + amp)))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.03),
      );
    }

    curtain(0.50, 0.07, 1.4, 2.0, 0.40, Color.lerp(a, b, 0.55)!);
    curtain(0.60, 0.08, 1.0, 0.0, 0.46, a);
    curtain(0.68, 0.05, 0.8, 4.0, 0.30, b);

    canvas.drawPath(
      Path()
        ..addPolygon([
          Offset(0, h * 0.88),
          Offset(w * 0.14, h * 0.72),
          Offset(w * 0.26, h * 0.84),
          Offset(w * 0.42, h * 0.64),
          Offset(w * 0.56, h * 0.82),
          Offset(w * 0.7, h * 0.7),
          Offset(w * 0.86, h * 0.86),
          Offset(w, h * 0.76),
          Offset(w, h),
          Offset(0, h),
        ], true),
      Paint()..color = const Color(0xFF070A18),
    );
  }

  void _plain(Canvas canvas, Size s) {
    _sky(canvas, s, colors, diagonal: true);
    canvas.drawCircle(Offset(s.width * 0.92, s.height * 0.05), s.height * 0.6,
        Paint()..color = const Color(0x24FFFFFF));
    canvas.drawCircle(Offset(s.width * 0.05, s.height * 1.05), s.height * 0.5,
        Paint()..color = const Color(0x1F000000));
    // Brillo diagonal
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.30, 0)
        ..lineTo(s.width * 0.44, 0)
        ..lineTo(s.width * 0.24, s.height)
        ..lineTo(s.width * 0.10, s.height)
        ..close(),
      Paint()..color = const Color(0x1FFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_BannerPainter old) => old.scene != scene || old.colors != colors;
}
