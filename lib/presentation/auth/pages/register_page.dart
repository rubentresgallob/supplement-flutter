import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/ui/ui.dart';
import '../widgets/legal_consents.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;
  var _consents = const LegalConsentsValue();

  static const _strengthLabels = ['', 'Débil', 'Mejor', 'Buena', 'Fuerte'];
  static const _strengthColors = [
    AppColors.border,
    AppColors.danger,
    AppColors.warning,
    AppColors.accent,
    AppColors.mint,
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (!_consents.all) {
      AppToast.show(context, 'Marca las tres casillas para crear tu cuenta', type: AppToastType.warning);
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
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Volver',
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Crear cuenta'),
        ),
        extendBodyBehindAppBar: true,
        body: AmbientBackground(
          child: SafeArea(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoadingState;
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.screen),
                        child: Column(
                          children: [
                            const SizedBox(height: AppSpace.xl),
                            const Reveal(
                              child: Floating(child: IridescentOrb(size: 56)),
                            ),
                            const SizedBox(height: AppSpace.xl),
                            const Reveal(
                              delay: Reveal.step1,
                              child: Text('Crea tu perfil',
                                  textAlign: TextAlign.center,
                                  style: AppText.title),
                            ),
                            const SizedBox(height: AppSpace.sm),
                            const Reveal(
                              delay: Reveal.step2,
                              child: Text(
                                'Empieza la racha hoy. Sin tarjetas.',
                                textAlign: TextAlign.center,
                                style: AppText.body,
                              ),
                            ),
                            const SizedBox(height: AppSpace.xl),
                            Reveal(
                              delay: Reveal.step2,
                              child: _buildForm(isLoading),
                            ),
                            const SizedBox(height: AppSpace.lg),
                          ],
                        ),
                      ),
                    ),
                    Reveal(
                      delay: Reveal.step3,
                      child: BottomActions(
                        children: [
                          AppButton(
                            label: 'Crear cuenta',
                            size: AppButtonSize.lg,
                            expand: true,
                            loading: isLoading,
                            onPressed: isLoading ? null : _onRegisterPressed,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
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
            controller: _usernameController,
            style: AppText.input,
            decoration: const InputDecoration(
              labelText: 'Nombre de usuario',
              prefixIcon: Icon(LucideIcons.userRound, size: 18),
            ),
            validator: Validators.validateUsername,
            enabled: !isLoading,
          ),
          const SizedBox(height: AppSpace.md),
          TextFormField(
            controller: _passwordController,
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
            onChanged: (_) => setState(() {}),
            validator: Validators.validatePassword,
            enabled: !isLoading,
          ),
          const SizedBox(height: AppSpace.md),
          _buildStrengthBars(),
          const SizedBox(height: AppSpace.lg),
          LegalConsents(
            value: _consents,
            enabled: !isLoading,
            onChanged: (v) => setState(() => _consents = v),
          ),
        ],
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
            return Expanded(
              child: AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.medium),
                curve: AppMotion.standard,
                margin: EdgeInsets.only(left: i == 0 ? 0 : AppSpace.xs),
                height: 2,
                color: i < s ? color : AppColors.border,
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Seguridad', style: AppText.micro),
            if (s > 0)
              Text(_strengthLabels[s],
                  style: AppText.micro.copyWith(color: color)),
          ],
        ),
      ],
    );
  }
}
