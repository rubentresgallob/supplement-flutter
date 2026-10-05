import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../core/utils/legal_links.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  // Enlaces del texto de consentimiento
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => openLegalPage(context, LegalPage.terms);
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => openLegalPage(context, LegalPage.privacy);

  late final AnimationController _blobCtrl;
  late final AnimationController _entranceCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _formOpacity;
  late final Animation<double> _shimmerAnim;

  static const _strengthLabels = ['', 'Débil', 'Mejor', 'Buena', 'Fuerte'];
  static const _strengthColors = [
    Color(0xFF262626),
    Color(0xFFFF4444),
    Color(0xFFFAB437),
    Color(0xFFFF8C42),
    Color(0xFF4ADE80),
  ];

  int get _strength {
    final pw = _passwordController.text;
    if (pw.isEmpty) return 0;
    int s = (pw.length / 2.5).floor();
    if (pw.contains(RegExp(r'[A-Z]'))) s++;
    if (pw.contains(RegExp(r'\d'))) s++;
    return s.clamp(0, 4);
  }

  @override
  void initState() {
    super.initState();

    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _headerSlide = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    ));

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.4),
      ),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _formOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.3, 0.7),
      ),
    );

    _shimmerAnim =
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _blobCtrl.dispose();
    _entranceCtrl.dispose();
    _shimmerCtrl.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (!_acceptedTerms) {
      AppToast.show(context, 'Debes aceptar los términos y la política de privacidad', type: AppToastType.warning);
      return;
    }
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthRegisterEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            username: _usernameController.text.trim(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          AppToast.show(context, state.message, type: AppToastType.error);
        } else if (state is AuthNeedsVerificationState) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => VerifyEmailPage(email: state.email),
          ));
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _blobCtrl,
              builder: (_, __) => CustomPaint(
                painter: _RegBlobPainter(_blobCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),
            SafeArea(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoadingState;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Header
                        SlideTransition(
                          position: _headerSlide,
                          child: FadeTransition(
                            opacity: _headerOpacity,
                            child: _buildHeader(context),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Form card
                        SlideTransition(
                          position: _formSlide,
                          child: FadeTransition(
                            opacity: _formOpacity,
                            child: _buildFormCard(isLoading),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F).withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(LucideIcons.chevronLeft,
                color: AppColors.textPrimary, size: 22),
          ),
        ),
        const SizedBox(height: 24),
        // "Crea tu"
        const Text(
          'Crea tu',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.0,
            height: 0.95,
          ),
        ),
        // "perfil de fuego." with fire gradient
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFF3D00), Color(0xFFFF6B35), Color(0xFFFAB437)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(b),
          child: const Text(
            'perfil de fuego.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.0,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Empieza la racha hoy. Sin tarjetas, sin friolera.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(LucideIcons.mail),
              ),
              validator: Validators.validateEmail,
              enabled: !isLoading,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                prefixIcon: Icon(LucideIcons.userRound),
              ),
              validator: Validators.validateUsername,
              enabled: !isLoading,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(LucideIcons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? LucideIcons.eye
                      : LucideIcons.eyeOff),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              onChanged: (_) => setState(() {}),
              validator: Validators.validatePassword,
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),
            // Password strength bars
            _buildStrengthBars(),
            const SizedBox(height: 20),
            // Terms toggle
            _buildTermsToggle(isLoading),
            const SizedBox(height: 24),
            _AnimatedRegButton(
              onPressed: isLoading ? null : _onRegisterPressed,
              isLoading: isLoading,
              label: 'Crear cuenta',
              shimmerAnim: _shimmerAnim,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthBars() {
    final s = _strength;
    final color = _strengthColors[s];
    return Column(
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < s;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                height: 4,
                decoration: BoxDecoration(
                  color: filled ? color : AppColors.bgCardElevated,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: filled
                      ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SEGURIDAD',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.08,
              ),
            ),
            if (s > 0)
              Text(
                _strengthLabels[s].toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsToggle(bool isLoading) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pill toggle switch
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 26,
              decoration: BoxDecoration(
                gradient: _acceptedTerms ? AppGradients.brand : null,
                color: _acceptedTerms
                    ? null
                    : const Color(0xFF262626).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _acceptedTerms ? Colors.transparent : AppColors.border,
                ),
                boxShadow: _acceptedTerms
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 14,
                        )
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.elasticOut,
                    top: 3,
                    left: _acceptedTerms ? 21 : 3,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _acceptedTerms ? AppColors.onPrimary : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Acepto los '),
                    TextSpan(
                      text: 'Términos',
                      recognizer: _termsTap,
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'Política de privacidad',
                      recognizer: _privacyTap,
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    // RGPD: consentimiento explícito para datos de salud
                    const TextSpan(
                      text: ', y que se traten mis datos sobre los suplementos que tomo para usar la app.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegBlobPainter extends CustomPainter {
  final double t;
  _RegBlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.bgDeep;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final p1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.22),
          AppColors.gold.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.8 + 0.12 * math.sin(t * 2 * math.pi)),
          size.height * (0.2 + 0.1 * math.cos(t * 2 * math.pi)),
        ),
        radius: size.width * 0.42,
      ));

    final p2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.05),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.15 + 0.1 * math.cos(t * 2 * math.pi + 1.5)),
          size.height * (0.7 + 0.1 * math.sin(t * 2 * math.pi + 1.5)),
        ),
        radius: size.width * 0.45,
      ));

    canvas.drawCircle(
      Offset(
        size.width * (0.8 + 0.12 * math.sin(t * 2 * math.pi)),
        size.height * (0.2 + 0.1 * math.cos(t * 2 * math.pi)),
      ),
      size.width * 0.42,
      p1,
    );
    canvas.drawCircle(
      Offset(
        size.width * (0.15 + 0.1 * math.cos(t * 2 * math.pi + 1.5)),
        size.height * (0.7 + 0.1 * math.sin(t * 2 * math.pi + 1.5)),
      ),
      size.width * 0.45,
      p2,
    );
  }

  @override
  bool shouldRepaint(_RegBlobPainter old) => old.t != t;
}

class _AnimatedRegButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final Animation<double> shimmerAnim;

  const _AnimatedRegButton({
    required this.onPressed,
    required this.label,
    required this.shimmerAnim,
    this.isLoading = false,
  });

  @override
  State<_AnimatedRegButton> createState() => _AnimatedRegButtonState();
}

class _AnimatedRegButtonState extends State<_AnimatedRegButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => _pressCtrl.forward() : null,
      onTapUp: enabled
          ? (_) {
              _pressCtrl.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _pressScale,
        child: AnimatedBuilder(
          animation: widget.shimmerAnim,
          builder: (_, child) => Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: enabled
                  ? LinearGradient(
                      colors: AppColors.brandGradient,
                      begin: Alignment(
                          -1.5 + 3.0 * widget.shimmerAnim.value, 0),
                      end:
                          Alignment(0.5 + 3.0 * widget.shimmerAnim.value, 0),
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF3A3A3A), Color(0xFF3A3A3A)]),
              borderRadius: BorderRadius.circular(999),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: child,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.onPrimary),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
