import 'forgot_password_page.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import 'register_page.dart';
import 'verify_email_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Estado de Capsu
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _greeting = true;
  bool _loginError = false;
  Timer? _greetTimer;
  Timer? _errorTimer;

  late final AnimationController _blobCtrl;
  late final AnimationController _logoScaleCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _logoScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(
      parent: _logoScaleCtrl,
      curve: Curves.elasticOut,
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoScaleCtrl, curve: const Interval(0, 0.4)),
    );

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardOpacity = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnim =
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);

    // Capsu reacciona al foco y a lo que se escribe
    for (final l in [_emailFocus, _passwordFocus, _emailController]) {
      l.addListener(_refreshCapsu);
    }
    _greetTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _greeting = false);
    });

    _logoScaleCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _cardCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _logoScaleCtrl.dispose();
    _greetTimer?.cancel();
    _errorTimer?.cancel();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _cardCtrl.dispose();
    _shimmerCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _refreshCapsu() {
    if (mounted) setState(() {});
  }

  CapsuMood _capsuMood(bool isLoading) {
    if (_loginError) return CapsuMood.sad;
    if (isLoading) return CapsuMood.thinking;
    if (_passwordFocus.hasFocus) {
      return _obscurePassword ? CapsuMood.shy : CapsuMood.peek;
    }
    if (_emailFocus.hasFocus) return CapsuMood.idle;
    return _greeting ? CapsuMood.wave : CapsuMood.idle;
  }

  /// Mientras escribes el correo, Capsu sigue el cursor con la mirada.
  Offset get _capsuLook {
    if (!_emailFocus.hasFocus) return Offset.zero;
    final progress = (_emailController.text.length / 28).clamp(0.0, 1.0);
    return Offset(-0.8 + 1.6 * progress, 0.9);
  }

  String _capsuSays(bool isLoading) {
    if (_loginError) return 'Uy… algo no cuadra 😕';
    if (isLoading) return 'Comprobando… 🤔';
    if (_passwordFocus.hasFocus) {
      return _obscurePassword
          ? '¡No miro, lo prometo! 🙈'
          : 'Vale… solo un poquito 👀';
    }
    if (_emailFocus.hasFocus) {
      final email = _emailController.text;
      if (email.isEmpty) return 'Escribe tu correo 👇';
      return email.contains('@') && email.contains('.')
          ? '¡Ese correo me suena! 😄'
          : 'Te leo… ✍️';
    }
    return '¡Hola! Soy Capsu. ¿Entramos? 💊';
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          AppToast.show(context, state.message, type: AppToastType.error);
          _errorTimer?.cancel();
          setState(() => _loginError = true);
          _errorTimer = Timer(const Duration(milliseconds: 3200), () {
            if (mounted) setState(() => _loginError = false);
          });
        } else if (state is AuthNeedsVerificationState &&
            (ModalRoute.of(context)?.isCurrent ?? false)) {
          // Solo si el login está delante (si viene del registro, lo abre él)
          Navigator.of(context).push(MaterialPageRoute(
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
                painter: _BlobPainter(_blobCtrl.value),
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
                      children: [
                        const SizedBox(height: 20),
                        _buildLogo(isLoading),
                        const SizedBox(height: 28),
                        _buildFormCard(isLoading),
                        const SizedBox(height: 28),
                        _buildDivider(),
                        const SizedBox(height: 16),
                        _buildSocialButtons(),
                        const SizedBox(height: 32),
                        _buildRegisterLink(isLoading),
                        const SizedBox(height: 32),
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

  Widget _buildLogo(bool isLoading) {
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CapsuBubble(text: _capsuSays(isLoading)),
              ),
            ),
            // El lienzo de Capsu deja aire arriba para saltos: lo acercamos al bocadillo
            Transform.translate(
              offset: const Offset(0, -14),
              child: Capsu(
                size: 96,
                mood: _capsuMood(isLoading),
                lookAt: _capsuLook,
              ),
            ),
            const Text(
              'Enciende\ntu racha.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.6,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu stack diario, en una sola app.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardOpacity,
        child: Container(
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
                  focusNode: _emailFocus,
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
                  controller: _passwordController,
                  focusNode: _passwordFocus,
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
                  validator: Validators.validatePassword,
                  enabled: !isLoading,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ForgotPasswordPage(
                                initialEmail: _emailController.text.trim(),
                              ),
                            )),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 4),
                    ),
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _AnimatedGradientButton(
                  onPressed: isLoading ? null : _onLoginPressed,
                  isLoading: isLoading,
                  label: 'Iniciar sesión',
                  shimmerAnim: _shimmerAnim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return FadeTransition(
      opacity: _cardOpacity,
      child: Row(
        children: [
          Expanded(
              child: Container(height: 1, color: AppColors.border)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'O CONTINÚA CON',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.18,
              ),
            ),
          ),
          Expanded(
              child: Container(height: 1, color: AppColors.border)),
        ],
      ),
    );
  }

  Widget _buildSocialButtons() {
    return FadeTransition(
      opacity: _cardOpacity,
      child: Row(
        children: [
          Expanded(child: _socialButton(Icons.g_mobiledata_rounded, 'Google')),
          const SizedBox(width: 12),
          Expanded(child: _socialButton(Icons.apple_rounded, 'Apple')),
        ],
      ),
    );
  }

  Widget _socialButton(IconData icon, String label) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink(bool isLoading) {
    return FadeTransition(
      opacity: _cardOpacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¿Aún sin cuenta?  ',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          GestureDetector(
            onTap: isLoading
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
            child: Text(
              'Crear una',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary.withValues(alpha: 0.4),
                decorationThickness: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.06),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.2 + 0.15 * math.sin(t * 2 * math.pi)),
          size.height * (0.25 + 0.12 * math.cos(t * 2 * math.pi)),
        ),
        radius: size.width * 0.45,
      ));

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.2),
          AppColors.gold.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.75 + 0.1 * math.cos(t * 2 * math.pi + 1.0)),
          size.height * (0.6 + 0.1 * math.sin(t * 2 * math.pi + 1.0)),
        ),
        radius: size.width * 0.4,
      ));

    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.04),
          AppColors.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * (0.5 + 0.2 * math.sin(t * 2 * math.pi + 2.5)),
          size.height * (0.85 + 0.08 * math.cos(t * 2 * math.pi + 2.5)),
        ),
        radius: size.width * 0.35,
      ));

    final bgPaint = Paint()..color = AppColors.bgDeep;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    canvas.drawCircle(
      Offset(
        size.width * (0.2 + 0.15 * math.sin(t * 2 * math.pi)),
        size.height * (0.25 + 0.12 * math.cos(t * 2 * math.pi)),
      ),
      size.width * 0.45,
      paint1,
    );
    canvas.drawCircle(
      Offset(
        size.width * (0.75 + 0.1 * math.cos(t * 2 * math.pi + 1.0)),
        size.height * (0.6 + 0.1 * math.sin(t * 2 * math.pi + 1.0)),
      ),
      size.width * 0.4,
      paint2,
    );
    canvas.drawCircle(
      Offset(
        size.width * (0.5 + 0.2 * math.sin(t * 2 * math.pi + 2.5)),
        size.height * (0.85 + 0.08 * math.cos(t * 2 * math.pi + 2.5)),
      ),
      size.width * 0.35,
      paint3,
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}

class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final Animation<double> shimmerAnim;

  const _AnimatedGradientButton({
    required this.onPressed,
    required this.label,
    required this.shimmerAnim,
    this.isLoading = false,
  });

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
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
          builder: (_, child) {
            return Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(
                        colors: AppColors.brandGradient,
                        begin: Alignment(
                            -1.5 + 3.0 * widget.shimmerAnim.value, 0),
                        end: Alignment(
                            0.5 + 3.0 * widget.shimmerAnim.value, 0),
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
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: child,
            );
          },
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
