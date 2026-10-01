import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/legal_links.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_state.dart';
import '../../onboarding/pages/onboarding_page.dart';
import '../../rewards/bloc/rewards_cubit.dart';
import '../../pro/widgets/pro_profile_section.dart';
import '../../../core/widgets/mascot/capsu.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  String _bio = '';

  late final AnimationController _ringCtrl;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _statsOpacity;
  late final Animation<Offset> _statsSlide;
  late final Animation<double> _settingsOpacity;
  late final Animation<Offset> _settingsSlide;

  @override
  void initState() {
    super.initState();
    _bio = context.read<LocalStorageDataSource>().getBio();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _headerOpacity = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _statsOpacity = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.65),
    );
    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
    ));

    _settingsOpacity = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.5, 0.9),
    );
    _settingsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _editBio() async {
    final result = await showAppPrompt(
      context,
      title: 'Tu descripción',
      body: 'Cuéntale a tus amigos qué te motiva.',
      confirmLabel: 'Guardar',
      hint: 'Ej.: Entrenando para mi primera maratón',
      initialValue: _bio,
      maxLines: 3,
    );
    if (result != null && mounted) {
      final ls = context.read<LocalStorageDataSource>();
      await ls.saveBio(result);
      setState(() => _bio = result);
    }
  }

  /// Eliminar cuenta (obligatorio en App Store y Google Play): confirmar + contraseña.
  Future<void> _deleteAccount() async {
    final confirmed = await showAppConfirm(
      context,
      title: '¿Eliminar tu cuenta?',
      body:
          'Se borrarán para siempre tus suplementos, tomas, rachas, amigos, puntos y objetos. '
          'No se puede deshacer.\n\nSi tienes Pro, cancela también la suscripción en tu tienda de apps.',
      confirmLabel: 'Continuar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final password = await showAppPrompt(
      context,
      title: 'Confirma con tu contraseña',
      body: 'Escribe tu contraseña para eliminar la cuenta.',
      confirmLabel: 'Eliminar cuenta',
      hint: 'Contraseña',
      icon: LucideIcons.lock,
      obscureText: true,
      destructive: true,
    );
    if (password == null || password.isEmpty || !mounted) return;

    try {
      await context.read<AuthRemoteDataSource>().deleteAccount(password);
      await NotificationService.cancelAll();
      if (!mounted) return;
      AppToast.success(context, 'Tu cuenta se ha eliminado');
      context.read<AuthBloc>().add(AuthLogoutEvent());
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerOpacity,
                child: SlideTransition(
                  position: _headerSlide,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mi cuenta',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Perfil',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Avatar + info
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerOpacity,
                child: SlideTransition(
                  position: _headerSlide,
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is! AuthAuthenticatedState) {
                        return const SizedBox();
                      }
                      final user = state.user;
                      // Banner y medalla equipados en la tienda
                      final rewards = context.watch<RewardsCubit>().state;
                      final banner = rewards.item(rewards.equipped['banner']);
                      final medal = rewards.item(rewards.equipped['medal']);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: banner != null && banner.colors.length >= 2
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      ...banner.colors
                                          .map((c) => c.withValues(alpha: 0.45)),
                                      AppColors.bgCard,
                                    ],
                                  )
                                : AppGradients.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Rotating ring avatar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _AnimatedAvatarRing(
                                    letter: user.username[0].toUpperCase(),
                                    ringCtrl: _ringCtrl,
                                  ),
                                  const SizedBox(width: 12),
                                  Capsu(
                                    size: 62,
                                    mood: CapsuMood.wave,
                                    outfit: rewards.outfit,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (b) =>
                                        AppGradients.brand.createShader(b),
                                    child: Text(
                                      user.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  if (medal != null) ...[
                                    const SizedBox(width: 6),
                                    Tooltip(
                                      message: medal.name,
                                      child: Text(medal.icon,
                                          style: const TextStyle(fontSize: 20)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(user.email,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                'Miembro desde ${_formatDate(user.createdAt)}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _editBio,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgCardElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _bio.isEmpty
                                              ? 'Añade una descripción...'
                                              : _bio,
                                          style: TextStyle(
                                            color: _bio.isEmpty
                                                ? AppColors.textMuted
                                                : AppColors.textSecondary,
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(LucideIcons.pencil,
                                          size: 14,
                                          color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Stats
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _statsOpacity,
                child: SlideTransition(
                  position: _statsSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('Mis estadísticas',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                        ),
                        BlocBuilder<HomeBloc, HomeState>(
                          builder: (context, homeState) {
                            int supplementCount = 0;
                            int streakDays = 0;
                            int longestStreak = 0;
                            if (homeState is HomeLoadedState) {
                              supplementCount =
                                  homeState.supplements.length;
                              streakDays =
                                  homeState.userStreak.currentStreak;
                              longestStreak =
                                  homeState.userStreak.longestStreak;
                            }
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _BentoStatCard(
                                        label: 'Racha actual',
                                        value: streakDays,
                                        unit: 'días',
                                        labelColor: AppColors.gold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _BentoStatCard(
                                        label: 'Mejor racha',
                                        value: longestStreak,
                                        unit: 'días',
                                        labelColor: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _BentoStatCardWide(
                                  label: 'Suplementos activos',
                                  value: supplementCount,
                                  unit: 'activos',
                                ),
                                const SizedBox(height: 10),
                                _BentoStatCardWide(
                                  label: 'Puntos',
                                  value: context.watch<RewardsCubit>().state.points,
                                  unit: '💎',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Plan Pro + estadísticas
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _settingsOpacity,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ProProfileSection(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Ajustes
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _settingsOpacity,
                child: SlideTransition(
                  position: _settingsSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('Ajustes',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _SettingsTile(
                                icon: LucideIcons.bell,
                                label: 'Notificaciones',
                                trailing: const Icon(
                                    LucideIcons.chevronRight,
                                    color: AppColors.textMuted),
                                onTap: () {},
                              ),
                              const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                  indent: 52),
                              _SettingsTile(
                                icon: LucideIcons.pill,
                                label: 'Ver tutorial de Capsu',
                                trailing: const Icon(
                                    LucideIcons.chevronRight,
                                    color: AppColors.textMuted),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => OnboardingPage(
                                      onDone: () => Navigator.of(ctx).pop(),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                  indent: 52),
                              _SettingsTile(
                                icon: LucideIcons.shieldCheck,
                                label: 'Política de privacidad',
                                trailing: const Icon(LucideIcons.externalLink,
                                    color: AppColors.textMuted, size: 18),
                                onTap: () =>
                                    openLegalPage(context, LegalPage.privacy),
                              ),
                              const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                  indent: 52),
                              _SettingsTile(
                                icon: LucideIcons.fileText,
                                label: 'Términos de uso',
                                trailing: const Icon(LucideIcons.externalLink,
                                    color: AppColors.textMuted, size: 18),
                                onTap: () =>
                                    openLegalPage(context, LegalPage.terms),
                              ),
                              const Divider(
                                  height: 1,
                                  color: AppColors.border,
                                  indent: 52),
                              _SettingsTile(
                                icon: LucideIcons.info,
                                label: 'Versión de la app',
                                trailing: const Text('1.0.0',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13)),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Cerrar sesión
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _settingsOpacity,
                child: SlideTransition(
                  position: _settingsSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () =>
                          context.read<AuthBloc>().add(AuthLogoutEvent()),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.logOut,
                                color: AppColors.error, size: 20),
                            SizedBox(width: 10),
                            Text('Cerrar sesión',
                                style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Eliminar cuenta (discreto, debajo de cerrar sesión)
            SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: _deleteAccount,
                  child: const Text(
                    'Eliminar mi cuenta',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedAvatarRing extends StatelessWidget {
  final String letter;
  final AnimationController ringCtrl;

  const _AnimatedAvatarRing({
    required this.letter,
    required this.ringCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ringCtrl,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          // Rotating gradient ring
          Transform.rotate(
            angle: ringCtrl.value * 2 * math.pi,
            child: Container(
              width: 94,
              height: 94,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.gold,
                    Color(0x00FF6B35),
                    AppColors.primary,
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // Gap ring
          Container(
            width: 86,
            height: 86,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgCard,
            ),
          ),
          // Avatar
          child!,
        ],
      ),
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          gradient: AppGradients.brand,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              color: AppColors.onPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoStatCard extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color labelColor;

  const _BentoStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.12,
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${v.round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoStatCardWide extends StatelessWidget {
  final String label;
  final int value;
  final String unit;

  const _BentoStatCardWide({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.12,
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${v.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Icon(
            LucideIcons.pill,
            size: 32,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bgCardElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child:
                  Icon(icon, color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500))),
            trailing,
          ],
        ),
      ),
    );
  }
}
