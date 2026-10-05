import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/supplements_remote_datasource.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import '../../../data/models/supplement_database_model.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../core/services/notification_service.dart';

class AddSupplementPage extends StatefulWidget {
  const AddSupplementPage({super.key});

  @override
  State<AddSupplementPage> createState() => _AddSupplementPageState();
}

class _AddSupplementPageState extends State<AddSupplementPage> {
  final _searchController = TextEditingController();
  List<SupplementDatabaseModel> _allSupplements = [];
  List<SupplementDatabaseModel> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await context.read<SupplementsRemoteDataSource>().getSupplementsDatabase();
      setState(() { _allSupplements = items; _filtered = items; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'No se pudo cargar el catálogo'; _isLoading = false; });
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allSupplements
          : _allSupplements.where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.category.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _openConfigure({
    String? supplementDatabaseId,
    required String name,
    required List<String> availableForms,
    String typicalDosage = '',
    bool isCustom = false,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfigureSheet(
        supplementDatabaseId: supplementDatabaseId,
        name: name,
        availableForms: availableForms,
        typicalDosage: typicalDosage,
        isCustom: isCustom,
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir suplemento'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xs),
            child: TextField(
              controller: _searchController,
              style: AppText.input,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o categoría',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppListSkeleton(itemCount: 7);
    if (_error != null) {
      return Center(
        child: AppEmpty(
          media: const Capsu(size: 90, mood: CapsuMood.sad),
          icon: LucideIcons.cloudOff,
          title: 'Sin conexión con el catálogo',
          description: 'Comprueba tu conexión e inténtalo de nuevo.',
          action: AppButton(
            label: 'Reintentar',
            icon: LucideIcons.refreshCw,
            variant: AppButtonVariant.outline,
            onPressed: _loadCatalog,
          ),
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: AppEmpty(
            media: const Capsu(size: 90, mood: CapsuMood.surprised),
            icon: LucideIcons.searchX,
            title: 'Sin resultados',
            description:
                'No encontramos "${_searchController.text}" en el catálogo. Puedes añadirlo como personalizado.',
            action: AppButton(
              label: 'Crear personalizado',
              icon: LucideIcons.plus,
              onPressed: () => _openConfigure(
                name: '',
                availableForms: const [
                  'pastilla', 'cápsula', 'polvo', 'líquido', 'gominola', 'gotas'
                ],
                isCustom: true,
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        ..._filtered.map((s) => _CatalogTile(
              supplement: s,
              onTap: () => _openConfigure(
                supplementDatabaseId: s.id,
                name: s.name,
                availableForms: s.forms,
                typicalDosage: s.typicalDosage,
              ),
            )),
        const SizedBox(height: 8),
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 8),
        // Personalizado
        PressableScale(
          scale: 0.98,
          onTap: () => _openConfigure(
            name: '',
            availableForms: const [
              'pastilla', 'cápsula', 'polvo', 'líquido', 'gominola', 'gotas'
            ],
            isCustom: true,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: AppDecorations.frame(border: AppColors.ring),
            child: Row(
              children: [
                const IconChip(
                    icon: LucideIcons.plus, size: 44, highlighted: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suplemento personalizado',
                          style: AppText.navTitle),
                      const SizedBox(height: 2),
                      Text('Añadir uno que no está en el catálogo',
                          style: AppText.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight,
                    color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CatalogTile extends StatelessWidget {
  final SupplementDatabaseModel supplement;
  final VoidCallback onTap;
  const _CatalogTile({required this.supplement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: AppDecorations.frame(),
        child: Row(
          children: [
            IconChip(icon: _icon(supplement.category), size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(supplement.name,
                      style: AppText.label),
                  const SizedBox(height: 2),
                  Text(
                    '${supplement.category} · ${supplement.typicalDosage}',
                    style: AppText.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _icon(String category) {
    switch (category.toLowerCase()) {
      case 'vitamina': return LucideIcons.droplet;
      case 'mineral': return LucideIcons.gem;
      case 'proteína': return LucideIcons.dumbbell;
      case 'aminoácido': return LucideIcons.zap;
      case 'planta': return LucideIcons.leaf;
      case 'probiótico': return LucideIcons.microscope;
      case 'ácido graso': return LucideIcons.droplets;
      default: return LucideIcons.stethoscope;
    }
  }
}

// ─── Bottom Sheet de configuración ──────────────────────────────────────────

class _ConfigureSheet extends StatefulWidget {
  final String? supplementDatabaseId;
  final String name;
  final List<String> availableForms;
  final String typicalDosage;
  final bool isCustom;

  const _ConfigureSheet({
    this.supplementDatabaseId,
    required this.name,
    required this.availableForms,
    required this.typicalDosage,
    required this.isCustom,
  });

  @override
  State<_ConfigureSheet> createState() => _ConfigureSheetState();
}

class _ConfigureSheetState extends State<_ConfigureSheet> {
  static const _dosageUnits = ['mg', 'g', 'µg', 'UI', 'ml', 'cápsulas', 'comprimidos'];
  static const _scheduleOptions = [
    ('mañana',   LucideIcons.sun,   'Mañana'),
    ('mediodía', LucideIcons.cloudSun,  'Mediodía'),
    ('tarde',    LucideIcons.sunset,      'Tarde'),
    ('noche',    LucideIcons.moon, 'Noche'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '1');
  String? _selectedForm;
  String _dosageUnit = 'mg';
  final List<String> _schedules = [];
  int _timesPerDay = 1;
  TimeOfDay? _notificationTime;
  bool _saving = false;

  // Para cápsulas/comprimidos, cada unidad = 1 toma
  bool get _isPillUnit =>
      _dosageUnit == 'cápsulas' || _dosageUnit == 'comprimidos';

  int get _computedTimesPerDay {
    if (_isPillUnit) {
      final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
      return (amount?.toInt() ?? 1).clamp(1, 99);
    }
    return _timesPerDay;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.name;
    if (widget.availableForms.isNotEmpty) _selectedForm = widget.availableForms.first;
    _parseDosage(widget.typicalDosage);
    // Rebuild cuando cambia la cantidad (para actualizar el contador de tomas en modo píldora)
    _amountCtrl.addListener(() => setState(() {}));
  }

  void _parseDosage(String d) {
    final m = RegExp(r'(\d+\.?\d*)').firstMatch(d);
    if (m != null) _amountCtrl.text = m.group(1)!;
    if (d.contains('µg')) _dosageUnit = 'µg';
    else if (d.contains(' g') || d.startsWith('g')) _dosageUnit = 'g';
    else if (d.contains('UI')) _dosageUnit = 'UI';
    else if (d.contains('ml')) _dosageUnit = 'ml';
  }

  @override
  void dispose() { _nameCtrl.dispose(); _amountCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedForm == null) { _snack('Selecciona la forma'); return; }
    if (_schedules.isEmpty) { _snack('Selecciona al menos un horario'); return; }
    setState(() => _saving = true);
    // Capturar referencias antes de los awaits para evitar uso de context tras gap async
    final supplementsDs = context.read<SupplementsRemoteDataSource>();
    final localStorageDs = context.read<LocalStorageDataSource>();
    final notifTime = _notificationTime;
    try {
      final saved = await supplementsDs.createUserSupplement(
        supplementDatabaseId: widget.supplementDatabaseId,
        customName: _nameCtrl.text.trim(),
        form: _selectedForm!,
        dosageAmount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
        dosageUnit: _dosageUnit,
        timesPerDay: _computedTimesPerDay,
        schedules: List.from(_schedules),
      );
      if (notifTime != null) {
        await localStorageDs.saveNotificationTime(saved.id, notifTime);
        await NotificationService.scheduleReminder(
          id: NotificationService.idFromSupplementId(saved.id),
          supplementName: saved.name,
          time: notifTime,
        );
      }
      if (mounted) { _snack('Suplemento añadido', isSuccess: true); Navigator.of(context).pop(true); }
    } catch (e) {
      if (mounted) { setState(() => _saving = false); _snack(e.toString(), isError: true); }
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
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                  ),
                ),
              ),
              Text(
                widget.isCustom ? 'Suplemento personalizado' : widget.name,
                style: AppText.question,
              ),
              const SizedBox(height: 24),

              if (widget.isCustom) ...[
                TextFormField(
                  controller: _nameCtrl,
                  style: AppText.input,
                  decoration: const InputDecoration(
                    labelText: 'Nombre', prefixIcon: Icon(LucideIcons.pill)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
              ],

              const _SectionLabel('Forma'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableForms
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
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountCtrl,
                      style: AppText.input,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: _dosageUnit,
                      dropdownColor: AppColors.surfaceRaised,
                      style: AppText.input,
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      items: _dosageUnits.map((u) =>
                          DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _dosageUnit = v!),
                    ),
                  ),
                ],
              ),
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
                // Cápsulas/comprimidos: cada unidad = 1 toma (automático)
                AppAlert(
                  message:
                      'Cada ${_dosageUnit == 'cápsulas' ? 'cápsula' : 'comprimido'} cuenta como 1 toma — total: $_computedTimesPerDay tomas al día',
                )
              else
                // Otras unidades: stepper manual
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
              PressableScale(
                onTap: _pickNotificationTime,
                scale: 0.98,
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.medium),
                  curve: AppMotion.standard,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg, vertical: AppSpace.sm),
                  constraints: const BoxConstraints(minHeight: 48),
                  decoration: BoxDecoration(
                    color: _notificationTime != null
                        ? AppColors.surfaceSelected
                        : AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadii.tile),
                    border: Border.all(
                      color: _notificationTime != null
                          ? AppColors.ring
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _notificationTime != null
                            ? LucideIcons.bellRing
                            : LucideIcons.bell,
                        color: _notificationTime != null
                            ? AppColors.accent
                            : AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _notificationTime != null
                              ? 'Recordatorio a las ${_notificationTime!.format(context)}'
                              : 'Sin recordatorio (toca para configurar)',
                          style: AppText.body.copyWith(color: _notificationTime != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                        ),
                      ),
                      if (_notificationTime != null)
                        SizedBox(
                          width: AppSpacing.minTouch,
                          height: AppSpacing.minTouch,
                          child: IconButton(
                            tooltip: 'Quitar recordatorio',
                            padding: EdgeInsets.zero,
                            onPressed: () => setState(() => _notificationTime = null),
                            icon: const Icon(LucideIcons.x,
                                color: AppColors.textMuted, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              AppButton(
                label: 'Guardar suplemento',
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppText.captionStrong.copyWith(color: AppColors.textSecondary));
}
