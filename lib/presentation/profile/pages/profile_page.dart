import '../../rewards/widgets/rewards_widgets.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/ui/ui.dart';
import '../widgets/delete_account.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../data/datasources/friends_remote_datasource.dart';
import '../../../core/utils/legal_links.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_state.dart';
import '../../onboarding/pages/onboarding_page.dart';
import '../../rewards/bloc/rewards_cubit.dart';
import '../../../core/widgets/mascot/capsu.dart';

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

  bool _exporting = false;

  /// Descarga (web) o comparte (móvil) un archivo JSON con todos los datos
  /// del usuario: es su derecho de portabilidad.
  Future<void> _exportData(BuildContext tileContext) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final box = tileContext.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final data = await context.read<AuthRemoteDataSource>().exportData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(json)),
            mimeType: 'application/json',
            name: _exportFileName,
          ),
        ],
        fileNameOverrides: const [_exportFileName],
        downloadFallbackEnabled: true,
        sharePositionOrigin: origin,
      ));
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  static const _exportFileName = 'mis-datos-suplementacion.json';

  Future<void> _deleteAccount() => confirmAndDeleteAccount(context);

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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                    padding: EdgeInsets.fromLTRB(AppSpace.screen, 16, AppSpace.screen, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mi cuenta',
                            style: AppText.body),
                        SizedBox(height: 2),
                        Text('Perfil',
                            style: AppText.title),
                      ],
                    ),
                  ),
            ),

            // Avatar + info
            SliverToBoxAdapter(
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
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
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
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              // Rotating ring avatar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _Avatar(letter: user.username[0].toUpperCase()),
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
                                  Text(user.username, style: AppText.question),
                                  if (medal != null) ...[
                                    const SizedBox(width: AppSpace.sm),
                                    Tooltip(
                                      message: medal.name,
                                      child: MedalIcon(medal: medal, size: 26),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(user.email,
                                  style: AppText.body),
                              const SizedBox(height: 4),
                              Text(
                                'Miembro desde ${_formatDate(user.createdAt)}',
                                style: AppText.caption,
                              ),
                              const SizedBox(height: 16),
                              PressableScale(
                                onTap: _editBio,
                                scale: 0.98,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.md, vertical: AppSpace.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceRaised,
                                    borderRadius: BorderRadius.circular(AppRadii.tile),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _bio.isEmpty
                                              ? 'Añade una descripción'
                                              : _bio,
                                          style: AppText.body.copyWith(color: _bio.isEmpty
                                                ? AppColors.textMuted
                                                : AppColors.textSecondary),
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

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Mis estadísticas',
                              style: AppText.label.copyWith(color: AppColors.textSecondary)),
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
                                        labelColor: AppColors.accent,
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
                                  unit: 'puntos',
                                ),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Ajustes',
                              style: AppText.label.copyWith(color: AppColors.textSecondary)),
                        ),
                        Container(
                          decoration: AppDecorations.frame(),
                          child: Column(
                            children: [
                              const _SharingTile(),
                              const Divider(indent: 64),
                              _SettingsTile(
                                icon: LucideIcons.bell,
                                label: 'Notificaciones',
                                trailing: const Icon(
                                    LucideIcons.chevronRight,
                                    color: AppColors.textMuted),
                                onTap: () {},
                              ),
                              const Divider(indent: 64),
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
                              const Divider(indent: 64),
                              _SettingsTile(
                                icon: LucideIcons.shieldCheck,
                                label: 'Política de privacidad',
                                trailing: const Icon(LucideIcons.externalLink,
                                    color: AppColors.textMuted, size: 16),
                                onTap: () =>
                                    openLegalPage(context, LegalPage.privacy),
                              ),
                              const Divider(indent: 64),
                              _SettingsTile(
                                icon: LucideIcons.fileText,
                                label: 'Términos de uso',
                                trailing: const Icon(LucideIcons.externalLink,
                                    color: AppColors.textMuted, size: 16),
                                onTap: () =>
                                    openLegalPage(context, LegalPage.terms),
                              ),
                              const Divider(indent: 64),
                              Builder(
                                builder: (tileContext) => _SettingsTile(
                                  icon: LucideIcons.download,
                                  label: 'Descargar mis datos',
                                  trailing: _exporting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(LucideIcons.chevronRight,
                                          color: AppColors.textMuted),
                                  onTap: () => _exportData(tileContext),
                                ),
                              ),
                              const Divider(indent: 64),
                              _SettingsTile(
                                icon: LucideIcons.info,
                                label: 'Versión de la app',
                                trailing: Text('1.0.0',
                                    style: AppText.body.copyWith(color: AppColors.textMuted)),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                    child: AppButton(
                      label: 'Cerrar sesión',
                      icon: LucideIcons.logOut,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.lg,
                      expand: true,
                      onPressed: () =>
                          context.read<AuthBloc>().add(AuthLogoutEvent()),
                    ),
                  ),
            ),

            // Eliminar cuenta (discreto, debajo de cerrar sesión)
            SliverToBoxAdapter(
              child: Center(
                child: PressableScale(
                  onTap: _deleteAccount,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Text(
                      'Eliminar mi cuenta',
                      style: AppText.caption.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textTertiary,
                      ),
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

class _Avatar extends StatelessWidget {
  final String letter;
  const _Avatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
            colors: [...AppColors.iridescent, AppColors.iridescent.first]),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
        ),
        child: Text(letter, style: AppText.display),
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
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: AppDecorations.frame(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.caption.copyWith(color: labelColor),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: AppMotion.of(context, AppMotion.slow),
            curve: AppMotion.standard,
            builder: (_, v, __) => RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${v.round()}',
                    style: AppText.display,
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: AppText.body,
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
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: AppDecorations.frame(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.caption,
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: AppMotion.of(context, AppMotion.slow),
                curve: AppMotion.standard,
                builder: (_, v, __) => RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${v.round()}',
                        style: AppText.display,
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: AppText.label.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Icon(LucideIcons.pill, size: 28, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

/// Interruptor: ¿ven mis amigos mi stack, lo que tomo hoy y mi calendario?
class _SharingTile extends StatefulWidget {
  const _SharingTile();

  @override
  State<_SharingTile> createState() => _SharingTileState();
}

class _SharingTileState extends State<_SharingTile> {
  /// `null` mientras se carga.
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await context.read<FriendsRemoteDataSource>().getSharing();
      if (mounted) setState(() => _enabled = enabled);
    } catch (_) {
      // Sin conexión: se queda deshabilitado hasta que se pueda leer
    }
  }

  Future<void> _toggle() async {
    final current = _enabled;
    if (current == null) return;
    setState(() => _enabled = !current);
    try {
      await context.read<FriendsRemoteDataSource>().setSharing(!current);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enabled = current);
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return Semantics(
      button: true,
      toggled: enabled ?? false,
      enabled: enabled != null,
      label: 'Compartir con mis amigos mi stack y mi calendario',
      excludeSemantics: true,
      child: PressableScale(
        onTap: enabled == null ? null : _toggle,
        scale: 0.98,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.md),
          child: Row(
            children: [
              const IconChip(icon: LucideIcons.usersRound),
              const SizedBox(width: AppSpace.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compartir con mis amigos', style: AppText.label),
                    SizedBox(height: 2),
                    Text('Ven tu stack, lo que tomas hoy y tu calendario',
                        style: AppText.micro),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              _Switch(on: enabled ?? false, loading: enabled == null),
            ],
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final bool on;
  final bool loading;
  const _Switch({required this.on, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: loading ? 0.4 : 1,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.medium),
        curve: AppMotion.standard,
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on ? AppColors.accentStrong : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: on ? AppColors.accentStrong : AppColors.border),
        ),
        child: AnimatedAlign(
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.standard,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ),
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
    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        child: Row(
          children: [
            IconChip(icon: icon),
            const SizedBox(width: AppSpace.md),
            Expanded(child: Text(label, style: AppText.label)),
            trailing,
          ],
        ),
      ),
    );
  }
}
