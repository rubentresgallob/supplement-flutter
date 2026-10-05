import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/supplement_card.dart';
import '../widgets/streak_badge.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../friends/pages/friends_page.dart';
import '../../profile/pages/profile_page.dart';
import '../../rewards/bloc/rewards_cubit.dart';
import '../../pro/bloc/pro_cubit.dart';
import '../../pro/pages/pro_page.dart';
import '../../../data/datasources/pro_remote_datasource.dart';
import '../../rewards/pages/shop_page.dart';
import '../../rewards/widgets/rewards_widgets.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/datasources/supplements_remote_datasource.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import '../../../domain/entities/streak.dart';
import '../../../domain/entities/user_supplement.dart';
import 'add_supplement_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentTab = 0;
  late final AnimationController _fabPulseCtrl;
  late final Animation<double> _fabPulse;

  bool _showCelebration = false;
  bool _prevAllComplete = false;
  StreamSubscription<RewardsCelebration>? _rewardsSub;

  static const _shopTab = 2;
  static const _profileTab = 3;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadSupplementsEvent());

    // Puntos y tienda: cada premio nuevo lo celebra Capsu con un aviso
    context.read<ProCubit>()
      ..reset()
      ..load();
    final rewards = context.read<RewardsCubit>()
      ..reset()
      ..load();
    _rewardsSub = rewards.celebrations.listen((celebration) {
      if (!mounted) return;
      RewardPopup.show(context, celebration, outfit: rewards.state.outfit);
    });
    _fabPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fabPulse = CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pulso del FAB desactivado si el usuario pide reducir movimiento
    if (AppMotion.reduced(context)) {
      _fabPulseCtrl.stop();
    } else if (!_fabPulseCtrl.isAnimating) {
      _fabPulseCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _rewardsSub?.cancel();
    RewardPopup.dismiss();
    _fabPulseCtrl.dispose();
    super.dispose();
  }

  void _triggerCelebration() {
    setState(() => _showCelebration = true);
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  Future<void> _openAddSupplement() async {
    final added = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddSupplementPage()));
    if (added == true && mounted) {
      context.read<HomeBloc>().add(HomeRefreshEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeLoadedState) {
          final allComplete = state.supplements.isNotEmpty &&
              state.supplements
                  .every((s) => (state.progress[s.id] ?? 0) >= s.timesPerDay);
          if (allComplete && !_prevAllComplete) {
            _triggerCelebration();
          }
          _prevAllComplete = allComplete;
        } else if (state is HomeLoadingState || state is HomeEmptyState) {
          _prevAllComplete = false;
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.bgDeep,
            body: IndexedStack(
              index: _currentTab,
              children: [
                _SupplementsTab(
                  onAddPressed: _openAddSupplement,
                  onProfilePressed: () => setState(() => _currentTab = _profileTab),
                  onShopPressed: () => setState(() => _currentTab = _shopTab),
                ),
                const FriendsPage(),
                const ShopPage(),
                const ProfilePage(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
            floatingActionButton: _currentTab == 0 ? _buildFAB() : null,
          ),
          if (_showCelebration)
            _CelebrationOverlay(outfit: context.read<RewardsCubit>().state.outfit),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xD9121212),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _NavItem(
                    icon: LucideIcons.flame,
                    activeIcon: LucideIcons.flame,
                    label: 'Suplementos',
                    isActive: _currentTab == 0,
                    onTap: () => setState(() => _currentTab = 0),
                  ),
                  _NavItem(
                    icon: LucideIcons.usersRound,
                    activeIcon: LucideIcons.usersRound,
                    label: 'Amigos',
                    isActive: _currentTab == 1,
                    onTap: () => setState(() => _currentTab = 1),
                  ),
                  _NavItem(
                    icon: LucideIcons.store,
                    activeIcon: LucideIcons.store,
                    label: 'Tienda',
                    isActive: _currentTab == _shopTab,
                    onTap: () => setState(() => _currentTab = _shopTab),
                  ),
                  _NavItem(
                    icon: LucideIcons.userRound,
                    activeIcon: LucideIcons.userRound,
                    label: 'Perfil',
                    isActive: _currentTab == _profileTab,
                    onTap: () => setState(() => _currentTab = _profileTab),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _fabPulse,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 60 + 44 * _fabPulse.value,
              height: 60 + 44 * _fabPulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary
                      .withValues(alpha: (1.0 - _fabPulse.value) * 0.35),
                  width: 2,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: Semantics(
        button: true,
        label: 'Añadir suplemento',
        child: GestureDetector(
        onTap: _openAddSupplement,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(LucideIcons.plus, color: AppColors.onPrimary, size: 28),
        ),
      ),
      ),
    );
  }
}

// ─── Confetti celebration ────────────────────────────────────────────────────

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double gravity;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final bool isCircle;

  _ConfettiParticle(math.Random rng)
      : startX = rng.nextDouble(),
        startY = rng.nextDouble() * 0.5 + 0.1,
        vx = (rng.nextDouble() - 0.5) * 0.5,
        vy = -(rng.nextDouble() * 0.8 + 0.3),
        gravity = rng.nextDouble() * 1.2 + 0.4,
        size = rng.nextDouble() * 10 + 6,
        rotation = rng.nextDouble() * math.pi * 2,
        rotationSpeed = (rng.nextDouble() - 0.5) * 12,
        isCircle = rng.nextBool(),
        color = const [
          AppColors.accent,
          AppColors.gold,
          AppColors.success,
          Colors.white,
          Color(0xFFFF3D00),
          Color(0xFF00E5FF),
        ][rng.nextInt(6)];
}

class _CelebrationOverlay extends StatefulWidget {
  final CapsuOutfit outfit;
  const _CelebrationOverlay({this.outfit = CapsuOutfit.none});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(70, (_) => _ConfettiParticle(rng));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          final contentOpacity = t < 0.12
              ? t / 0.12
              : t > 0.78
                  ? ((0.88 - t) / 0.1).clamp(0.0, 1.0)
                  : 1.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Scrim oscuro que se desvanece
              Opacity(
                opacity: (0.6 * (1 - t * 0.7)).clamp(0.0, 1.0),
                child: const ColoredBox(color: Colors.black),
              ),
              // Confetti
              CustomPaint(
                painter: _ConfettiPainter(_particles, t),
              ),
              // GIF + badge
              Center(
                child: Opacity(
                  opacity: contentOpacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.5 + 0.5 * Curves.elasticOut
                        .transform((t * 2).clamp(0.0, 1.0)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Capsu celebrando
                        Capsu(
                          size: 170,
                          mood: CapsuMood.celebrate,
                          interactive: false,
                          outfit: widget.outfit,
                        ),
                        const SizedBox(height: 8),
                        // Badge de texto
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppGradients.accent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.55),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.flame,
                                      color: AppColors.onPrimary, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '¡Racha del día!',
                                    style: TextStyle(
                                      color: AppColors.onPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Todos los suplementos tomados',
                                style: TextStyle(
                                  color: Color(0xB31A0B02),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double t;

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.startX + p.vx * t) * size.width;
      final y = (p.startY + p.vy * t + p.gravity * t * t) * size.height;

      if (y < -30 || y > size.height + 30) continue;

      final alpha = (1.0 - t * 0.7).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.5),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ─── NavItem ─────────────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.80), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.80, end: 1.20), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceCtrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.isActive,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _bounceScale,
              child: SizedBox(
                width: 48,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Radial glow when active
                    if (widget.isActive)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    Icon(
                      widget.isActive ? widget.activeIcon : widget.icon,
                      color: widget.isActive
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color:
                    widget.isActive ? AppColors.primary : AppColors.textMuted,
                fontSize: 11,
                fontWeight:
                    widget.isActive ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.08,
              ),
              child: Text(widget.label),
            ),
            const SizedBox(height: 4),
            // Dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: widget.isActive ? 4 : 0,
              height: widget.isActive ? 4 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─── Progress Ring ────────────────────────────────────────────────────────────

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const _ProgressRingPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF262626).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress;

    // Glow behind arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Fire gradient arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [
            Color(0xFFFF3D00),
            Color(0xFFFF6B35),
            Color(0xFFFAB437),
            Color(0xFFFF3D00),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

class _ProgressRing extends StatelessWidget {
  final int taken;
  final int total;

  const _ProgressRing({required this.taken, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (taken / total).clamp(0.0, 1.0) : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, p, __) => SizedBox(
        width: 92,
        height: 92,
        child: CustomPaint(
          painter: _ProgressRingPainter(progress: p, strokeWidth: 9),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$taken',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                Text(
                  '/$total',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab de Suplementos ──────────────────────────────────────────────────────

class _SupplementsTab extends StatelessWidget {
  final VoidCallback onAddPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onShopPressed;
  const _SupplementsTab({
    required this.onAddPressed,
    required this.onProfilePressed,
    required this.onShopPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeErrorState) {
          AppToast.error(context, state.message);
        }
      },
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final username = authState is AuthAuthenticatedState
            ? authState.user.username
            : '';
        final streak =
            state is HomeLoadedState ? state.userStreak : null;

        return CustomScrollView(
          slivers: [
            // Header: greeting + username + streak badge
            _buildHeader(username, streak),

            // Progress ring card
            if (state is HomeLoadedState) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _buildProgressCard(state),
                ),
              ),
              // Racha rota pero recuperable con protectores
              BlocBuilder<RewardsCubit, RewardsState>(
                buildWhen: (a, b) => a.summary?.repair != b.summary?.repair,
                builder: (context, rewards) {
                  final repair = rewards.summary?.repair;
                  return SliverToBoxAdapter(
                    child: repair == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: StreakRepairCard(
                              repair: repair,
                              onGoToShop: onShopPressed,
                            ),
                          ),
                  );
                },
              ),
              // Pro: suplementos a punto de acabarse
              if (state.supplements.any((s) => s.isStockLow))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _LowStockCard(
                      supplements:
                          state.supplements.where((s) => s.isStockLow).toList(),
                    ),
                  ),
                ),
            ],

            // States
            if (state is HomeLoadingState)
              const SliverToBoxAdapter(child: _HomeSkeleton())
            else if (state is HomeEmptyState)
              SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: AppEmpty(
                      media: const Capsu(size: 96, mood: CapsuMood.wave),
                      icon: LucideIcons.flame,
                      title: 'Tu stack está vacío',
                      description:
                          'Añade tu primer suplemento y empieza a construir tu racha diaria.',
                      action: AppButton(
                        label: 'Añadir suplemento',
                        icon: LucideIcons.plus,
                        onPressed: onAddPressed,
                      ),
                    ),
                  ))
            else if (state is HomeLoadedState) ...[
              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Tu stack',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        '${state.supplements.length} activos',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final s = state.supplements[i];
                      final taken = state.progress[s.id] ?? 0;
                      return SupplementCard(
                        supplement: s,
                        taken: taken,
                        cardIndex: i,
                        onMarkTaken: () => context
                            .read<HomeBloc>()
                            .add(HomeMarkIntakeTakenEvent(s.id)),
                        onMarkAllTaken: () => context
                            .read<HomeBloc>()
                            .add(HomeMarkAllIntakesTakenEvent(
                              s.id,
                              s.timesPerDay - taken,
                            )),
                        onEdit: () async {
                          final updated =
                              await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                _EditSupplementSheet(supplement: s),
                          );
                          if (updated == true && context.mounted) {
                            context
                                .read<HomeBloc>()
                                .add(HomeRefreshEvent());
                          }
                        },
                        onDelete: () {
                          context
                              .read<HomeBloc>()
                              .add(HomeDeleteSupplementEvent(s.id));
                        },
                      );
                    },
                    childCount: state.supplements.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    '← Desliza para eliminar  ·  Toca para registrar toma',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.04,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ] else
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
        );
      },
    );
  }

  SliverToBoxAdapter _buildHeader(String username, Streak? streak) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';

    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$username,',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              BlocBuilder<RewardsCubit, RewardsState>(
                buildWhen: (a, b) => a.points != b.points,
                builder: (context, rewards) => rewards.summary == null
                    ? const SizedBox.shrink()
                    : PointsChip(points: rewards.points, onTap: onShopPressed),
              ),
              if (streak != null) ...[
                const SizedBox(width: 8),
                StreakBadge(streak: streak),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(HomeLoadedState state) {
    final takenSlots = state.supplements.fold<int>(
        0, (sum, s) => sum + (state.progress[s.id] ?? 0).clamp(0, s.timesPerDay));
    final totalSlots =
        state.supplements.fold<int>(0, (sum, s) => sum + s.timesPerDay);
    final allDone = totalSlots > 0 && takenSlots >= totalSlots;
    final progress = totalSlots > 0 ? takenSlots / totalSlots : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCardElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glow accent top-right
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _ProgressRing(taken: takenSlots, total: totalSlots),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HOY',
                      style: TextStyle(
                        color: AppColors.neonOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      allDone
                          ? '¡Stack al 100%!'
                          : '$takenSlots de $totalSlots tomas',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      allDone
                          ? 'Eres una máquina. Vuelve mañana.'
                          : progress > 0.5
                              ? 'Casi lo tienes. No bajes el ritmo.'
                              : progress > 0
                                  ? 'Buen comienzo. Sigue así.'
                                  : 'Empieza tu primera toma del día.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
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

// ─── Skeleton de carga ───────────────────────────────────────────────────────

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeletonGroup(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de progreso
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.frame(color: AppColors.bgCardElevated.withValues(alpha: 0.7)),
              child: const Row(
                children: [
                  AppSkeleton.circle(size: 92),
                  SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeleton(width: 40, height: 10),
                        SizedBox(height: 10),
                        AppSkeleton(width: 150, height: 20),
                        SizedBox(height: 10),
                        AppSkeleton(width: 190, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const AppSkeleton(width: 90, height: 18),
            const SizedBox(height: 14),
            for (var i = 0; i < 3; i++) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.frame(),
                child: const Row(
                  children: [
                    AppSkeleton(width: 48, height: 48, radius: AppRadius.xl),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton(width: 130, height: 14),
                          SizedBox(height: 8),
                          AppSkeleton(width: 90, height: 11),
                        ],
                      ),
                    ),
                    AppSkeleton(width: 44, height: 44, radius: AppRadius.lg),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sheet de edición de suplemento ─────────────────────────────────────────

class _EditSupplementSheet extends StatefulWidget {
  final UserSupplement supplement;
  const _EditSupplementSheet({required this.supplement});

  @override
  State<_EditSupplementSheet> createState() => _EditSupplementSheetState();
}

class _EditSupplementSheetState extends State<_EditSupplementSheet> {
  static const _allForms = [
    'pastilla', 'tableta', 'comprimido', 'cápsula',
    'polvo', 'líquido', 'gominola', 'gotas',
  ];
  static const _dosageUnits = [
    'mg', 'g', 'µg', 'UI', 'ml', 'cápsulas', 'comprimidos',
  ];
  static const _scheduleOptions = [
    ('mañana',   LucideIcons.sun,  'Mañana'),
    ('mediodía', LucideIcons.cloudSun, 'Mediodía'),
    ('tarde',    LucideIcons.sunset,     'Tarde'),
    ('noche',    LucideIcons.moon,'Noche'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late String _selectedForm;
  late String _dosageUnit;
  late List<String> _schedules;
  late int _timesPerDay;
  TimeOfDay? _notificationTime;
  bool _saving = false;

  // Stock (Pro)
  late bool _stockEnabled;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _unitsPerIntakeCtrl;

  double? _parse(String v) => double.tryParse(v.replaceAll(',', '.'));

  String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  /// Días que dura el stock con los valores escritos.
  int? get _stockDaysPreview {
    final units = _parse(_stockCtrl.text);
    final perIntake = _parse(_unitsPerIntakeCtrl.text) ?? 1;
    final perDay = perIntake * _computedTimesPerDay;
    if (units == null || perDay <= 0) return null;
    return (units / perDay).floor();
  }

  bool get _isPillUnit =>
      _dosageUnit == 'cápsulas' || _dosageUnit == 'comprimidos';

  int get _computedTimesPerDay {
    if (_isPillUnit) {
      final amount =
          double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
      return (amount?.toInt() ?? 1).clamp(1, 99);
    }
    return _timesPerDay;
  }

  @override
  void initState() {
    super.initState();
    final s = widget.supplement;
    _amountCtrl = TextEditingController(
      text: s.dosageAmount % 1 == 0
          ? s.dosageAmount.toInt().toString()
          : s.dosageAmount.toString(),
    );
    _selectedForm = _allForms.contains(s.form) ? s.form : _allForms.first;
    _dosageUnit =
        _dosageUnits.contains(s.dosageUnit) ? s.dosageUnit : _dosageUnits.first;
    _schedules = List.from(s.schedules);
    _timesPerDay = s.timesPerDay;
    _amountCtrl.addListener(() => setState(() {}));
    _stockEnabled = s.tracksStock;
    _stockCtrl = TextEditingController(text: s.stockUnits == null ? '' : _fmt(s.stockUnits!))
      ..addListener(() => setState(() {}));
    _unitsPerIntakeCtrl = TextEditingController(text: _fmt(s.unitsPerIntake))
      ..addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final savedTime =
          context.read<LocalStorageDataSource>().getNotificationTime(s.id);
      if (savedTime != null) setState(() => _notificationTime = savedTime);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _stockCtrl.dispose();
    _unitsPerIntakeCtrl.dispose();
    super.dispose();
  }

  /// Guarda el stock solo si es Pro y ha cambiado algo.
  Future<void> _saveStock(ProRemoteDataSource proDs, bool isPro) async {
    if (!isPro) return;
    final s = widget.supplement;
    final units = _stockEnabled ? _parse(_stockCtrl.text) : null;
    final perIntake = _parse(_unitsPerIntakeCtrl.text) ?? 1;
    if (units == s.stockUnits && perIntake == s.unitsPerIntake) return;
    await proDs.updateStock(s.id, stockUnits: units, unitsPerIntake: perIntake);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_schedules.isEmpty) {
      _snack('Selecciona al menos un horario');
      return;
    }
    setState(() => _saving = true);
    final supplementsDs = context.read<SupplementsRemoteDataSource>();
    final localStorageDs = context.read<LocalStorageDataSource>();
    final proDs = context.read<ProRemoteDataSource>();
    final isPro = context.read<ProCubit>().state.isPro;
    final notifTime = _notificationTime;
    final supId = widget.supplement.id;
    final supName = widget.supplement.name;
    try {
      await supplementsDs.updateUserSupplement(
        supId,
        form: _selectedForm,
        dosageAmount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
        dosageUnit: _dosageUnit,
        timesPerDay: _computedTimesPerDay,
        schedules: List.from(_schedules),
      );
      await _saveStock(proDs, isPro);
      if (notifTime != null) {
        await localStorageDs.saveNotificationTime(supId, notifTime);
        await NotificationService.scheduleReminder(
          id: NotificationService.idFromSupplementId(supId),
          supplementName: supName,
          time: notifTime,
        );
      } else {
        // Borrar también la hora guardada: si no, la Home lo volvía a programar
        await localStorageDs.removeNotificationTime(supId);
        await NotificationService.cancelReminder(
          NotificationService.idFromSupplementId(supId),
        );
      }
      if (mounted) {
        _snack('Suplemento actualizado', isSuccess: true);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _pickNotificationTime() async {
    final picked =
        await showReminderTimePicker(context, initial: _notificationTime);
    if (picked == null || !mounted) return;
    setState(() => _notificationTime = picked);
    // Pedimos permiso justo cuando el usuario quiere un recordatorio
    final allowed = await NotificationService.ensurePermissions();
    if (!allowed && mounted) {
      AppToast.show(
        context,
        'Activa las notificaciones de la app en Ajustes para recibir el recordatorio',
        type: AppToastType.warning,
      );
    }
  }

  void _snack(String msg, {bool isError = false, bool isSuccess = false}) {
    AppToast.show(
      context,
      msg,
      type: isError
          ? AppToastType.error
          : isSuccess
              ? AppToastType.success
              : AppToastType.warning,
    );
  }

  Widget _buildStockSection() {
    final isPro = context.watch<ProCubit>().state.isPro;
    if (!isPro) {
      return GestureDetector(
        onTap: () => openProPage(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(children: [
            Icon(LucideIcons.package, color: AppColors.textMuted, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text('Te avisamos antes de que se te acabe',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ),
            Icon(LucideIcons.lock, color: AppColors.textMuted, size: 16),
          ]),
        ),
      );
    }

    final days = _stockDaysPreview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _stockEnabled,
          activeThumbColor: AppColors.accent,
          title: const Text('Controlar lo que me queda',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          onChanged: (v) => setState(() => _stockEnabled = v),
        ),
        if (_stockEnabled) ...[
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _stockCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Me quedan (unidades)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => _stockEnabled && _parse(v ?? '') == null ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _unitsPerIntakeCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Gasto por toma'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (_parse(v ?? '') ?? 0) <= 0 ? 'Inválido' : null,
              ),
            ),
          ]),
          if (days != null) ...[
            const SizedBox(height: 8),
            Text(
              '📦 Te dura unos $days días',
              style: TextStyle(
                color: days <= 7 ? AppColors.warning : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.supplement.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Editar configuración',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),

              const _SectionLabel('Forma'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allForms
                    .map((f) => AppToggleChip(
                          label: f,
                          selected: _selectedForm == f,
                          onChanged: (_) => setState(() => _selectedForm = f),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              const _SectionLabel('Dosis'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _dosageUnit,
                    dropdownColor: AppColors.bgCardElevated,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: _dosageUnits
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _dosageUnit = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              const _SectionLabel('Horarios'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _scheduleOptions.map((opt) {
                  final (value, icon, label) = opt;
                  return AppToggleChip(
                    label: label,
                    icon: icon,
                    selected: _schedules.contains(value),
                    onChanged: (sel) => setState(() {
                      sel ? _schedules.add(value) : _schedules.remove(value);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const _SectionLabel('Tomas por día'),
              const SizedBox(height: 8),
              if (_isPillUnit)
                AppAlert(
                  message:
                      'Cada ${_dosageUnit == 'cápsulas' ? 'cápsula' : 'comprimido'} cuenta como 1 toma — total: $_computedTimesPerDay tomas al día',
                )
              else
                AppNumberField(
                  value: _timesPerDay,
                  min: 1,
                  max: 20,
                  format: (v) => '$v ${v == 1 ? 'vez al día' : 'veces al día'}',
                  onChanged: (v) => setState(() => _timesPerDay = v),
                ),
              const SizedBox(height: 20),

              const _SectionLabel('Recordatorio'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickNotificationTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _notificationTime != null
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.bgCardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _notificationTime != null
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      _notificationTime != null
                          ? LucideIcons.bellRing
                          : LucideIcons.bell,
                      color: _notificationTime != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _notificationTime != null
                            ? 'Recordatorio a las ${_notificationTime!.format(context)}'
                            : 'Sin recordatorio (toca para configurar)',
                        style: TextStyle(
                          color: _notificationTime != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_notificationTime != null)
                      SizedBox(
                        width: AppSpacing.minTouch,
                        height: AppSpacing.minTouch,
                        child: IconButton(
                          tooltip: 'Quitar recordatorio',
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              setState(() => _notificationTime = null),
                          icon: const Icon(LucideIcons.x,
                              color: AppColors.textMuted, size: 18),
                        ),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              const Row(
                children: [
                  _SectionLabel('Control de stock'),
                  SizedBox(width: 6),
                  ProBadge(),
                ],
              ),
              const SizedBox(height: 8),
              _buildStockSection(),
              const SizedBox(height: 28),

              AppButton(
                label: 'Guardar cambios',
                size: AppButtonSize.lg,
                expand: true,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso de stock bajo (Pro): "Se te acaba la creatina en 3 días".
class _LowStockCard extends StatelessWidget {
  final List<UserSupplement> supplements;
  const _LowStockCard({required this.supplements});

  String _line(UserSupplement s) {
    final days = s.stockDaysLeft ?? 0;
    if (days == 0) return '${s.name}: se ha acabado';
    return '${s.name}: quedan $days ${days == 1 ? 'día' : 'días'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📦', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toca reponer',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                for (final s in supplements)
                  Text(
                    _line(s),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8));
}
