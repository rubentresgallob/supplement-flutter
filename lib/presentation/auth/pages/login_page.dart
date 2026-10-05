import 'forgot_password_page.dart';
import 'dart:async';
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

class _LoginPageState extends State<LoginPage> {
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

  /// Lo que dura el saludo de Capsu y su cara de error.
  static final _reactionTime = AppMotion.hero * 5;

  @override
  void initState() {
    super.initState();
    // Capsu reacciona al foco y a lo que se escribe
    for (final l in [_emailFocus, _passwordFocus, _emailController]) {
      l.addListener(_refreshCapsu);
    }
    _greetTimer = Timer(_reactionTime, () {
      if (mounted) setState(() => _greeting = false);
    });
  }

  @override
  void dispose() {
    _greetTimer?.cancel();
    _errorTimer?.cancel();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
    if (_loginError) return 'Algo no cuadra';
    if (isLoading) return 'Comprobando…';
    if (_passwordFocus.hasFocus) {
      return _obscurePassword ? 'No miro, lo prometo' : 'Solo un poquito';
    }
    if (_emailFocus.hasFocus) {
      final email = _emailController.text;
      if (email.isEmpty) return 'Escribe tu correo';
      return email.contains('@') && email.contains('.')
          ? 'Ese correo me suena'
          : 'Te leo…';
    }
    return 'Hola, soy Capsu. ¿Entramos?';
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
          _errorTimer = Timer(_reactionTime, () {
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
        body: AmbientBackground(
          child: SafeArea(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoadingState;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpace.lg),
                      Reveal(child: _buildHero(isLoading)),
                      const SizedBox(height: AppSpace.xl),
                      Reveal(delay: Reveal.step2, child: _buildForm(isLoading)),
                      const SizedBox(height: AppSpace.xl),
                      Reveal(
                        delay: Reveal.step3,
                        child: Column(
                          children: [
                            _buildDivider(),
                            const SizedBox(height: AppSpace.lg),
                            _buildSocialButtons(),
                            const SizedBox(height: AppSpace.xl),
                            _buildRegisterLink(isLoading),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isLoading) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: CapsuBubble(text: _capsuSays(isLoading)),
          ),
        ),
        HeroGlow(
          size: 190,
          child: Floating(
            amplitude: 4,
            child: Capsu(
              size: 96,
              mood: _capsuMood(isLoading),
              lookAt: _capsuLook,
            ),
          ),
        ),
        const Text('Enciende tu racha',
            textAlign: TextAlign.center, style: AppText.title),
        const SizedBox(height: AppSpace.sm),
        const Text('Tu stack diario, en una sola app',
            textAlign: TextAlign.center, style: AppText.brandSubtitle),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            style: AppText.input,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(LucideIcons.mail, size: 18),
            ),
            validator: Validators.validateEmail,
            enabled: !isLoading,
          ),
          const SizedBox(height: AppSpace.md),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            style: AppText.input,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(LucideIcons.lock, size: 18),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: Validators.validatePassword,
            enabled: !isLoading,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: PressableScale(
              onTap: isLoading
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ForgotPasswordPage(
                          initialEmail: _emailController.text.trim(),
                        ),
                      )),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                child: Text('¿Olvidaste tu contraseña?',
                    style: AppText.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ),
          ),
          AppButton(
            label: 'Iniciar sesión',
            size: AppButtonSize.lg,
            expand: true,
            loading: isLoading,
            onPressed: isLoading ? null : _onLoginPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpace.md),
          child: Text('O continúa con', style: AppText.micro),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(child: _socialButton('Google')),
        const SizedBox(width: AppSpace.md),
        Expanded(child: _socialButton('Apple')),
      ],
    );
  }

  Widget _socialButton(String label) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Text(label, style: AppText.button),
    );
  }

  Widget _buildRegisterLink(bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(
          child: Text('¿Aún sin cuenta?', style: AppText.body),
        ),
        PressableScale(
          onTap: isLoading
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
          child: const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpace.sm, vertical: AppSpace.md),
            child: Text('Crear una', style: AppText.label),
          ),
        ),
      ],
    );
  }
}
