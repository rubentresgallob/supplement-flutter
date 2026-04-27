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
import 'add_supplement_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadSupplementsEvent());
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
    return Scaffold(
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
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.medication_outlined,
                activeIcon: Icons.medication_rounded,
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
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _openAddSupplement,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab de Suplementos ─────────────────────────────────────────────────────

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
        return CustomScrollView(
          slivers: [
            _buildAppBar(context),
            if (state is HomeLoadingState)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (state is HomeEmptyState)
              SliverFillRemaining(child: _buildEmpty(context))
            else if (state is HomeLoadedState) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: StreakBadge(streak: state.userStreak),
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
                        onMarkTaken: () => context
                            .read<HomeBloc>()
                            .add(HomeMarkIntakeTakenEvent(s.id)),
                        onMarkAllTaken: () => context
                            .read<HomeBloc>()
                            .add(HomeMarkAllIntakesTakenEvent(
                              s.id,
                              s.timesPerDay - taken,
                            )),
                      );
                    },
                    childCount: state.supplements.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ] else
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.bgDeep,
      floating: true,
      pinned: false,
      elevation: 0,
      expandedHeight: 110,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, authState) {
                            final username = authState is AuthAuthenticatedState
                                ? authState.user.username
                                : '';
                            return Text(
                              'Hola, $username 👋',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tus suplementos',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar → navega a perfil
                  GestureDetector(
                    onTap: onProfilePressed,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppGradients.brand,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final letter = state is AuthAuthenticatedState
                              ? state.user.username[0].toUpperCase()
                              : '?';
                          return Center(
                            child: Text(
                              letter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.bgCardElevated,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.medication_outlined,
                  size: 44, color: AppColors.textMuted),
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
    );
  }
}
