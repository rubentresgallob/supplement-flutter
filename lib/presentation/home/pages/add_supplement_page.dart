import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/supplements_remote_datasource.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import '../../../data/models/supplement_database_model.dart';
import '../../../core/constants/app_constants.dart';
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
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Añadir Suplemento'),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgCardElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 15, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o categoría...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
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
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _loadCatalog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Reintentar',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
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
        GestureDetector(
          onTap: () => _openConfigure(
            name: '',
            availableForms: const [
              'pastilla', 'cápsula', 'polvo', 'líquido', 'gominola', 'gotas'
            ],
            isCustom: true,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0D00), Color(0xFF0F1623)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suplemento personalizado',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Añadir uno que no está en el catálogo',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
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

  static const _categoryColors = {
    'vitamina':   [Color(0xFF1A3A2A), Color(0xFF4ADE80)],
    'mineral':    [Color(0xFF1A2A3A), Color(0xFF60A5FA)],
    'proteína':   [Color(0xFF3A1A1A), Color(0xFFF87171)],
    'aminoácido': [Color(0xFF2A1A3A), Color(0xFFA78BFA)],
    'planta':     [Color(0xFF1A3A1A), Color(0xFF86EFAC)],
    'probiótico': [Color(0xFF3A2A1A), Color(0xFFFBBF24)],
    'ácido graso':[Color(0xFF1A2A3A), Color(0xFF38BDF8)],
    'coenzima':   [Color(0xFF3A1A2A), Color(0xFFF472B6)],
    'glicosaminoglicano': [Color(0xFF1A2A2A), Color(0xFF34D399)],
    'alga':       [Color(0xFF1A3A2A), Color(0xFF6EE7B7)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _categoryColors[supplement.category.toLowerCase()] ??
        [const Color(0xFF1A1A2A), AppColors.primary];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors[0],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: (colors[1] as Color).withValues(alpha: 0.3)),
              ),
              child: Icon(_icon(supplement.category),
                  color: colors[1] as Color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(supplement.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${supplement.category} · ${supplement.typicalDosage}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  IconData _icon(String category) {
    switch (category.toLowerCase()) {
      case 'vitamina': return Icons.water_drop_rounded;
      case 'mineral': return Icons.diamond_outlined;
      case 'proteína': return Icons.fitness_center_rounded;
      case 'aminoácido': return Icons.bolt_rounded;
      case 'planta': return Icons.eco_rounded;
      case 'probiótico': return Icons.bubble_chart_rounded;
      case 'ácido graso': return Icons.opacity_rounded;
      default: return Icons.medical_services_rounded;
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
    ('mañana',   Icons.wb_sunny_outlined,   'Mañana'),
    ('mediodía', Icons.wb_cloudy_outlined,  'Mediodía'),
    ('tarde',    Icons.cloud_outlined,      'Tarde'),
    ('noche',    Icons.nightlight_outlined, 'Noche'),
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
      backgroundColor: isError ? AppColors.error : isSuccess ? AppColors.success : null,
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
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.isCustom ? 'Suplemento personalizado' : widget.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              const SizedBox(height: 24),

              if (widget.isCustom) ...[
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Nombre', prefixIcon: Icon(Icons.medication_rounded)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
              ],

              _SectionLabel('Forma'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: widget.availableForms.map((f) {
                  final sel = _selectedForm == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedForm = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? AppGradients.brand : null,
                        color: sel ? null : AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? Colors.transparent : AppColors.border),
                        boxShadow: sel ? [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)] : [],
                      ),
                      child: Text(f, style: TextStyle(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Dosis'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
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
                      dropdownColor: AppColors.bgCardElevated,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      items: _dosageUnits.map((u) =>
                          DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (v) => setState(() => _dosageUnit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionLabel('Horarios'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _scheduleOptions.map((opt) {
                  final (value, icon, label) = opt;
                  final sel = _schedules.contains(value);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel) _schedules.remove(value); else _schedules.add(value);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: sel ? AppGradients.brand : null,
                        color: sel ? null : AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? Colors.transparent : AppColors.border),
                        boxShadow: sel ? [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)] : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 14,
                              color: sel ? Colors.white : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(label, style: TextStyle(
                            color: sel ? Colors.white : AppColors.textSecondary,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
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
                // Cápsulas/comprimidos: cada unidad = 1 toma (automático)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cada ${_dosageUnit == 'cápsulas' ? 'cápsula' : 'comprimido'} cuenta como 1 toma — total: $_computedTimesPerDay tomas al día',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Otras unidades: stepper manual
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        color: _timesPerDay > 1 ? AppColors.primary : AppColors.textMuted,
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
                        color: _timesPerDay < 20 ? AppColors.primary : AppColors.textMuted,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  child: Row(
                    children: [
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
                          onTap: () => setState(() => _notificationTime = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textMuted, size: 18),
                        ),
                    ],
                  ),
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
                    boxShadow: _saving ? [] : [BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Guardar suplemento',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 16)),
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
          fontSize: 12, fontWeight: FontWeight.w600,
          letterSpacing: 0.8));
}
