import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/design/design.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../data/datasources/friends_remote_datasource.dart';
import '../../../data/models/friend_profile.dart';
import '../../calendar/pages/calendar_page.dart';
import '../../rewards/bloc/rewards_cubit.dart';
import '../../rewards/widgets/rewards_widgets.dart';
import '../widgets/moderation_actions.dart';

/// Perfil de un amigo: su Capsu tal como lo lleva y, si los comparte, su progreso,
/// su stack de hoy y su calendario. Desde aquí se le puede bloquear o denunciar.
class FriendProfilePage extends StatefulWidget {
  final int friendId;
  final String username;
  final VoidCallback onMotivate;
  final VoidCallback onRemove;

  const FriendProfilePage({
    super.key,
    required this.friendId,
    required this.username,
    required this.onMotivate,
    required this.onRemove,
  });

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  FriendProfile? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final profile = await context
          .read<FriendsRemoteDataSource>()
          .getFriendProfile(widget.friendId);
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _openCalendar() {
    final source = context.read<FriendsRemoteDataSource>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CalendarPage(
        title: 'Calendario de ${widget.username}',
        loader: (year, month) =>
            source.getFriendCalendar(widget.friendId, year, month),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.username),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ModerationMenuButton(
            userId: widget.friendId,
            username: widget.username,
            onBlocked: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: _error != null
              ? Center(
                  child: AppEmpty(
                    icon: LucideIcons.cloudOff,
                    title: 'No se pudo cargar el perfil',
                    description: _error!,
                    action: AppButton(
                      label: 'Reintentar',
                      variant: AppButtonVariant.outline,
                      onPressed: _load,
                    ),
                  ),
                )
              : profile == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(AppSpace.screen,
                                AppSpace.sm, AppSpace.screen, AppSpace.xl),
                            children: [
                              _Hero(profile: profile),
                              const SizedBox(height: AppSpace.lg),
                              profile.sharesProgress
                                  ? _Stats(profile: profile)
                                  : _Today.note(
                                      LucideIcons.lock,
                                      '${profile.username} no comparte su progreso',
                                      'Si lo activa en su perfil, verás su racha y su cumplimiento.',
                                    ),
                              const SizedBox(height: AppSpace.xl),
                              const Text('Hoy', style: AppText.section),
                              const SizedBox(height: AppSpace.md),
                              _Today(profile: profile),
                              if (profile.sharesSupplements) ...[
                                const SizedBox(height: AppSpace.md),
                                AppButton(
                                  label: 'Ver su calendario',
                                  icon: LucideIcons.calendarDays,
                                  variant: AppButtonVariant.outline,
                                  expand: true,
                                  onPressed: _openCalendar,
                                ),
                              ],
                              const SizedBox(height: AppSpace.xl),
                              Center(
                                child: PressableScale(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    widget.onRemove();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpace.md),
                                    child: Text('Eliminar amigo',
                                        style: AppText.caption.copyWith(
                                          color: AppColors.danger,
                                        )),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        BottomActions(
                          children: [
                            AppButton(
                              label: 'Motivar',
                              icon: LucideIcons.smile,
                              size: AppButtonSize.lg,
                              expand: true,
                              onPressed: widget.onMotivate,
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

/// Su Capsu con lo que lleva puesto, sobre su banner, y su nombre con su medalla.
class _Hero extends StatelessWidget {
  final FriendProfile profile;
  const _Hero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rewards = context.watch<RewardsCubit>().state;
    final medal = rewards.item(profile.equipped['medal']);
    final bannerCode = profile.equipped['banner'];
    final hasBanner = bannerCode != null && ShopRender.rendered.contains(bannerCode);
    final since = profile.memberSince;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        decoration: const BoxDecoration(gradient: AppGradients.card),
        child: Stack(
          children: [
            if (hasBanner) ...[
              Positioned.fill(
                child: Image.asset(
                  ShopRender.assetOf(bannerCode),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              // Oscurece el banner hacia abajo para que se lea el texto
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.scrim, AppColors.surface],
                      stops: [0, 0.85],
                    ),
                  ),
                ),
              ),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                children: [
                  HeroGlow(
                    size: 190,
                    child: Floating(
                      amplitude: 5,
                      child: Capsu(
                        size: 132,
                        mood: CapsuMood.wave,
                        outfit: CapsuOutfit.fromEquipped(profile.equipped),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(profile.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title),
                      ),
                      if (medal != null) ...[
                        const SizedBox(width: AppSpace.sm),
                        Tooltip(
                          message: medal.name,
                          child: MedalIcon(medal: medal, size: 30),
                        ),
                      ],
                    ],
                  ),
                  if (since != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text('En la app desde ${_monthYear(since)}',
                        textAlign: TextAlign.center, style: AppText.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthYear(DateTime d) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${months[d.month - 1]} de ${d.year}';
  }
}

class _Stats extends StatelessWidget {
  final FriendProfile profile;
  const _Stats({required this.profile});

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label, IconData icon) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            child: Column(
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(height: AppSpace.xs),
              Text(value, style: AppText.display),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, style: AppText.caption),
              ),
            ],
          ),
          ),
        );
    return GlassCard(
      child: Row(
        children: [
          stat('${profile.currentStreak ?? 0}', 'días de racha', LucideIcons.flame),
          stat('${profile.longestStreak ?? 0}', 'mejor racha', LucideIcons.trophy),
          stat('${profile.adherence30Days ?? 0}%', 'últimos 30 días', LucideIcons.chartColumn),
        ],
      ),
    );
  }
}

/// Su stack con lo que lleva tomado hoy (si lo comparte).
class _Today extends StatelessWidget {
  final FriendProfile profile;
  const _Today({required this.profile});

  @override
  Widget build(BuildContext context) {
    final today = profile.today;
    if (!profile.sharesSupplements || today == null) {
      return note(
        LucideIcons.lock,
        '${profile.username} no comparte sus suplementos',
        'Si lo activa en su perfil, verás lo que toma hoy y su calendario.',
      );
    }
    if (today.isEmpty) {
      return note(LucideIcons.pill, 'Aún no tiene suplementos',
          'Cuando añada alguno, lo verás aquí.');
    }

    final pending = profile.pendingToday;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: AppDecorations.frame(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pending.isEmpty
                      ? 'Lo ha tomado todo'
                      : 'Le ${pending.length == 1 ? 'falta' : 'faltan'} ${pending.map((s) => s.name).join(', ')}',
                  style: AppText.label,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Text('${profile.takenToday} de ${profile.expectedToday}',
                  style: AppText.captionStrong.copyWith(
                      color: pending.isEmpty
                          ? AppColors.mint
                          : AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          FlowProgress(
            value: profile.expectedToday == 0
                ? 0
                : profile.takenToday / profile.expectedToday,
            height: 3,
          ),
          const SizedBox(height: AppSpace.sm),
          for (final s in today) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Row(
                children: [
                  Icon(
                    s.complete
                        ? LucideIcons.circleCheck
                        : s.taken > 0
                            ? LucideIcons.circleDashed
                            : LucideIcons.circle,
                    size: 18,
                    color: s.complete
                        ? AppColors.mint
                        : s.taken > 0
                            ? AppColors.accent
                            : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label),
                        Text(s.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.micro),
                      ],
                    ),
                  ),
                  Text('${s.taken} de ${s.expected}',
                      style: AppText.captionStrong
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget note(IconData icon, String title, String body) => Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: AppDecorations.frame(),
        child: Row(
          children: [
            IconChip(icon: icon),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.label),
                  const SizedBox(height: 2),
                  Text(body, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      );
}
