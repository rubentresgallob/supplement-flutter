import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';

/// Tutorial inicial guiado por Capsu. Se muestra la primera vez que el
/// usuario entra y puede repetirse desde Perfil.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _Step {
  final CapsuMood mood;
  final String speech;
  final String title;
  final String description;
  const _Step(this.mood, this.speech, this.title, this.description);
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = [
    _Step(
      CapsuMood.wave,
      '¡Hola! Soy Capsu 👋',
      'Tu compañero de suplementación',
      'Te ayudo a no olvidar ninguna toma y a ser constante día tras día.',
    ),
    _Step(
      CapsuMood.thinking,
      'Toca el + para probarlo 👇',
      'Añade tu stack',
      'Pulsa el botón + y elige entre más de 30 suplementos del catálogo, o crea uno personalizado.',
    ),
    _Step(
      CapsuMood.idle,
      'Toca el círculo 👇',
      'Registra cada toma',
      'Toca el círculo de cada suplemento al tomarlo. Si lo tomas varias veces al día, cada toque suma.',
    ),
    _Step(
      CapsuMood.celebrate,
      '¡A por la racha! 🔥',
      'Mantén tu racha',
      'Completa tu stack cada día para subir tu racha y compárate con tus amigos.',
    ),
  ];

  final _pageCtrl = PageController();
  int _page = 0;
  CapsuMood? _reaction;
  String? _speechOverride;
  Timer? _reactionTimer;

  bool get _isLast => _page == _steps.length - 1;

  void _react(CapsuMood mood, String speech) {
    _reactionTimer?.cancel();
    setState(() {
      _reaction = mood;
      _speechOverride = speech;
    });
    _reactionTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _reaction = null);
    });
  }

  void _next() {
    if (_isLast) {
      HapticFeedback.mediumImpact();
      widget.onDone();
      return;
    }
    _pageCtrl.nextPage(
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.standard,
    );
  }

  @override
  void dispose() {
    _reactionTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_page];
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    '${_page + 1} de ${_steps.length}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: _isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: _isLast ? null : widget.onDone,
                      child: const Text(
                        'Saltar',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Capsu + bocadillo
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CapsuBubble(text: _speechOverride ?? step.speech),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -14),
              child: Capsu(
                size: 104,
                mood: _reaction ?? step.mood,
                lookAt: _page == 2 ? const Offset(0, 0.9) : Offset.zero,
              ),
            ),

            // Pasos
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() {
                  _page = i;
                  _speechOverride = null;
                  _reaction = null;
                }),
                children: [
                  _StepView(step: _steps[0], illustration: const _FeaturesDemo()),
                  _StepView(
                    step: _steps[1],
                    illustration: _AddDemo(
                      onAdded: () => _react(CapsuMood.happy, '¡Genial! Así de fácil 🙌'),
                    ),
                  ),
                  _StepView(
                    step: _steps[2],
                    illustration: _IntakeDemo(
                      onProgress: () => _react(CapsuMood.happy, '¡Una más! 💪'),
                      onComplete: () =>
                          _react(CapsuMood.celebrate, '¡Omega 3 completado! 🎉'),
                    ),
                  ),
                  _StepView(step: _steps[3], illustration: const _StreakDemo()),
                ],
              ),
            ),

            // Indicador + botón
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        AnimatedContainer(
                          duration: AppMotion.of(context, AppMotion.base),
                          curve: AppMotion.standard,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page ? AppColors.primary : AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: _isLast ? '¡Empezar!' : 'Siguiente',
                    icon: _isLast ? LucideIcons.flame : null,
                    size: AppButtonSize.lg,
                    expand: true,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  final _Step step;
  final Widget illustration;
  const _StepView({required this.step, required this.illustration});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          illustration,
        ],
      ),
    );
  }
}

// ─── Demos de cada paso ─────────────────────────────────────────────────────

class _FeaturesDemo extends StatelessWidget {
  const _FeaturesDemo();

  @override
  Widget build(BuildContext context) {
    const items = [
      (LucideIcons.bell, 'Recordatorios a tu hora'),
      (LucideIcons.flame, 'Rachas diarias'),
      (LucideIcons.usersRound, 'Reta a tus amigos'),
    ];
    return Column(
      children: [
        for (final (icon, label) in items)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: AppDecorations.frame(radius: AppRadius.xl),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
      ],
    );
  }
}

class _MockTile extends StatelessWidget {
  final String name;
  final String detail;
  final Widget? trailing;
  const _MockTile({required this.name, required this.detail, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.frame(radius: AppRadius.xl),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(LucideIcons.pill, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Paso 2: el usuario toca + y aparece un suplemento nuevo.
class _AddDemo extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddDemo({required this.onAdded});

  @override
  State<_AddDemo> createState() => _AddDemoState();
}

class _AddDemoState extends State<_AddDemo> {
  bool _added = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MockTile(name: 'Creatina', detail: '5 g · 1× al día'),
        AnimatedSize(
          duration: AppMotion.of(context, AppMotion.slow),
          curve: AppMotion.standard,
          child: _added
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: AppMotion.of(context, AppMotion.slow),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Opacity(
                    opacity: v.clamp(0, 1),
                    child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
                  ),
                  child: const _MockTile(name: 'Magnesio', detail: '400 mg · 1× al día'),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'Añadir suplemento de ejemplo',
          child: GestureDetector(
            onTap: _added
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    setState(() => _added = true);
                    widget.onAdded();
                  },
            child: AnimatedOpacity(
              duration: AppMotion.fast,
              opacity: _added ? 0.4 : 1,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.md,
                ),
                child: Icon(_added ? LucideIcons.check : LucideIcons.plus,
                    color: AppColors.onPrimary, size: 26),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paso 3: el usuario registra dos tomas de Omega 3.
class _IntakeDemo extends StatefulWidget {
  final VoidCallback onProgress;
  final VoidCallback onComplete;
  const _IntakeDemo({required this.onProgress, required this.onComplete});

  @override
  State<_IntakeDemo> createState() => _IntakeDemoState();
}

class _IntakeDemoState extends State<_IntakeDemo> {
  static const _total = 2;
  int _taken = 0;

  void _tap() {
    if (_taken >= _total) return;
    HapticFeedback.lightImpact();
    setState(() => _taken++);
    _taken >= _total ? widget.onComplete() : widget.onProgress();
  }

  @override
  Widget build(BuildContext context) {
    final done = _taken >= _total;
    return _MockTile(
      name: 'Omega 3',
      detail: '2 cápsulas · 2× al día',
      trailing: Semantics(
        button: true,
        label: 'Registrar toma, $_taken de $_total',
        child: GestureDetector(
          onTap: _tap,
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.base),
            curve: AppMotion.standard,
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.success : Colors.transparent,
              border: Border.all(
                color: done
                    ? AppColors.success
                    : _taken > 0
                        ? AppColors.primary
                        : AppColors.textMuted,
                width: 2,
              ),
            ),
            child: Center(
              child: done
                  ? const Icon(LucideIcons.check, color: AppColors.onPrimary, size: 22)
                  : Text(
                      '$_taken/$_total',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paso 4: la racha sube y se rellena la semana.
class _StreakDemo extends StatelessWidget {
  const _StreakDemo();

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.frame(radius: AppRadius.xxl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.flame, color: AppColors.accent, size: 28),
              const SizedBox(width: 8),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: 12),
                duration: AppMotion.of(context, const Duration(milliseconds: 1400)),
                curve: AppMotion.standard,
                builder: (_, v, __) => Text(
                  '$v',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('días seguidos',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < days.length; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: AppMotion.of(
                      context, Duration(milliseconds: 300 + i * 150)),
                  curve: Curves.easeOutBack,
                  builder: (_, v, __) => Column(
                    children: [
                      Transform.scale(
                        scale: 0.6 + 0.4 * v.clamp(0.0, 1.2),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < 6
                                ? AppColors.accent.withValues(alpha: 0.9 * v.clamp(0.0, 1.0))
                                : AppColors.input,
                            border: Border.all(
                                color: i < 6 ? AppColors.accent : AppColors.border),
                          ),
                          child: i < 6
                              ? const Icon(LucideIcons.check,
                                  size: 15, color: AppColors.onPrimary)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(days[i],
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
