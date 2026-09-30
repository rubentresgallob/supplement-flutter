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

  const Capsu({
    super.key,
    this.size = 120,
    this.mood = CapsuMood.idle,
    this.lookAt = Offset.zero,
    this.interactive = true,
    this.onTap,
    this.semanticLabel,
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

  _CapsuPainter({
    required this.pose,
    required this.t,
    required this.blink,
    required this.gaze,
  });

  static const _ink = Color(0xFF171717);
  static const _orange = Color(0xFFFF6B35);
  static const _orangeDark = Color(0xFFD9480F);

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
    final feet = Paint()..color = _orangeDark;
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
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF7A45), Color(0xFFF0541A)],
        ).createShader(Rect.fromLTRB(left, mid, right, bottom)),
    );
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
        ..color = _orangeDark,
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
