import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import 'register_page.dart';

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

  late final AnimationController _blobCtrl;
  late final AnimationController _logoScaleCtrl;
  late final AnimationController _logoPulseCtrl;
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

    _logoPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

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
    _logoPulseCtrl.dispose();
    _cardCtrl.dispose();
    _shimmerCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
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
                        const SizedBox(height: 48),
                        _buildLogo(),
                        const SizedBox(height: 36),
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

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _logoPulseCtrl,
              builder: (_, child) {
                final glow = 0.5 + 0.5 * _logoPulseCtrl.value;
                return Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF3D00), Color(0xFFFF6B35), Color(0xFFFAB437)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4 + 0.25 * glow),
                        blurRadius: 28 + 20 * glow,
                        spreadRadius: 4 + 4 * glow,
                      ),
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.15 * glow),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Enciende\ntu racha.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                fontFamily: 'Syne',
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
            color: const Color(0xFF1A2234).withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
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
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.validateEmail,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
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
                    onPressed: isLoading ? null : () {},
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
        color: const Color(0xFF1A2234).withValues(alpha: 0.6),
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
          AppColors.primary.withValues(alpha: 0.28),
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
          AppColors.primary.withValues(alpha: 0.12),
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
                          color: AppColors.primary.withValues(alpha: 0.5),
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
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.3,
                      fontFamily: 'Syne',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
