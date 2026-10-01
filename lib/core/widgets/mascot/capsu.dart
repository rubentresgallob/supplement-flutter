import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../theme/app_tokens.dart';

/// Estados de ánimo de Capsu.
enum CapsuMood {
  idle, // tranquilo, respira y parpadea
  wave, // saluda con la mano
  happy, // contento, ojos ^ ^ y saltitos
  celebrate, // celebración a tope
  sad, // triste (errores)
  shy, // se tapa los ojos (contraseña oculta)
  peek, // espía entre los dedos (contraseña visible)
  thinking, // concentrado / cargando
  surprised, // sorprendido
}

/// Accesorios que lleva Capsu (se compran en la tienda).
/// Cada campo es el código de un objeto del catálogo del backend.
@immutable
class CapsuOutfit {
  final String? head;
  final String? face;
  final String? neck;
  final String? skin;

  const CapsuOutfit({this.head, this.face, this.neck, this.skin});

  static const none = CapsuOutfit();

  /// A partir de los objetos equipados (slot → código) que devuelve el backend.
  factory CapsuOutfit.fromEquipped(Map<String, String> equipped) => CapsuOutfit(
        head: equipped['capsu_head'],
        face: equipped['capsu_face'],
        neck: equipped['capsu_neck'],
        skin: equipped['capsu_skin'],
      );

  /// Copia cambiando un slot (para "probarse" un objeto en la tienda).
  CapsuOutfit withSlot(String slot, String? code) => CapsuOutfit(
        head: slot == 'capsu_head' ? code : head,
        face: slot == 'capsu_face' ? code : face,
        neck: slot == 'capsu_neck' ? code : neck,
        skin: slot == 'capsu_skin' ? code : skin,
      );

  @override
  bool operator ==(Object other) =>
      other is CapsuOutfit &&
      other.head == head &&
      other.face == face &&
      other.neck == neck &&
      other.skin == skin;

  @override
  int get hashCode => Object.hash(head, face, neck, skin);
}

/// Capsu: la mascota de la app. Una cápsula mitad blanca y mitad naranja,
/// dibujada 100% en código (sin assets) y animada en tiempo real.
///
/// ```dart
/// Capsu(size: 120, mood: CapsuMood.wave, lookAt: const Offset(0.5, 0.8))
/// ```
class Capsu extends StatefulWidget {
  /// Ancho del personaje. El alto es `size * 1.3`.
  final double size;
  final CapsuMood mood;

  /// Hacia dónde mira, en rango -1..1 (x: izquierda→derecha, y: arriba→abajo).
  final Offset lookAt;

  /// Si es true, al tocarlo da un saltito de alegría.
  final bool interactive;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Accesorios equipados (gorra, gafas, bufanda, color...).
  final CapsuOutfit outfit;

  const Capsu({
    super.key,
    this.size = 120,
    this.mood = CapsuMood.idle,
    this.lookAt = Offset.zero,
    this.interactive = true,
    this.onTap,
    this.semanticLabel,
    this.outfit = CapsuOutfit.none,
  });

  @override
  State<Capsu> createState() => _CapsuState();
}

class _CapsuState extends State<Capsu> with TickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);
  Offset _gaze = Offset.zero;

  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..value = 1;
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );

  late _Pose _from = _Pose.of(widget.mood);
  late _Pose _to = _from;
  CapsuMood? _boopMood;
  Timer? _blinkTimer;
  Timer? _boopTimer;
  bool _reduced = false;

  _Pose get _pose =>
      _Pose.lerp(_from, _to, Curves.easeOutBack.transform(_transition.value));

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _time.value = elapsed.inMicroseconds / 1e6;
      // Suavizado de la mirada (sigue el objetivo con inercia)
      _gaze = Offset.lerp(_gaze, widget.lookAt, 0.14)!;
    });
    _scheduleBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = AppMotion.reduced(context);
    if (_reduced) {
      _ticker.stop();
      _gaze = widget.lookAt;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(Capsu old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood && _boopMood == null) _goTo(widget.mood);
    if (_reduced) _gaze = widget.lookAt;
  }

  void _goTo(CapsuMood mood) {
    _from = _pose;
    _to = _Pose.of(mood);
    if (_reduced) {
      _transition.value = 1;
    } else {
      _transition.forward(from: 0);
    }
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    final wait = 2200 + math.Random().nextInt(3200);
    _blinkTimer = Timer(Duration(milliseconds: wait), () async {
      if (!mounted) return;
      if (!_reduced) {
        await _blink.forward(from: 0);
        if (mounted) await _blink.reverse();
      }
      if (mounted) _scheduleBlink();
    });
  }

  void _handleTap() {
    widget.onTap?.call();
    if (!widget.interactive) return;
    HapticFeedback.lightImpact();
    _boopTimer?.cancel();
    _boopMood = CapsuMood.happy;
    _goTo(CapsuMood.happy);
    _boopTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      _boopMood = null;
      _goTo(widget.mood);
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _boopTimer?.cancel();
    _ticker.dispose();
    _transition.dispose();
    _blink.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = AnimatedBuilder(
      animation: Listenable.merge([_time, _transition, _blink]),
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size * 1.3),
        painter: _CapsuPainter(
          pose: _pose,
          t: _time.value,
          blink: _blink.value,
          gaze: _gaze,
          outfit: widget.outfit,
        ),
      ),
    );

    return Semantics(
      image: true,
      label: widget.semanticLabel ?? 'Capsu, la mascota de la app',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: (widget.interactive || widget.onTap != null) ? _handleTap : null,
          child: RepaintBoundary(child: painter),
        ),
      ),
    );
  }
}

// ─── Pose: todos los parámetros animables del personaje ─────────────────────

@immutable
class _Pose {
  final double eyeOpen; // 0 cerrado · 1 normal · >1 sorprendido
  final double eyeHappy; // 0 normales · 1 ojos ^ ^
  final double mouthCurve; // -1 triste · 1 sonrisa
  final double mouthOpen; // 0 cerrada · 1 muy abierta
  final double blush;
  final double leftArm; // rad: 0 colgando · π arriba
  final double rightArm;
  final double handsOnEyes; // 0..1
  final double peek; // 0..1 baja una mano para espiar
  final double tilt; // rad
  final double gazeY; // mirada base -1..1
  final double bounce; // saltos continuos 0..1
  final double wave; // saludo brazo derecho 0..1

  const _Pose({
    this.eyeOpen = 1,
    this.eyeHappy = 0,
    this.mouthCurve = 0.7,
    this.mouthOpen = 0,
    this.blush = 0.45,
    this.leftArm = 0.35,
    this.rightArm = 0.35,
    this.handsOnEyes = 0,
    this.peek = 0,
    this.tilt = 0,
    this.gazeY = 0,
    this.bounce = 0,
    this.wave = 0,
  });

  static _Pose of(CapsuMood mood) => switch (mood) {
        CapsuMood.idle => const _Pose(),
        CapsuMood.wave => const _Pose(
            mouthCurve: 0.9, mouthOpen: 0.35, blush: 0.6,
            rightArm: 2.6, wave: 1, tilt: 0.04),
        CapsuMood.happy => const _Pose(
            eyeHappy: 1, mouthCurve: 1, mouthOpen: 0.55, blush: 0.9,
            leftArm: 2.2, rightArm: 2.2, bounce: 0.6),
        CapsuMood.celebrate => const _Pose(
            eyeHappy: 1, mouthCurve: 1, mouthOpen: 0.85, blush: 1,
            leftArm: 2.7, rightArm: 2.7, bounce: 1, wave: 0.5),
        CapsuMood.sad => const _Pose(
            eyeOpen: 0.6, mouthCurve: -0.8, blush: 0,
            leftArm: 0.1, rightArm: 0.1, tilt: -0.06, gazeY: 0.8),
        CapsuMood.shy => const _Pose(
            eyeOpen: 0.2, mouthCurve: 0.35, mouthOpen: 0.1, blush: 1,
            handsOnEyes: 1),
        CapsuMood.peek => const _Pose(
            eyeOpen: 1.1, mouthCurve: 0.2, mouthOpen: 0.3, blush: 0.9,
            handsOnEyes: 1, peek: 1, gazeY: 0.3),
        CapsuMood.thinking => const _Pose(
            mouthCurve: 0.1, mouthOpen: 0.12, blush: 0.3,
            rightArm: 0.7, tilt: 0.05, gazeY: -0.5),
        CapsuMood.surprised => const _Pose(
            eyeOpen: 1.25, mouthCurve: 0, mouthOpen: 1, blush: 0.3,
            leftArm: 1.3, rightArm: 1.3),
      };

  static _Pose lerp(_Pose a, _Pose b, double t) {
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return _Pose(
      eyeOpen: l(a.eyeOpen, b.eyeOpen),
      eyeHappy: l(a.eyeHappy, b.eyeHappy).clamp(0, 1),
      mouthCurve: l(a.mouthCurve, b.mouthCurve),
      mouthOpen: l(a.mouthOpen, b.mouthOpen).clamp(0, 1.2),
      blush: l(a.blush, b.blush).clamp(0, 1),
      leftArm: l(a.leftArm, b.leftArm),
      rightArm: l(a.rightArm, b.rightArm),
      handsOnEyes: l(a.handsOnEyes, b.handsOnEyes),
      peek: l(a.peek, b.peek),
      tilt: l(a.tilt, b.tilt),
      gazeY: l(a.gazeY, b.gazeY),
      bounce: l(a.bounce, b.bounce).clamp(0, 1),
      wave: l(a.wave, b.wave).clamp(0, 1),
    );
  }
}

// ─── Painter ────────────────────────────────────────────────────────────────

class _CapsuPainter extends CustomPainter {
  final _Pose pose;
  final double t;
  final double blink;
  final Offset gaze;
  final CapsuOutfit outfit;

  _CapsuPainter({
    required this.pose,
    required this.t,
    required this.blink,
    required this.gaze,
    this.outfit = CapsuOutfit.none,
  });

  static const _ink = Color(0xFF171717);
  static const _orange = Color(0xFFFF6B35);

  /// Colores de la mitad de color (degradado + tono oscuro de pies y brazos).
  ({Color light, Color dark, Color shade}) get _skin => switch (outfit.skin) {
        'capsu_skin_mint' => (
            light: const Color(0xFF6EE0B4),
            dark: const Color(0xFF2FA67A),
            shade: const Color(0xFF23805E),
          ),
        'capsu_skin_galaxy' => (
            light: const Color(0xFF8F94FB),
            dark: const Color(0xFF4E54C8),
            shade: const Color(0xFF363A9E),
          ),
        'capsu_skin_gold' => (
            light: const Color(0xFFFFDC5E),
            dark: const Color(0xFFF2A100),
            shade: const Color(0xFFC77F00),
          ),
        _ => (
            light: const Color(0xFFFF7A45),
            dark: const Color(0xFFF0541A),
            shade: const Color(0xFFD9480F),
          ),
      };

  @override
  void paint(Canvas canvas, Size size) {
    // Todo se dibuja en una caja virtual de 100 x 130
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);

    const tau = math.pi * 2;
    final breath = math.sin(t * tau / 2.6);
    final phase = (t * 1.8) % 1;
    final jump = pose.bounce * math.sin(phase * math.pi) * 12;
    final stretch = 0.02 * breath - pose.bounce * 0.07 * math.cos(phase * tau);
    final sway = 0.02 * math.sin(t * tau / 3.2);

    final w = 52 * (1 - stretch);
    final h = 84 * (1 + stretch);
    final bottom = 116 - jump;
    final top = bottom - h;
    final left = 50 - w / 2;
    final right = 50 + w / 2;
    final mid = top + h * 0.5;

    // Sombra en el suelo
    final shadowScale = 1 - jump / 30;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 121), width: 46 * shadowScale, height: 7),
      Paint()..color = Colors.black.withValues(alpha: 0.35 * shadowScale),
    );

    canvas.save();
    canvas.translate(50, bottom);
    canvas.rotate(pose.tilt + sway);
    canvas.translate(-50, -bottom);

    // Pies
    final skin = _skin;
    final feet = Paint()..color = skin.shade;
    for (final dx in [-10.0, 10.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(50 + dx, bottom + 0.5), width: 14, height: 7.5),
        feet,
      );
    }

    // Cuerpo (cápsula)
    final body = RRect.fromLTRBR(left, top, right, bottom, Radius.circular(w / 2));
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, mid),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFE8E8E8)],
        ).createShader(Rect.fromLTRB(left, top, right, mid)),
    );
    canvas.drawRect(
      Rect.fromLTRB(left, mid, right, bottom),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skin.light, skin.dark],
        ).createShader(Rect.fromLTRB(left, mid, right, bottom)),
    );
    // Capsu galaxia: estrellitas que titilan en la mitad de color
    if (outfit.skin == 'capsu_skin_galaxy') {
      const stars = [
        Offset(0.22, 0.18), Offset(0.62, 0.12), Offset(0.40, 0.42),
        Offset(0.78, 0.36), Offset(0.28, 0.68), Offset(0.66, 0.62), Offset(0.50, 0.85),
      ];
      for (var i = 0; i < stars.length; i++) {
        final twinkle = (math.sin(t * 3 + i * 1.3) + 1) / 2;
        canvas.drawCircle(
          Offset(left + w * stars[i].dx, mid + (bottom - mid) * stars[i].dy),
          0.7 + 0.9 * twinkle,
          Paint()..color = Colors.white.withValues(alpha: 0.45 + 0.5 * twinkle),
        );
      }
    }
    // Volumen: sombra lateral derecha
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.14)],
          stops: const [0.6, 1],
        ).createShader(Rect.fromLTRB(left, top, right, bottom)),
    );
    // Brillo en la mitad naranja
    canvas.drawRRect(
      RRect.fromLTRBR(left + w * 0.16, mid + h * 0.08, left + w * 0.27,
          mid + h * 0.34, const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    // Junta entre las dos mitades
    canvas.drawLine(Offset(left, mid), Offset(right, mid),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.14)
          ..strokeWidth = 1.4);
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withValues(alpha: 0.18),
    );

    // Cara
    final faceY = top + h * 0.30;
    final gx = gaze.dx.clamp(-1.0, 1.0);
    final gy = (pose.gazeY + gaze.dy).clamp(-1.0, 1.0);
    _drawFace(canvas, faceY, gx, gy);

    // Accesorios (por debajo de los brazos para que las manos queden delante)
    _drawNeck(canvas, body, left, right, mid);
    _drawFaceWear(canvas, faceY, gx, gy);
    _drawHead(canvas, body, top, right);

    // Brazos y manos (por delante de la cara para poder taparse los ojos)
    final armY = top + h * 0.56;
    final waveOsc = math.sin(t * tau * 2.2);
    final leftAngle = pose.leftArm + pose.bounce * 0.3 * math.sin(t * tau * 1.8 + math.pi);
    final rightAngle = pose.rightArm + pose.wave * 0.35 * waveOsc;
    final eyeL = Offset(39, faceY + 1);
    final eyeR = Offset(61, faceY + 1);
    final peekL = Offset(33, faceY + 16);
    _drawArm(canvas, Offset(left + 1.5, armY), leftAngle, -1,
        Offset.lerp(eyeL, peekL, pose.peek)!);
    _drawArm(canvas, Offset(right - 1.5, armY), rightAngle, 1, eyeR);

    canvas.restore();

    // Destellos de celebración
    if (pose.bounce > 0.5) _drawSparkles(canvas, (pose.bounce - 0.5) * 2);

    canvas.restore();
  }

  void _drawFace(Canvas canvas, double faceY, double gx, double gy) {
    final open = (pose.eyeOpen * (1 - blink)).clamp(0.0, 1.4);
    final ink = Paint()..color = _ink.withValues(alpha: 1 - pose.eyeHappy);

    for (final side in [-1.0, 1.0]) {
      final ex = 50 + side * 11.5 + gx * 3;
      final ey = faceY + gy * 2.5;

      // Ojos normales
      if (pose.eyeHappy < 1) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(ex, ey), width: 9.5, height: math.max(1.4, 12.5 * open)),
          ink,
        );
        if (open > 0.4) {
          canvas.drawCircle(
            Offset(ex - 1.8 + gx * 0.8, ey - 3 * open),
            2.1,
            Paint()..color = Colors.white.withValues(alpha: 1 - pose.eyeHappy),
          );
        }
      }
      // Ojos felices ^ ^
      if (pose.eyeHappy > 0) {
        final p = Path()
          ..moveTo(ex - 4.5, ey + 1.5)
          ..quadraticBezierTo(ex, ey - 5, ex + 4.5, ey + 1.5);
        canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round
            ..color = _ink.withValues(alpha: pose.eyeHappy),
        );
      }
      // Coloretes
      if (pose.blush > 0) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(50 + side * 19, faceY + 7.5), width: 8, height: 4.5),
          Paint()..color = const Color(0xFFFF8FA3).withValues(alpha: 0.55 * pose.blush),
        );
      }
    }

    // Boca
    final mx = 50 + gx * 1.5;
    final my = faceY + 10 + gy * 1;
    final mw = 10 - pose.mouthOpen * 1.5;
    final c = pose.mouthCurve;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _ink;

    if (pose.mouthOpen > 0.05) {
      final mouth = Path()
        ..moveTo(mx - mw / 2, my)
        ..quadraticBezierTo(mx, my + 5 * c * 0.4, mx + mw / 2, my)
        ..quadraticBezierTo(mx, my + 5 * c * 0.4 + 11 * pose.mouthOpen, mx - mw / 2, my)
        ..close();
      canvas.drawPath(mouth, Paint()..color = const Color(0xFF3B1206));
      canvas.save();
      canvas.clipPath(mouth);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(mx, my + 7 * pose.mouthOpen + 2),
            width: 7,
            height: 5 * pose.mouthOpen + 1),
        Paint()..color = const Color(0xFFFF7B8A),
      );
      canvas.restore();
      canvas.drawPath(mouth, line);
    } else {
      final p = Path()
        ..moveTo(mx - mw / 2, my)
        ..quadraticBezierTo(mx, my + 5 * c, mx + mw / 2, my);
      canvas.drawPath(p, line);
    }
  }

  // ─── Accesorios ───────────────────────────────────────────────────────────

  void _drawHead(Canvas canvas, RRect body, double top, double right) {
    switch (outfit.head) {
      case 'capsu_head_halo':
        // Aureola flotando que sube y baja un poco
        final y = top - 9 + 1.5 * math.sin(t * 2.4);
        final halo = Rect.fromCenter(center: Offset(50, y), width: 30, height: 8);
        canvas.drawOval(
          halo.inflate(2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = const Color(0xFFFFE27A).withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawOval(
          halo,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6
            ..color = const Color(0xFFFFD54A),
        );
      case 'capsu_head_cap':
        canvas.save();
        canvas.clipRRect(body);
        canvas.drawRect(Rect.fromLTRB(0, top - 2, 100, top + 13),
            Paint()..color = const Color(0xFF2563EB));
        canvas.drawLine(Offset(50, top), Offset(50, top + 13),
            Paint()
              ..color = Colors.black.withValues(alpha: 0.18)
              ..strokeWidth = 1);
        canvas.restore();
        // Visera
        canvas.drawRRect(
          RRect.fromLTRBR(46, top + 10, right + 13, top + 15.5,
              const Radius.circular(3)),
          Paint()..color = const Color(0xFF1D4ED8),
        );
        canvas.drawCircle(Offset(50, top + 0.5), 2.2,
            Paint()..color = const Color(0xFF1E40AF));
      case 'capsu_head_party':
        final hat = Path()
          ..moveTo(39, top + 7)
          ..lineTo(61, top + 7)
          ..lineTo(53, top - 20)
          ..close();
        canvas.drawPath(hat, Paint()..color = const Color(0xFFEC4899));
        canvas.save();
        canvas.clipPath(hat);
        final stripe = Paint()
          ..color = const Color(0xFFFDE047)
          ..strokeWidth = 3;
        for (var y = top - 16; y < top + 8; y += 7) {
          canvas.drawLine(Offset(30, y + 6), Offset(70, y - 4), stripe);
        }
        canvas.restore();
        canvas.drawCircle(Offset(53, top - 21), 3.6, Paint()..color = Colors.white);
      case 'capsu_head_crown':
        final crown = Path()
          ..moveTo(36, top + 5)
          ..lineTo(36, top - 8)
          ..lineTo(43, top - 1)
          ..lineTo(50, top - 13)
          ..lineTo(57, top - 1)
          ..lineTo(64, top - 8)
          ..lineTo(64, top + 5)
          ..close();
        canvas.drawPath(
          crown,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE27A), Color(0xFFF2A100)],
            ).createShader(Rect.fromLTRB(36, top - 13, 64, top + 5)),
        );
        canvas.drawPath(
          crown,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFFB45309),
        );
        canvas.drawCircle(Offset(50, top), 2.4, Paint()..color = const Color(0xFFE11D48));
        for (final x in [41.0, 59.0]) {
          canvas.drawCircle(Offset(x, top + 1.5), 1.6,
              Paint()..color = const Color(0xFF38BDF8));
        }
    }
  }

  void _drawFaceWear(Canvas canvas, double faceY, double gx, double gy) {
    final ey = faceY + gy * 2.5;
    final lx = 50 - 11.5 + gx * 3;
    final rx = 50 + 11.5 + gx * 3;
    switch (outfit.face) {
      case 'capsu_face_sunglasses':
        final lens = Paint()..color = const Color(0xF0101010);
        for (final x in [lx, rx]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(x, ey), width: 16, height: 10.5),
                const Radius.circular(4)),
            lens,
          );
          // Brillo del cristal
          canvas.drawLine(Offset(x - 5, ey - 2.5), Offset(x - 2, ey - 2.5),
              Paint()
                ..color = Colors.white.withValues(alpha: 0.55)
                ..strokeWidth = 1.4
                ..strokeCap = StrokeCap.round);
        }
        canvas.drawLine(Offset(lx + 8, ey - 2), Offset(rx - 8, ey - 2),
            Paint()
              ..color = const Color(0xFF101010)
              ..strokeWidth = 2);
      case 'capsu_face_glasses':
        final frame = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = const Color(0xFF5B3A1E);
        for (final x in [lx, rx]) {
          canvas.drawCircle(Offset(x, ey), 7.8, Paint()..color = const Color(0x2260A5FA));
          canvas.drawCircle(Offset(x, ey), 7.8, frame);
        }
        canvas.drawLine(Offset(lx + 7.8, ey), Offset(rx - 7.8, ey), frame);
    }
  }

  void _drawNeck(Canvas canvas, RRect body, double left, double right, double mid) {
    switch (outfit.neck) {
      case 'capsu_neck_scarf':
        const red = Color(0xFFDC2626);
        final stripe = Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..strokeWidth = 1.2;
        canvas.save();
        canvas.clipRRect(body);
        canvas.drawRect(Rect.fromLTRB(left, mid - 1, right, mid + 7), Paint()..color = red);
        canvas.drawLine(Offset(left, mid + 1.5), Offset(right, mid + 1.5), stripe);
        canvas.drawLine(Offset(left, mid + 4.5), Offset(right, mid + 4.5), stripe);
        canvas.restore();
        // Punta colgando que se balancea
        canvas.save();
        canvas.translate(right - 12, mid + 5);
        canvas.rotate(0.18 + 0.05 * math.sin(t * 3));
        canvas.drawRRect(
          RRect.fromLTRBR(-3.5, 0, 3.5, 17, const Radius.circular(2)),
          Paint()..color = red,
        );
        canvas.drawLine(const Offset(-3.5, 14), const Offset(3.5, 14), stripe);
        canvas.restore();
      case 'capsu_neck_medal':
        final ribbon = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF2563EB);
        canvas.drawLine(Offset(42, mid - 2), Offset(50, mid + 10), ribbon);
        canvas.drawLine(Offset(58, mid - 2), Offset(50, mid + 10), ribbon);
        final center = Offset(50, mid + 15);
        canvas.drawCircle(center, 5.5, Paint()..color = const Color(0xFFFAB437));
        canvas.drawCircle(
          center,
          5.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = const Color(0xFFB45309),
        );
        canvas.drawCircle(center, 2.2, Paint()..color = const Color(0xFFFFE27A));
    }
  }

  void _drawArm(Canvas canvas, Offset shoulder, double angle, double side, Offset eyeTarget) {
    const len = 17.0;
    final rest = shoulder + Offset(side * len * math.sin(angle), len * math.cos(angle));
    final hand = Offset.lerp(rest, eyeTarget, pose.handsOnEyes.clamp(0.0, 1.1))!;
    final midPt = Offset.lerp(shoulder, hand, 0.5)!;
    final ctrl = midPt + Offset(side * 5, 0);

    canvas.drawPath(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, hand.dx, hand.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..color = _skin.shade,
    );
    final handR = 5.4 + 1.2 * pose.handsOnEyes.clamp(0.0, 1.0);
    canvas.drawCircle(hand, handR, Paint()..color = const Color(0xFFFAFAFA));
    canvas.drawCircle(
      hand,
      handR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withValues(alpha: 0.3),
    );
  }

  void _drawSparkles(Canvas canvas, double intensity) {
    const spots = [Offset(12, 30), Offset(88, 22), Offset(84, 70), Offset(16, 78)];
    for (var i = 0; i < spots.length; i++) {
      final k = (math.sin(t * 6 + i * 1.7) + 1) / 2;
      final r = 2.5 + 3 * k;
      final p = spots[i];
      final star = Path()
        ..moveTo(p.dx, p.dy - r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
        ..close();
      canvas.drawPath(
        star,
        Paint()..color = (i.isEven ? _orange : const Color(0xFFFAB437))
            .withValues(alpha: intensity * (0.4 + 0.6 * k)),
      );
    }
  }

  @override
  bool shouldRepaint(_CapsuPainter old) => true;
}

// ─── Bocadillo de diálogo ───────────────────────────────────────────────────

/// Bocadillo con efecto "máquina de escribir" para que Capsu hable.
class CapsuBubble extends StatefulWidget {
  final String text;
  final double maxWidth;

  const CapsuBubble({super.key, required this.text, this.maxWidth = 260});

  @override
  State<CapsuBubble> createState() => _CapsuBubbleState();
}

class _CapsuBubbleState extends State<CapsuBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _type = AnimationController(vsync: this);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery no se puede leer en initState: arrancamos aquí la primera vez
    if (!_started) {
      _started = true;
      _start();
    }
  }

  @override
  void didUpdateWidget(CapsuBubble old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _type.duration = Duration(milliseconds: 18 * widget.text.characters.length + 60);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _type.value = 1;
    } else {
      _type.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chars = widget.text.characters;
    return Semantics(
      liveRegion: true,
      label: widget.text,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                  boxShadow: AppShadows.md,
                ),
                child: AnimatedBuilder(
                  animation: _type,
                  builder: (context, _) {
                    final n = (chars.length * _type.value).round();
                    return Stack(
                      children: [
                        // Texto completo invisible: fija el tamaño y evita saltos
                        Opacity(opacity: 0, child: Text(widget.text, style: _style)),
                        Text(chars.take(n).toString(), style: _style),
                      ],
                    );
                  },
                ),
              ),
              CustomPaint(size: const Size(16, 8), painter: _TailPainter()),
            ],
          ),
        ),
      ),
    );
  }

  static const _style = TextStyle(
    color: Color(0xFFF5F5F5),
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, -1)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, -1)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFF1F1F1F));
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2E2E2E),
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}
