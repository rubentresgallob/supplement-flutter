import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _bio = '';

  @override
  void initState() {
    super.initState();
    _bio = context.read<LocalStorageDataSource>().getBio();
  }

  Future<void> _editBio() async {
    final ctrl = TextEditingController(text: _bio);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tu descripción',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                maxLength: 150,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Cuéntale a tus amigos sobre ti...',
                  counterStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                          child: Text('Cancelar',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: Text('Guardar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      final ls = context.read<LocalStorageDataSource>();
      await ls.saveBio(result);
      setState(() => _bio = result);
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
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mi cuenta',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Perfil',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),
            ),

            // Avatar + info card
            SliverToBoxAdapter(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is! AuthAuthenticatedState) return const SizedBox();
                  final user = state.user;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppGradients.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppGradients.brand,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(user.username,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text(user.email,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Miembro desde ${_formatDate(user.createdAt)}',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
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
                                border: Border.all(color: AppColors.border),
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
                                  const Icon(Icons.edit_rounded,
                                      size: 14, color: AppColors.textMuted),
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

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Stats
            SliverToBoxAdapter(
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
                          supplementCount = homeState.supplements.length;
                          streakDays = homeState.userStreak.currentStreak;
                          longestStreak = homeState.userStreak.longestStreak;
                        }
                        return Row(
                          children: [
                            Expanded(
                                child: _StatCard(
                              icon: Icons.medication_rounded,
                              value: '$supplementCount',
                              label: 'Suplementos',
                              color: AppColors.primary,
                            )),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _StatCard(
                              icon: Icons.local_fire_department_rounded,
                              value: '$streakDays',
                              label: 'Racha actual',
                              color: AppColors.gold,
                            )),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _StatCard(
                              icon: Icons.emoji_events_rounded,
                              value: '$longestStreak',
                              label: 'Mejor racha',
                              color: AppColors.success,
                            )),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Ajustes
            SliverToBoxAdapter(
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
                            icon: Icons.notifications_outlined,
                            label: 'Notificaciones',
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textMuted),
                            onTap: () {},
                          ),
                          const Divider(
                              height: 1, color: AppColors.border, indent: 52),
                          _SettingsTile(
                            icon: Icons.info_outline_rounded,
                            label: 'Versión de la app',
                            trailing: const Text('1.0.0',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Cerrar sesión
            SliverToBoxAdapter(
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
                        Icon(Icons.logout_rounded,
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

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
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
  const _SettingsTile(
      {required this.icon,
      required this.label,
      required this.trailing,
      required this.onTap});

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
              child: Icon(icon, color: AppColors.textSecondary, size: 18),
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
