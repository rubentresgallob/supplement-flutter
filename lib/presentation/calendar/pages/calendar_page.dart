import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/design/design.dart';
import '../../../data/datasources/intakes_remote_datasource.dart';
import '../../../data/models/calendar_models.dart';

/// Calendario de progreso: qué días se completó todo, cuáles a medias y
/// cuáles se quedaron sin tomar, con el detalle de cada día.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const CalendarPage()));

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _weekdayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  CalendarMonth? _data;
  bool _loading = true;
  String? _error;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final month = _month;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context
          .read<IntakesRemoteDataSource>()
          .getCalendar(month.year, month.month);
      if (!mounted || month != _month) return; // llegó tarde: ya se cambió de mes
      setState(() {
        _data = data;
        _loading = false;
        // Por defecto, hoy (si está en este mes)
        final today = data.today;
        _selected = today.year == month.year && today.month == month.month
            ? today
            : null;
      });
    } catch (e) {
      if (!mounted || month != _month) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _go(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = null;
    });
    _load();
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  bool get _canGoBack {
    final first = _data?.firstTracked;
    if (first == null) return false;
    return _month.isAfter(DateTime(first.year, first.month));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xxl),
          children: [
            _MonthSwitcher(
              label: '${_capitalize(_months[_month.month - 1])} ${_month.year}',
              onPrevious: _canGoBack && !_loading ? () => _go(-1) : null,
              onNext: _canGoNext && !_loading ? () => _go(1) : null,
            ),
            const SizedBox(height: AppSpace.lg),
            if (_error != null)
              AppEmpty(
                icon: LucideIcons.cloudOff,
                title: 'No se pudo cargar el calendario',
                description: _error!,
                action: AppButton(
                  label: 'Reintentar',
                  variant: AppButtonVariant.outline,
                  onPressed: _load,
                ),
              )
            else if (data == null)
              const Padding(
                padding: EdgeInsets.only(top: AppSpace.xxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              AnimatedOpacity(
                duration: AppMotion.of(context, AppMotion.fast),
                opacity: _loading ? 0.4 : 1,
                child: _MonthGrid(
                  data: data,
                  selected: _selected,
                  onSelect: (d) => setState(() => _selected = d),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              const _Legend(),
              const SizedBox(height: AppSpace.lg),
              _Summary(data: data),
              const SizedBox(height: AppSpace.lg),
              _DayDetail(
                day: _selected == null
                    ? null
                    : data.days
                        .where((d) => DateUtils.isSameDay(d.date, _selected))
                        .firstOrNull,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  const _MonthSwitcher({required this.label, this.onPrevious, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          onPressed: onPrevious,
          disabledColor: AppColors.textTertiary,
          icon: const Icon(LucideIcons.chevronLeft),
        ),
        Expanded(
          child: Text(label, textAlign: TextAlign.center, style: AppText.question),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          onPressed: onNext,
          disabledColor: AppColors.textTertiary,
          icon: const Icon(LucideIcons.chevronRight),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final CalendarMonth data;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  const _MonthGrid({required this.data, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final leading = DateTime(data.year, data.month, 1).weekday - 1; // lunes = 0
    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (final day in data.days)
        _DayCell(
          day: day,
          isToday: DateUtils.isSameDay(day.date, data.today),
          selected: DateUtils.isSameDay(day.date, selected),
          onTap: day.status == CalendarDayStatus.future ||
                  day.status == CalendarDayStatus.none
              ? null
              : () => onSelect(day.date),
        ),
    ];
    return Column(
      children: [
        Row(
          children: [
            for (final d in _weekdayInitials)
              Expanded(
                child: Text(d, textAlign: TextAlign.center, style: AppText.micro),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.xs,
          crossAxisSpacing: AppSpace.xs,
          children: cells,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isToday;
  final bool selected;
  final VoidCallback? onTap;
  const _DayCell({required this.day, required this.isToday, required this.selected, this.onTap});

  String get _semantics {
    final date = '${day.date.day} de ${_months[day.date.month - 1]}';
    return switch (day.status) {
      CalendarDayStatus.complete => '$date, completo',
      CalendarDayStatus.partial => '$date, ${day.taken} de ${day.expected} tomas',
      CalendarDayStatus.missed => '$date, sin tomar',
      CalendarDayStatus.pending => '$date, hoy, sin empezar',
      _ => date,
    };
  }

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color text) = switch (day.status) {
      CalendarDayStatus.complete => (AppColors.mint, AppColors.background),
      CalendarDayStatus.missed => (AppColors.danger.withValues(alpha: 0.16), AppColors.danger),
      CalendarDayStatus.partial => (AppColors.surfaceRaised, AppColors.textPrimary),
      CalendarDayStatus.pending => (AppColors.surfaceRaised, AppColors.textPrimary),
      _ => (Colors.transparent, AppColors.textTertiary),
    };

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: _semantics,
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        scale: 0.92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: selected
                      ? AppColors.textPrimary
                      : isToday
                          ? AppColors.borderStrong
                          : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
            if (day.status == CalendarDayStatus.partial)
              // Anillo con la parte del día que sí se tomó
              Padding(
                padding: const EdgeInsets.all(5),
                child: CircularProgressIndicator(
                  value: day.expected == 0 ? 0 : day.taken / day.expected,
                  strokeWidth: 2,
                  color: AppColors.accent,
                  backgroundColor: AppColors.border,
                ),
              ),
            Text('${day.date.day}',
                style: AppText.captionStrong.copyWith(color: text)),
            if (day.isProtected)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(LucideIcons.shieldCheck, size: 12, color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label, {bool ring = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ring ? Colors.transparent : color,
                border: ring ? Border.all(color: color, width: 2) : null,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Text(label, style: AppText.micro),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpace.lg,
      runSpacing: AppSpace.sm,
      children: [
        item(AppColors.mint, 'Completo'),
        item(AppColors.accent, 'A medias', ring: true),
        item(AppColors.danger, 'Sin tomar'),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shieldCheck, size: 12, color: AppColors.accent),
            SizedBox(width: AppSpace.xs),
            Text('Protector', style: AppText.micro),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final CalendarMonth data;
  const _Summary({required this.data});

  @override
  Widget build(BuildContext context) {
    Widget stat(int value, String label, Color color) => Expanded(
          child: Column(
            children: [
              Text('$value', style: AppText.display.copyWith(color: color)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, style: AppText.caption),
              ),
            ],
          ),
        );
    return GlassCard(
      child: Row(
        children: [
          stat(data.completeDays, 'completos', AppColors.mint),
          stat(data.partialDays, 'a medias', AppColors.accent),
          stat(data.missedDays, 'sin tomar', AppColors.danger),
        ],
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  final CalendarDay? day;
  const _DayDetail({required this.day});

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    if (day == null) {
      return const Text(
        'Toca un día para ver qué tomaste y qué te faltó.',
        textAlign: TextAlign.center,
        style: AppText.body,
      );
    }
    final title =
        '${_capitalize(_weekdays[day.date.weekday - 1])} ${day.date.day} de ${_months[day.date.month - 1]}';
    final missing = day.missing;
    final String subtitle = switch (day.status) {
      CalendarDayStatus.complete => 'Día completo',
      CalendarDayStatus.pending => 'Hoy todavía no has registrado nada',
      CalendarDayStatus.missed => 'No registraste ninguna toma',
      _ => 'Te ${missing.length == 1 ? 'faltó' : 'faltaron'} ${missing.map((s) => s.name).join(', ')}',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: AppDecorations.frame(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.section),
          const SizedBox(height: 2),
          Text(subtitle, style: AppText.body),
          if (day.isProtected) ...[
            const SizedBox(height: AppSpace.sm),
            const Row(
              children: [
                Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.accent),
                SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text('Un protector salvó tu racha este día',
                      style: AppText.brandSubtitle),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          for (final s in day.supplements) ...[
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
                            : LucideIcons.circleX,
                    size: 18,
                    color: s.complete
                        ? AppColors.mint
                        : s.taken > 0
                            ? AppColors.accent
                            : AppColors.danger,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label),
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
}
