import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/pro_remote_datasource.dart';
import '../../../data/models/pro_models.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/pro_cubit.dart';
import 'pro_page.dart';
import 'stats_pdf.dart';

/// Estadísticas avanzadas (Pro). Sin Pro se ve una vista previa borrosa.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  static const _periods = [(7, '7 días'), (30, '30 días'), (90, '3 meses'), (365, '1 año')];

  int _days = 30;
  StatsReport? _report;
  bool _loading = false;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (context.read<ProCubit>().state.isPro) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await context.read<ProRemoteDataSource>().getStats(_days);
      if (mounted) setState(() => _report = report);
    } on ProRequiredException {
      if (mounted) setState(() => _report = null);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    final report = _report;
    if (report == null) return;
    final auth = context.read<AuthBloc>().state;
    final username = auth is AuthAuthenticatedState ? auth.user.username : '';
    setState(() => _exporting = true);
    try {
      final bytes = await buildStatsPdf(report, username);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'informe-suplementos-${report.to.year}-${report.to.month}-${report.to.day}.pdf',
      );
    } catch (e) {
      if (mounted) AppToast.error(context, 'No se pudo crear el PDF');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProCubit, ProState>(
      listenWhen: (a, b) => a.isPro != b.isPro,
      listener: (context, state) {
        if (state.isPro) _load();
      },
      builder: (context, pro) {
        return Scaffold(
          backgroundColor: AppColors.bgDeep,
          appBar: AppBar(
            title: const Text('Estadísticas'),
            actions: [
              if (pro.isPro && _report != null)
                IconButton(
                  tooltip: 'Exportar PDF',
                  onPressed: _exporting ? null : _exportPdf,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        )
                      : const Icon(LucideIcons.fileDown),
                ),
            ],
          ),
          body: pro.isPro ? _content() : _locked(),
        );
      },
    );
  }

  Widget _locked() {
    return Stack(
      children: [
        // Vista previa con datos de ejemplo, borrosa
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: IgnorePointer(child: _body(_sampleReport)),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.frame(color: AppColors.bgCardElevated),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Capsu(size: 80, mood: CapsuMood.thinking, interactive: false),
                const SizedBox(height: 8),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Estadísticas avanzadas',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 6),
                    ProBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Calendario de cumplimiento, tus mejores días e informe en PDF para tu médico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Desbloquear con Pro',
                  icon: LucideIcons.crown,
                  onPressed: () => openProPage(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _content() {
    if (_loading && _report == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_error != null && _report == null) {
      return Center(
        child: AppEmpty(
          icon: LucideIcons.chartColumn,
          title: 'No se pudieron cargar',
          description: _error!,
          action: AppButton(label: 'Reintentar', onPressed: _load),
        ),
      );
    }
    final report = _report;
    if (report == null) return const SizedBox.shrink();
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: _body(report),
    );
  }

  Widget _body(StatsReport r) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (days, label) in _periods) ...[
                AppToggleChip(
                  label: label,
                  selected: _days == days,
                  onChanged: (_) {
                    setState(() => _days = days);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Tile(label: 'Cumplimiento', value: '${r.adherence}%', color: AppColors.success),
            const SizedBox(width: 10),
            _Tile(label: 'Días completos', value: '${r.completeDays}/${r.totalDays}'),
            const SizedBox(width: 10),
            _Tile(label: 'Mejor racha', value: '${r.longestStreak}d', color: AppColors.gold),
          ],
        ),
        if (r.bestWeekday != null) ...[
          const SizedBox(height: 12),
          _Insight(
            text: r.worstWeekday != null
                ? 'Tu mejor día es el ${r.bestWeekday!.toLowerCase()}. El ${r.worstWeekday!.toLowerCase()} es cuando más se te olvida: pon un recordatorio extra 💡'
                : 'Tu mejor día es el ${r.bestWeekday!.toLowerCase()}. ¡Sigue así!',
          ),
        ],
        const SizedBox(height: 20),
        const _Title('Calendario'),
        const SizedBox(height: 10),
        _Heatmap(days: r.days),
        const SizedBox(height: 22),
        const _Title('Por suplemento'),
        const SizedBox(height: 6),
        for (final s in r.supplements) _Bar(label: s.name, percent: s.adherence),
        if (r.supplements.isEmpty)
          const Text('Aún no tienes suplementos activos.',
              style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 22),
        const _Title('Por día de la semana'),
        const SizedBox(height: 10),
        _WeekdayChart(weekdays: r.weekdays),
      ],
    );
  }
}

// Datos de ejemplo para la vista previa borrosa (sin Pro)
final _sampleReport = StatsReport(
  periodDays: 30,
  from: DateTime(2026, 9, 2),
  to: DateTime(2026, 10, 1),
  days: List.generate(
    30,
    (i) => StatsDay(
      date: DateTime(2026, 9, 2).add(Duration(days: i)),
      taken: i % 6 == 0 ? 1 : 3,
      expected: 3,
      complete: i % 6 != 0,
    ),
  ),
  supplements: const [
    StatsSupplement(name: 'Creatina', taken: 29, expected: 30, adherence: 97),
    StatsSupplement(name: 'Vitamina D', taken: 26, expected: 30, adherence: 87),
    StatsSupplement(name: 'Omega 3', taken: 21, expected: 30, adherence: 70),
  ],
  weekdays: const [
    StatsWeekday(weekday: 'Lunes', completionRate: 100, days: 4),
    StatsWeekday(weekday: 'Martes', completionRate: 90, days: 4),
    StatsWeekday(weekday: 'Miércoles', completionRate: 95, days: 4),
    StatsWeekday(weekday: 'Jueves', completionRate: 85, days: 4),
    StatsWeekday(weekday: 'Viernes', completionRate: 75, days: 4),
    StatsWeekday(weekday: 'Sábado', completionRate: 60, days: 4),
    StatsWeekday(weekday: 'Domingo', completionRate: 50, days: 4),
  ],
  adherence: 86,
  completeDays: 25,
  totalDays: 30,
  intakes: 80,
  currentStreak: 5,
  longestStreak: 12,
  bestWeekday: 'Lunes',
  worstWeekday: 'Domingo',
);

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700));
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Tile({required this.label, required this.value, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppDecorations.frame(radius: AppRadius.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  final String text;
  const _Insight({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
    );
  }
}

/// Un cuadrado por día: más intenso cuanto más se cumplió.
class _Heatmap extends StatelessWidget {
  final List<StatsDay> days;
  const _Heatmap({required this.days});

  @override
  Widget build(BuildContext context) {
    final big = days.length <= 31;
    final size = big ? 34.0 : (days.length <= 90 ? 16.0 : 9.0);
    return Wrap(
      spacing: big ? 6 : 3,
      runSpacing: big ? 6 : 3,
      children: [
        for (final d in days)
          Tooltip(
            message: '${d.date.day}/${d.date.month}: ${d.taken} de ${d.expected} tomas',
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: d.expected == 0
                    ? AppColors.input
                    : d.complete
                        ? AppColors.success
                        : Color.lerp(AppColors.input, AppColors.accent, d.ratio),
                borderRadius: BorderRadius.circular(big ? 8 : 2),
              ),
              child: big
                  ? Text('${d.date.day}',
                      style: TextStyle(
                        color: d.complete ? AppColors.onPrimary : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ))
                  : null,
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int percent;
  const _Bar({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? AppColors.success
        : percent >= 50
            ? AppColors.warning
            : AppColors.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              Text('$percent%',
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 7,
              backgroundColor: AppColors.input,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Iniciales españolas: L M X J V S D (X = miércoles).
String _initial(String weekday) => switch (weekday) {
      'Miércoles' => 'X',
      _ => weekday.substring(0, 1),
    };

class _WeekdayChart extends StatelessWidget {
  final List<StatsWeekday> weekdays;
  const _WeekdayChart({required this.weekdays});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final w in weekdays)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(w.days == 0 ? '-' : '${w.completionRate}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(height: 4),
                    Container(
                      height: 80 * (w.completionRate / 100) + 2,
                      decoration: BoxDecoration(
                        gradient: AppGradients.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_initial(w.weekday),
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
