import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
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
import '../../../core/constants/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadSupplementsEvent());
    _fabPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _fabPulse = CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
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
                  onProfilePressed: () => setState(() => _currentTab = 2),
                ),
                const FriendsPage(),
                const ProfilePage(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(),
            floatingActionButton: _currentTab == 0 ? _buildFAB() : null,
          ),
          if (_showCelebration) const _CelebrationOverlay(),
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
            color: Color(0xD9070B18),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.local_fire_department_outlined,
                    activeIcon: Icons.local_fire_department_rounded,
                    label: 'Suplementos',
                    isActive: _currentTab == 0,
                    onTap: () => setState(() => _currentTab = 0),
                  ),
                  _NavItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people_rounded,
                    label: 'Amigos',
                    isActive: _currentTab == 1,
                    onTap: () => setState(() => _currentTab = 1),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person_rounded,
                    label: 'Perfil',
                    isActive: _currentTab == 2,
                    onTap: () => setState(() => _currentTab = 2),
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
      child: GestureDetector(
        onTap: _openAddSupplement,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3D00), Color(0xFFFF6B35), Color(0xFFFAB437)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3D00).withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 0,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
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
          AppColors.primary,
          AppColors.gold,
          AppColors.success,
          Colors.white,
          Color(0xFFFF3D00),
          Color(0xFF00E5FF),
        ][rng.nextInt(6)];
}

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay();

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_ConfettiParticle> _particles;
  late final String _gifPath;

  static const _gifs = [
    'assets/gifs/8fdb05aca4211c1886b200259514422b.gif',
    'assets/gifs/descarga.gif',
    'assets/gifs/hasbulla-fire.gif',
    'assets/gifs/hasbulla-hasbullah.gif',
    'assets/gifs/hasbulla.gif',
  ];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _gifPath = _gifs[rng.nextInt(_gifs.length)];
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
                        // GIF animado aleatorio
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                blurRadius: 48,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.4),
                                blurRadius: 72,
                                spreadRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              _gifPath,
                              width: 250,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Badge de texto
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppGradients.brand,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.55),
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
                                  Icon(Icons.local_fire_department_rounded,
                                      color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '¡Racha del día!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Todos los suplementos tomados',
                                style: TextStyle(
                                  color: Colors.white70,
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
                                AppColors.primary.withValues(alpha: 0.35),
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
                fontSize: 9,
                fontWeight:
                    widget.isActive ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.08,
                fontFamily: 'Syne',
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
                          color: AppColors.primary.withValues(alpha: 0.7),
                          blurRadius: 6,
                        )
                      ]
                    : null,
              ),
            ),
          ],
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
        ..color = const Color(0xFF1E2A45).withValues(alpha: 0.7)
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
        ..color = AppColors.primary.withValues(alpha: 0.35)
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
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Syne',
                    height: 1,
                  ),
                ),
                Text(
                  '/$total',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Syne',
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
  const _SupplementsTab(
      {required this.onAddPressed, required this.onProfilePressed});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
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
            ],

            // States
            if (state is HomeLoadingState)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cargando suplementos...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (state is HomeEmptyState)
              SliverFillRemaining(child: _buildEmpty(context))
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
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Syne',
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
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Syne',
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (streak != null) StreakBadge(streak: streak),
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
                    AppColors.primary.withValues(alpha: 0.22),
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
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Syne',
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

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(scale: v.clamp(0.0, 1.5), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.gold.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sin suplementos aún',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toca el botón + para añadir\ntu primer suplemento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
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
    ('mañana',   Icons.wb_sunny_outlined,  'Mañana'),
    ('mediodía', Icons.wb_cloudy_outlined, 'Mediodía'),
    ('tarde',    Icons.cloud_outlined,     'Tarde'),
    ('noche',    Icons.nightlight_outlined,'Noche'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late String _selectedForm;
  late String _dosageUnit;
  late List<String> _schedules;
  late int _timesPerDay;
  TimeOfDay? _notificationTime;
  bool _saving = false;

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
    super.dispose();
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
      if (notifTime != null) {
        await localStorageDs.saveNotificationTime(supId, notifTime);
        await NotificationService.scheduleReminder(
          id: NotificationService.idFromSupplementId(supId),
          supplementName: supName,
          time: notifTime,
        );
      } else {
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
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.bgCardElevated,
            onSurface: AppColors.textPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColors.bgCard,
            dialBackgroundColor: AppColors.bgCardElevated,
            hourMinuteColor: AppColors.bgCardElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _notificationTime = picked);
  }

  void _snack(String msg, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? AppColors.error : isSuccess ? AppColors.success : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Editar configuración',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),

              _SectionLabel('Forma'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _allForms.map((f) {
                  final sel = _selectedForm == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedForm = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? AppGradients.brand : null,
                        color: sel ? null : AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                sel ? Colors.transparent : AppColors.border),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: Text(f,
                          style: TextStyle(
                            color:
                                sel ? Colors.white : AppColors.textSecondary,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 13,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Dosis'),
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

              _SectionLabel('Horarios'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _scheduleOptions.map((opt) {
                  final (value, icon, label) = opt;
                  final sel = _schedules.contains(value);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel) {
                        _schedules.remove(value);
                      } else {
                        _schedules.add(value);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? AppGradients.brand : null,
                        color: sel ? null : AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                sel ? Colors.transparent : AppColors.border),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8)
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon,
                              size: 14,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(label,
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Tomas por día'),
              const SizedBox(height: 8),
              if (_isPillUnit)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cada ${_dosageUnit == 'cápsulas' ? 'cápsula' : 'comprimido'} cuenta como 1 toma — total: $_computedTimesPerDay tomas al día',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ]),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _timesPerDay > 1
                            ? () => setState(() => _timesPerDay--)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                        color: _timesPerDay > 1
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      Text(
                        '$_timesPerDay ${_timesPerDay == 1 ? 'vez al día' : 'veces al día'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _timesPerDay < 20
                            ? () => setState(() => _timesPerDay++)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                        color: _timesPerDay < 20
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              _SectionLabel('Recordatorio'),
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
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
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
                      GestureDetector(
                        onTap: () =>
                            setState(() => _notificationTime = null),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 18),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _saving ? null : AppGradients.brand,
                    color: _saving ? AppColors.bgCardElevated : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _saving
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Guardar cambios',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
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
