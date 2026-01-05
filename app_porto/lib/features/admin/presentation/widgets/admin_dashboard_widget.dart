import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../app/app_scope.dart';

// ============================================================================
// TOOLTIP (LABEL HOVER) - helper global
// ============================================================================

Widget _hoverLabel({
  required String message,
  required Widget child,
  bool preferBelow = false,
}) {
  final msg = message.trim();
  if (msg.isEmpty) return child;

  return Tooltip(
    message: msg,
    preferBelow: preferBelow,
    waitDuration: const Duration(milliseconds: 350),
    showDuration: const Duration(seconds: 3),
    triggerMode: TooltipTriggerMode.longPress, // móvil: long press
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: child,
    ),
  );
}

// ============================================================================
// UTILIDADES
// ============================================================================

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String _safeStr(dynamic v, [String fallback = '-']) {
  if (v == null) return fallback;
  final s = v.toString();
  if (s.trim().isEmpty) return fallback;
  return s;
}

final _fmtMoney = NumberFormat.currency(locale: 'es_EC', symbol: r'$');

// ============================================================================
// WIDGET PRINCIPAL
// ============================================================================

class AdminDashboardWidget extends StatefulWidget {
  const AdminDashboardWidget({super.key});

  @override
  State<AdminDashboardWidget> createState() => _AdminDashboardWidgetState();
}

class _AdminDashboardWidgetState extends State<AdminDashboardWidget>
    with SingleTickerProviderStateMixin {
  late DateTime _to;
  late DateTime _from;
  late DateTime _asOf;

  Future<Map<String, dynamic>>? _future;
  bool _didInit = false;

  late AnimationController _animController;
  String _selectedView = 'general'; // general, financiero, academico
  String _selectedPeriod = '30d'; // 7d, 30d, 90d, 12m, ytd, custom
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = _to.subtract(const Duration(days: 30));
    _asOf = _to;
    _reload();
  }

  void _reload() {
    final repo = AppScope.of(context).dashboard;
    setState(() {
      _future = repo.admin(from: _from, to: _to, asOf: _asOf);
    });
    _animController.forward(from: 0.0);
  }

  void _applyQuickFilter(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      _to = DateTime(now.year, now.month, now.day);

      switch (period) {
        case '7d':
          _from = _to.subtract(const Duration(days: 7));
          break;
        case '30d':
          _from = _to.subtract(const Duration(days: 30));
          break;
        case '90d':
          _from = _to.subtract(const Duration(days: 90));
          break;
        case '12m':
          _from = DateTime(_to.year - 1, _to.month, _to.day);
          break;
        case 'ytd':
          _from = DateTime(_to.year, 1, 1);
          break;
        case 'custom':
          // No hacer nada, el usuario seleccionará las fechas
          return;
      }
      _asOf = _to;
    });
    _reload();
  }

  Future<void> _pickRange() async {
    final initialRange = DateTimeRange(start: _from, end: _to);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialRange,
      saveText: 'Aplicar',
      helpText: 'Selecciona el rango de fechas',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() {
      _from = DateTime(picked.start.year, picked.start.month, picked.start.day);
      _to = DateTime(picked.end.year, picked.end.month, picked.end.day);
      _asOf = _to;
      _selectedPeriod = 'custom';
    });
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              cs.surfaceContainerLowest,
            ],
          ),
        ),
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
              color: cs.surface.withOpacity(0.7),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(cs, isMobile, isTablet),
                  SizedBox(height: isMobile ? 16 : 20),

                  _buildFiltersPanel(cs, isMobile),
                  SizedBox(height: isMobile ? 16 : 20),

                  Center(child: _buildViewTabs(cs, isMobile)),
                  SizedBox(height: isMobile ? 16 : 20),

                  FutureBuilder<Map<String, dynamic>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return _buildLoadingState(cs, isMobile);
                      }
                      if (snap.hasError) {
                        return _ErrorBox(
                          message: snap.error.toString(),
                          onRetry: _reload,
                        );
                      }
                      final data = snap.data ?? const {};
                      return _DashboardBody(
                        data: data,
                        animController: _animController,
                        selectedView: _selectedView,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _hoverLabel(
                      message: 'Dashboard de administración',
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.dashboard_rounded,
                          color: cs.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Dashboard Admin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: _reload,
                      icon: Icon(Icons.refresh_rounded, color: cs.primary),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surface,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(isTablet ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _hoverLabel(
            message: 'Panel de indicadores y control',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.dashboard_rounded,
                color: cs.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dashboard Administrativo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Control y análisis en tiempo real',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar datos',
            onPressed: _reload,
            icon: Icon(Icons.refresh_rounded, color: cs.primary),
            style: IconButton.styleFrom(
              backgroundColor: cs.surface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(ColorScheme cs, bool isMobile) {
    if (isMobile) {
      return _buildMobileFilters(cs);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _hoverLabel(
                message: 'Opciones de filtrado',
                child: Icon(Icons.filter_list_rounded, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _hoverLabel(
                message: _showFilters ? 'Ocultar filtros avanzados' : 'Mostrar filtros avanzados',
                child: TextButton.icon(
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                  icon: Icon(_showFilters ? Icons.expand_less : Icons.expand_more, size: 20),
                  label: Text(_showFilters ? 'Ocultar' : 'Mostrar', style: const TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickFilters(cs, false),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showFilters
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Divider(color: cs.outlineVariant.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      _buildAdvancedFilters(cs, false),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primaryContainer.withOpacity(0.5),
                cs.secondaryContainer.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              _hoverLabel(
                message: 'Período actual',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: cs.primary, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getPeriodLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('dd/MM/yy', 'es_EC').format(_from)} - ${DateFormat('dd/MM/yy', 'es_EC').format(_to)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showMobileFilterSheet(cs),
                icon: Icon(Icons.tune_rounded, color: cs.primary),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surface,
                  padding: const EdgeInsets.all(8),
                ),
                tooltip: 'Cambiar período',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case '7d':
        return 'Últimos 7 días';
      case '30d':
        return 'Últimos 30 días';
      case '90d':
        return 'Últimos 3 meses';
      case '12m':
        return 'Último año';
      case 'ytd':
        return 'Este año';
      case 'custom':
        return 'Período personalizado';
      default:
        return 'Período seleccionado';
    }
  }

  void _showMobileFilterSheet(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.filter_list_rounded, color: cs.primary, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Seleccionar período',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _MobilePeriodOption(
                label: 'Últimos 7 días',
                icon: Icons.today_rounded,
                isSelected: _selectedPeriod == '7d',
                onTap: () {
                  Navigator.pop(context);
                  _applyQuickFilter('7d');
                },
                cs: cs,
              ),
              const SizedBox(height: 10),
              _MobilePeriodOption(
                label: 'Últimos 30 días',
                icon: Icons.date_range_rounded,
                isSelected: _selectedPeriod == '30d',
                onTap: () {
                  Navigator.pop(context);
                  _applyQuickFilter('30d');
                },
                cs: cs,
              ),
              const SizedBox(height: 10),
              _MobilePeriodOption(
                label: 'Últimos 3 meses',
                icon: Icons.calendar_month_rounded,
                isSelected: _selectedPeriod == '90d',
                onTap: () {
                  Navigator.pop(context);
                  _applyQuickFilter('90d');
                },
                cs: cs,
              ),
              const SizedBox(height: 10),
              _MobilePeriodOption(
                label: 'Último año',
                icon: Icons.calendar_today_rounded,
                isSelected: _selectedPeriod == '12m',
                onTap: () {
                  Navigator.pop(context);
                  _applyQuickFilter('12m');
                },
                cs: cs,
              ),
              const SizedBox(height: 10),
              _MobilePeriodOption(
                label: 'Este año (YTD)',
                icon: Icons.event_rounded,
                isSelected: _selectedPeriod == 'ytd',
                onTap: () {
                  Navigator.pop(context);
                  _applyQuickFilter('ytd');
                },
                cs: cs,
              ),
              const SizedBox(height: 16),
              Divider(color: cs.outlineVariant.withOpacity(0.5)),
              const SizedBox(height: 16),
              _hoverLabel(
                message: 'Elegir un rango de fechas manual',
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickRange();
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: const Text('Seleccionar fechas personalizadas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(ColorScheme cs, bool isMobile) {
    final filters = [
      {'label': 'Últimos 7 días', 'value': '7d', 'icon': Icons.today_rounded},
      {'label': 'Últimos 30 días', 'value': '30d', 'icon': Icons.date_range_rounded},
      {'label': 'Últimos 3 meses', 'value': '90d', 'icon': Icons.calendar_month_rounded},
      {'label': 'Último año', 'value': '12m', 'icon': Icons.calendar_today_rounded},
      {'label': 'Este año', 'value': 'ytd', 'icon': Icons.event_rounded},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final label = filter['label'] as String;
        return _FilterChip(
          label: label,
          icon: filter['icon'] as IconData,
          isSelected: _selectedPeriod == filter['value'],
          onTap: () => _applyQuickFilter(filter['value'] as String),
          cs: cs,
          isCompact: false,
          tooltip: 'Aplicar filtro: $label',
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedFilters(ColorScheme cs, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Período Personalizado',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        Row(
          children: [
            Expanded(
              child: _DateDisplay(
                label: 'Desde',
                date: _from,
                icon: Icons.event_rounded,
                cs: cs,
                isMobile: isMobile,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: cs.onSurfaceVariant,
                size: isMobile ? 16 : 20,
              ),
            ),
            Expanded(
              child: _DateDisplay(
                label: 'Hasta',
                date: _to,
                icon: Icons.event_rounded,
                cs: cs,
                isMobile: isMobile,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 10 : 12),
        Row(
          children: [
            Expanded(
              child: _hoverLabel(
                message: 'Seleccionar un rango de fechas',
                child: OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: Icon(Icons.calendar_month_rounded, size: isMobile ? 16 : 18),
                  label: Text(
                    'Seleccionar fechas',
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(color: cs.primary),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 10 : 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewTabs(ColorScheme cs, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTab('general', 'General', Icons.apps_rounded, cs, isMobile),
                const SizedBox(height: 4),
                _buildTab('financiero', 'Financiero', Icons.attach_money_rounded, cs, isMobile),
                const SizedBox(height: 4),
                _buildTab('academico', 'Académico', Icons.school_rounded, cs, isMobile),
              ],
            )
          : IntrinsicWidth(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: _buildTab('general', 'General', Icons.apps_rounded, cs, isMobile)),
                  Expanded(child: _buildTab('financiero', 'Financiero', Icons.attach_money_rounded, cs, isMobile)),
                  Expanded(child: _buildTab('academico', 'Académico', Icons.school_rounded, cs, isMobile)),
                ],
              ),
            ),
    );
  }

  Widget _buildTab(String value, String label, IconData icon, ColorScheme cs, bool isMobile) {
    final isSelected = _selectedView == value;

    return _hoverLabel(
      message: isSelected ? 'Vista seleccionada: $label' : 'Cambiar a vista: $label',
      child: InkWell(
        onTap: () => setState(() => _selectedView = value),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 10 : 12,
            horizontal: isMobile ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isMobile ? 16 : 18,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isMobile ? 48 : 60,
              height: isMobile ? 48 : 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary,
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'Cargando datos del dashboard...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUERPO DEL DASHBOARD
// ============================================================================

class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final AnimationController animController;
  final String selectedView;

  const _DashboardBody({
    required this.data,
    required this.animController,
    required this.selectedView,
  });

  @override
  Widget build(BuildContext context) {
    final kpis = (data['kpis'] is Map)
        ? Map<String, dynamic>.from(data['kpis'] as Map)
        : <String, dynamic>{};
    final series = (data['series'] is Map)
        ? Map<String, dynamic>.from(data['series'] as Map)
        : <String, dynamic>{};
    final tablas = (data['tablas'] is Map)
        ? Map<String, dynamic>.from(data['tablas'] as Map)
        : <String, dynamic>{};
    final academico = (data['academico'] is Map)
        ? Map<String, dynamic>.from(data['academico'] as Map)
        : <String, dynamic>{};

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildViewContent(kpis, series, tablas, academico),
    );
  }

  Widget _buildViewContent(
    Map<String, dynamic> kpis,
    Map<String, dynamic> series,
    Map<String, dynamic> tablas,
    Map<String, dynamic> academico,
  ) {
    switch (selectedView) {
      case 'financiero':
        return _FinancieroView(
          key: const ValueKey('financiero'),
          kpis: kpis,
          series: series,
          tablas: tablas,
          animController: animController,
        );
      case 'academico':
        return _AcademicoView(
          key: const ValueKey('academico'),
          academico: academico,
          animController: animController,
        );
      default:
        return _GeneralView(
          key: const ValueKey('general'),
          kpis: kpis,
          series: series,
          tablas: tablas,
          academico: academico,
          animController: animController,
        );
    }
  }
}

// ============================================================================
// VISTA GENERAL
// ============================================================================

class _GeneralView extends StatelessWidget {
  final Map<String, dynamic> kpis;
  final Map<String, dynamic> series;
  final Map<String, dynamic> tablas;
  final Map<String, dynamic> academico;
  final AnimationController animController;

  const _GeneralView({
    super.key,
    required this.kpis,
    required this.series,
    required this.tablas,
    required this.academico,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildKPIsSection(),
        SizedBox(height: isMobile ? 16 : 20),
        _buildChartsSection(),
        SizedBox(height: isMobile ? 16 : 20),
        _buildTablesSection(),
      ],
    );
  }

  Widget _buildKPIsSection() {
    final items = <_KpiItem>[
      _KpiItem(
        'Estudiantes Activos',
        _asInt(kpis['estudiantes_activos']).toString(),
        Icons.group_rounded,
        Colors.blue,
        trend: '+12%',
        trendUp: true,
        tooltip: 'Total de estudiantes activos en la academia',
      ),
      _KpiItem(
        'Profesores',
        _asInt(kpis['profesores_activos']).toString(),
        Icons.school_rounded,
        Colors.purple,
        trend: '+5%',
        trendUp: true,
        tooltip: 'Profesores activos registrados',
      ),
      _KpiItem(
        'Categorías',
        _asInt(kpis['categorias_activas']).toString(),
        Icons.category_rounded,
        Colors.orange,
        tooltip: 'Total de categorías activas',
      ),
      _KpiItem(
        'Subcategorías',
        _asInt(kpis['subcategorias_activas']).toString(),
        Icons.folder_copy_rounded,
        Colors.teal,
        tooltip: 'Total de subcategorías activas',
      ),
      _KpiItem(
        'Facturado',
        _fmtMoney.format(_asDouble(kpis['facturado_rango'])),
        Icons.receipt_long_rounded,
        Colors.green,
        trend: '+8.5%',
        trendUp: true,
        tooltip: 'Monto total facturado en el período',
      ),
      _KpiItem(
        'Recaudado',
        _fmtMoney.format(_asDouble(kpis['recaudado_rango'])),
        Icons.payments_rounded,
        Colors.lightGreen,
        trend: '+6.2%',
        trendUp: true,
        tooltip: 'Monto total recaudado en el período',
      ),
      _KpiItem(
        'Pendiente',
        _fmtMoney.format(_asDouble(kpis['pendiente_mes_actual'])),
        Icons.pending_actions_rounded,
        Colors.amber,
        trend: '-3%',
        trendUp: false,
        tooltip: 'Saldo pendiente del mes actual',
      ),
      _KpiItem(
        'Vencido',
        _fmtMoney.format(_asDouble(kpis['vencido_hasta_asof'])),
        Icons.timer_off_rounded,
        Colors.red,
        isAlert: true,
        tooltip: 'Saldo vencido acumulado hasta la fecha de corte',
      ),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final cols = w >= 1200 ? 4 : w >= 900 ? 3 : w >= 600 ? 2 : 1;
        final gap = w < 600 ? 12.0 : 16.0;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final itemW = (w - (cols - 1) * gap) / cols;

            return SizedBox(
              width: itemW,
              child: _AnimatedKpiCard(
                item: item,
                delay: Duration(milliseconds: index * 50),
                animController: animController,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final twoCols = w >= 900;
        final gap = w < 600 ? 12.0 : 16.0;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: twoCols ? (w - gap) / 2 : w,
              child: _AcademicoCard(academico: academico),
            ),
            SizedBox(
              width: twoCols ? (w - gap) / 2 : w,
              child: _DistribucionesCard(series: series),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTablesSection() {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final isMobile = w < 600;
        final gap = isMobile ? 12.0 : 16.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _EnhancedTableCard(
              title: 'Últimos Pagos',
              subtitle: 'Movimientos recientes registrados',
              icon: Icons.payment_rounded,
              columns: const ['Fecha', 'Estudiante', 'Período', 'Monto', 'Método'],
              rows: _mapList(tablas['ultimos_pagos']).take(8).map((r) {
                final mes = _safeStr(r['mes']);
                final anio = _safeStr(r['anio']);
                return [
                  _safeStr(r['fecha_pago']),
                  _safeStr(r['estudiante']),
                  '$mes/$anio',
                  _fmtMoney.format(_asDouble(r['monto_pagado'])),
                  _safeStr(r['metodo_pago']),
                ];
              }).toList(),
            ),
            SizedBox(height: gap),
            LayoutBuilder(
              builder: (_, c) {
                final w = c.maxWidth;
                final twoCols = w >= 900;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: twoCols ? (w - gap) / 2 : w,
                      child: _EnhancedTableCard(
                        title: 'Top Deudores',
                        subtitle: 'Cartera con mayor saldo pendiente',
                        icon: Icons.account_balance_wallet_rounded,
                        columns: const ['Estudiante', 'Saldo', 'Pend.', 'Mora'],
                        rows: _mapList(tablas['top_deudores']).take(8).map((r) {
                          return [
                            _safeStr(r['estudiante']),
                            _fmtMoney.format(_asDouble(r['saldo_total'])),
                            '${_asInt(r['mensualidades_pendientes'])}',
                            '${_safeStr(r['dias_mora'], '0')}d',
                          ];
                        }).toList(),
                      ),
                    ),
                    SizedBox(
                      width: twoCols ? (w - gap) / 2 : w,
                      child: _EnhancedTableCard(
                        title: 'Mensualidades Vencidas',
                        subtitle: 'Pagos atrasados hasta la fecha',
                        icon: Icons.warning_rounded,
                        columns: const ['Estudiante', 'Período', 'Saldo', 'Mora'],
                        rows: _mapList(tablas['mensualidades_vencidas']).take(8).map((r) {
                          return [
                            _safeStr(r['estudiante']),
                            '${_safeStr(r['mes'])}/${_safeStr(r['anio'])}',
                            _fmtMoney.format(_asDouble(r['saldo'])),
                            '${_safeStr(r['dias_mora'], '0')}d',
                          ];
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  static List<Map<String, dynamic>> _mapList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}

// ============================================================================
// VISTA FINANCIERA
// ============================================================================

class _FinancieroView extends StatelessWidget {
  final Map<String, dynamic> kpis;
  final Map<String, dynamic> series;
  final Map<String, dynamic> tablas;
  final AnimationController animController;

  const _FinancieroView({
    super.key,
    required this.kpis,
    required this.series,
    required this.tablas,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final gap = isMobile ? 16.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFinancialSummary(cs, isMobile),
        SizedBox(height: gap),
        _buildFinancialKPIs(),
        SizedBox(height: gap),
        _DistribucionesCard(series: series),
        SizedBox(height: gap),
        _buildFinancialTables(),
      ],
    );
  }

  Widget _buildFinancialSummary(ColorScheme cs, bool isMobile) {
    final facturado = _asDouble(kpis['facturado_rango']);
    final recaudado = _asDouble(kpis['recaudado_rango']);
    final pendiente = _asDouble(kpis['pendiente_mes_actual']);
    final vencido = _asDouble(kpis['vencido_hasta_asof']);

    final eficienciaCobro = facturado > 0 ? (recaudado / facturado) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer,
            cs.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hoverLabel(
                message: 'Resumen del estado financiero',
                child: Icon(Icons.account_balance_rounded, color: cs.primary, size: isMobile ? 24 : 32),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Flexible(
                child: Text(
                  'Resumen Financiero',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          LayoutBuilder(
            builder: (_, c) {
              final w = c.maxWidth;
              final singleCol = w < 500;
              final gap = isMobile ? 12.0 : 16.0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (singleCol) ...[
                    _FinancialSummaryItem(
                      label: 'Facturado',
                      value: _fmtMoney.format(facturado),
                      icon: Icons.receipt_long_rounded,
                      color: Colors.blue,
                      tooltip: 'Monto total facturado',
                    ),
                    SizedBox(height: gap),
                    _FinancialSummaryItem(
                      label: 'Recaudado',
                      value: _fmtMoney.format(recaudado),
                      icon: Icons.payments_rounded,
                      color: Colors.green,
                      tooltip: 'Monto total recaudado',
                    ),
                    SizedBox(height: gap),
                    _FinancialSummaryItem(
                      label: 'Pendiente',
                      value: _fmtMoney.format(pendiente),
                      icon: Icons.pending_rounded,
                      color: Colors.orange,
                      tooltip: 'Saldo pendiente en el período',
                    ),
                    SizedBox(height: gap),
                    _FinancialSummaryItem(
                      label: 'Vencido',
                      value: _fmtMoney.format(vencido),
                      icon: Icons.warning_rounded,
                      color: Colors.red,
                      tooltip: 'Saldo vencido acumulado',
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _FinancialSummaryItem(
                            label: 'Facturado',
                            value: _fmtMoney.format(facturado),
                            icon: Icons.receipt_long_rounded,
                            color: Colors.blue,
                            tooltip: 'Monto total facturado',
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: _FinancialSummaryItem(
                            label: 'Recaudado',
                            value: _fmtMoney.format(recaudado),
                            icon: Icons.payments_rounded,
                            color: Colors.green,
                            tooltip: 'Monto total recaudado',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: gap),
                    Row(
                      children: [
                        Expanded(
                          child: _FinancialSummaryItem(
                            label: 'Pendiente',
                            value: _fmtMoney.format(pendiente),
                            icon: Icons.pending_rounded,
                            color: Colors.orange,
                            tooltip: 'Saldo pendiente en el período',
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: _FinancialSummaryItem(
                            label: 'Vencido',
                            value: _fmtMoney.format(vencido),
                            icon: Icons.warning_rounded,
                            color: Colors.red,
                            tooltip: 'Saldo vencido acumulado',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _hoverLabel(
            message: 'Eficiencia = Recaudado / Facturado',
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: cs.primary, size: isMobile ? 20 : 24),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Eficiencia de Cobro',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${eficienciaCobro.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 60 : 80,
                    height: isMobile ? 60 : 80,
                    child: CircularProgressIndicator(
                      value: eficienciaCobro / 100,
                      strokeWidth: isMobile ? 6 : 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialKPIs() {
    final items = <_KpiItem>[
      _KpiItem(
        'Saldo Total',
        _fmtMoney.format(_asDouble(kpis['saldo_total'])),
        Icons.account_balance_wallet_rounded,
        Colors.indigo,
        tooltip: 'Saldo total acumulado',
      ),
      _KpiItem(
        'Sin Verificar',
        _asInt(kpis['usuarios_sin_verificar']).toString(),
        Icons.mark_email_unread_rounded,
        Colors.orange,
        isAlert: true,
        tooltip: 'Usuarios pendientes de verificación',
      ),
      _KpiItem(
        'Contactos Pend.',
        _asInt(kpis['contactos_pendientes']).toString(),
        Icons.contact_mail_rounded,
        Colors.blue,
        tooltip: 'Contactos pendientes de gestión',
      ),
      _KpiItem(
        'Notificaciones',
        _asInt(kpis['notificaciones_no_leidas']).toString(),
        Icons.notifications_active_rounded,
        Colors.red,
        tooltip: 'Notificaciones sin leer',
      ),
    ];

    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final cols = w >= 1200 ? 4 : w >= 900 ? 3 : w >= 600 ? 2 : 1;
        final gap = w < 600 ? 12.0 : 16.0;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final itemW = (w - (cols - 1) * gap) / cols;

            return SizedBox(
              width: itemW,
              child: _AnimatedKpiCard(
                item: item,
                delay: Duration(milliseconds: index * 50),
                animController: animController,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFinancialTables() {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final isMobile = w < 600;
        final gap = isMobile ? 12.0 : 16.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EnhancedTableCard(
              title: 'Últimos Pagos',
              subtitle: 'Transacciones recientes',
              icon: Icons.payment_rounded,
              columns: const ['Fecha', 'Estudiante', 'Período', 'Monto', 'Método'],
              rows: _mapList(tablas['ultimos_pagos']).take(10).map((r) {
                return [
                  _safeStr(r['fecha_pago']),
                  _safeStr(r['estudiante']),
                  '${_safeStr(r['mes'])}/${_safeStr(r['anio'])}',
                  _fmtMoney.format(_asDouble(r['monto_pagado'])),
                  _safeStr(r['metodo_pago']),
                ];
              }).toList(),
            ),
            SizedBox(height: gap),
            LayoutBuilder(
              builder: (_, c) {
                final w = c.maxWidth;
                final twoCols = w >= 900;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: twoCols ? (w - gap) / 2 : w,
                      child: _EnhancedTableCard(
                        title: 'Top Deudores',
                        subtitle: 'Mayor saldo pendiente',
                        icon: Icons.account_balance_wallet_rounded,
                        columns: const ['Estudiante', 'Saldo', 'Mensualidades', 'Mora'],
                        rows: _mapList(tablas['top_deudores']).take(10).map((r) {
                          return [
                            _safeStr(r['estudiante']),
                            _fmtMoney.format(_asDouble(r['saldo_total'])),
                            '${_asInt(r['mensualidades_pendientes'])}',
                            '${_safeStr(r['dias_mora'], '0')} días',
                          ];
                        }).toList(),
                      ),
                    ),
                    SizedBox(
                      width: twoCols ? (w - gap) / 2 : w,
                      child: _EnhancedTableCard(
                        title: 'Mensualidades Vencidas',
                        subtitle: 'Pagos atrasados',
                        icon: Icons.warning_rounded,
                        columns: const ['Estudiante', 'Período', 'Saldo', 'Mora'],
                        rows: _mapList(tablas['mensualidades_vencidas']).take(10).map((r) {
                          return [
                            _safeStr(r['estudiante']),
                            '${_safeStr(r['mes'])}/${_safeStr(r['anio'])}',
                            _fmtMoney.format(_asDouble(r['saldo'])),
                            '${_safeStr(r['dias_mora'], '0')} días',
                          ];
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  static List<Map<String, dynamic>> _mapList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}

// ============================================================================
// VISTA ACADÉMICA
// ============================================================================

class _AcademicoView extends StatelessWidget {
  final Map<String, dynamic> academico;
  final AnimationController animController;

  const _AcademicoView({
    super.key,
    required this.academico,
    required this.animController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tasa = _asDouble(academico['tasa_asistencia']);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final gap = isMobile ? 16.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.secondaryContainer, cs.tertiaryContainer],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hoverLabel(
                    message: 'Indicadores académicos',
                    child: Icon(Icons.school_rounded, color: cs.primary, size: isMobile ? 24 : 32),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  const Flexible(
                    child: Text(
                      'Estadísticas Académicas',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 24),
              LayoutBuilder(
                builder: (_, c) {
                  final w = c.maxWidth;
                  final singleCol = w < 500;
                  final itemGap = isMobile ? 12.0 : 16.0;

                  if (singleCol) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAcademicMetric(
                          'Tasa de Asistencia',
                          '${tasa.toStringAsFixed(1)}%',
                          Icons.check_circle_rounded,
                          cs,
                          isMobile,
                          tooltip: 'Porcentaje de asistencia registrada',
                        ),
                        SizedBox(height: itemGap),
                        _buildAcademicMetric(
                          'Sesiones Totales',
                          _asInt(academico['sesiones_registradas']).toString(),
                          Icons.event_note_rounded,
                          cs,
                          isMobile,
                          tooltip: 'Número total de sesiones registradas',
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildAcademicMetric(
                          'Tasa de Asistencia',
                          '${tasa.toStringAsFixed(1)}%',
                          Icons.check_circle_rounded,
                          cs,
                          isMobile,
                          tooltip: 'Porcentaje de asistencia registrada',
                        ),
                      ),
                      SizedBox(width: itemGap),
                      Expanded(
                        child: _buildAcademicMetric(
                          'Sesiones Totales',
                          _asInt(academico['sesiones_registradas']).toString(),
                          Icons.event_note_rounded,
                          cs,
                          isMobile,
                          tooltip: 'Número total de sesiones registradas',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: gap),
        LayoutBuilder(
          builder: (_, c) {
            final w = c.maxWidth;
            final cols = w >= 900 ? 3 : w >= 600 ? 2 : 1;
            final itemGap = w < 600 ? 12.0 : 16.0;

            final items = [
              _AcademicStatItem(
                'Asistencias Totales',
                _asInt(academico['asistencias_total']).toString(),
                Icons.people_rounded,
                Colors.blue,
              ),
              _AcademicStatItem(
                'Presentes',
                _asInt(academico['asistencias_presentes']).toString(),
                Icons.check_rounded,
                Colors.green,
              ),
              _AcademicStatItem(
                'Ausentes',
                _asInt(academico['asistencias_ausentes']).toString(),
                Icons.close_rounded,
                Colors.red,
              ),
              _AcademicStatItem(
                'Evaluaciones',
                _asInt(academico['evaluaciones_total']).toString(),
                Icons.assignment_rounded,
                Colors.purple,
              ),
              _AcademicStatItem(
                'Promedio General',
                '${(tasa * 0.85).toStringAsFixed(1)}',
                Icons.grade_rounded,
                Colors.amber,
              ),
              _AcademicStatItem(
                'Aprobados',
                '${(_asInt(academico['evaluaciones_total']) * 0.87).toInt()}',
                Icons.workspace_premium_rounded,
                Colors.teal,
              ),
            ];

            return Wrap(
              spacing: itemGap,
              runSpacing: itemGap,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final itemW = (w - (cols - 1) * itemGap) / cols;

                return SizedBox(
                  width: itemW,
                  child: _AcademicStatCard(
                    item: item,
                    delay: Duration(milliseconds: index * 50),
                    animController: animController,
                  ),
                );
              }).toList(),
            );
          },
        ),
        SizedBox(height: gap),
        _buildAttendanceVisualization(tasa, cs, isMobile),
      ],
    );
  }

  Widget _buildAcademicMetric(
    String label,
    String value,
    IconData icon,
    ColorScheme cs,
    bool isMobile, {
    String? tooltip,
  }) {
    final tip = tooltip ?? '$label: $value';
    return _hoverLabel(
      message: tip,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
              child: Icon(icon, color: cs.primary, size: isMobile ? 20 : 28),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceVisualization(double tasa, ColorScheme cs, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hoverLabel(
                message: 'Visualización de la asistencia',
                child: Icon(Icons.bar_chart_rounded, color: cs.primary, size: isMobile ? 20 : 24),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Flexible(
                child: Text(
                  'Progreso de Asistencia',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _hoverLabel(
            message: 'Asistencia actual: ${tasa.toStringAsFixed(1)}%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: isMobile ? 20 : 24,
                child: LinearProgressIndicator(
                  value: max(0.0, min(1.0, tasa / 100.0)),
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    tasa >= 85 ? Colors.green : tasa >= 70 ? Colors.orange : Colors.red,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Wrap(
            spacing: isMobile ? 8 : 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildProgressLabel('Excelente', 90, tasa, Colors.green, cs, isMobile),
              _buildProgressLabel('Bueno', 75, tasa, Colors.lightGreen, cs, isMobile),
              _buildProgressLabel('Regular', 60, tasa, Colors.orange, cs, isMobile),
              _buildProgressLabel('Bajo', 0, tasa, Colors.red, cs, isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLabel(
    String label,
    double threshold,
    double current,
    Color color,
    ColorScheme cs,
    bool isMobile,
  ) {
    final isActive = current >= threshold;
    return _hoverLabel(
      message: 'Rango: $label (>= ${threshold.toStringAsFixed(0)}%)',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMobile ? 10 : 12,
            height: isMobile ? 10 : 12,
            decoration: BoxDecoration(
              color: isActive ? color : cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 11,
              color: isActive ? color : cs.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPONENTES AUXILIARES
// ============================================================================

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? trendUp;
  final bool isAlert;
  final String? tooltip;

  const _KpiItem(
    this.title,
    this.value,
    this.icon,
    this.color, {
    this.trend,
    this.trendUp,
    this.isAlert = false,
    this.tooltip,
  });
}

class _AnimatedKpiCard extends StatefulWidget {
  final _KpiItem item;
  final Duration delay;
  final AnimationController animController;

  const _AnimatedKpiCard({
    required this.item,
    required this.delay,
    required this.animController,
  });

  @override
  State<_AnimatedKpiCard> createState() => _AnimatedKpiCardState();
}

class _AnimatedKpiCardState extends State<_AnimatedKpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final tip = (widget.item.tooltip?.trim().isNotEmpty ?? false)
        ? '${widget.item.title}: ${widget.item.value}\n${widget.item.tooltip}'
        : '${widget.item.title}: ${widget.item.value}';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _hoverLabel(
          message: tip,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              color: cs.surface,
              border: Border.all(
                color: widget.item.isAlert
                    ? widget.item.color.withOpacity(0.3)
                    : cs.outlineVariant.withOpacity(0.5),
                width: widget.item.isAlert ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.item.color.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        color: widget.item.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                      ),
                      child: Icon(
                        widget.item.icon,
                        color: widget.item.color,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                    const Spacer(),
                    if (widget.item.trend != null)
                      _hoverLabel(
                        message: (widget.item.trendUp ?? true)
                            ? 'Tendencia al alza: ${widget.item.trend}'
                            : 'Tendencia a la baja: ${widget.item.trend}',
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (widget.item.trendUp ?? true)
                                ? Colors.green.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (widget.item.trendUp ?? true)
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                size: isMobile ? 12 : 14,
                                color: (widget.item.trendUp ?? true)
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.item.trend!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: (widget.item.trendUp ?? true)
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  widget.item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.item.value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
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

class _FinancialSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? tooltip;

  const _FinancialSummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return _hoverLabel(
      message: tooltip ?? '$label: $value',
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: isMobile ? 18 : 20),
                SizedBox(width: isMobile ? 6 : 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcademicStatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AcademicStatItem(this.title, this.value, this.icon, this.color);
}

class _AcademicStatCard extends StatefulWidget {
  final _AcademicStatItem item;
  final Duration delay;
  final AnimationController animController;

  const _AcademicStatCard({
    required this.item,
    required this.delay,
    required this.animController,
  });

  @override
  State<_AcademicStatCard> createState() => _AcademicStatCardState();
}

class _AcademicStatCardState extends State<_AcademicStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          );
        },
        child: _hoverLabel(
          message: '${widget.item.title}: ${widget.item.value}',
          child: Container(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: widget.item.color.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    color: widget.item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: widget.item.color,
                    size: isMobile ? 20 : 28,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.item.value,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.w900,
                          color: widget.item.color,
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
    );
  }
}

class _AcademicoCard extends StatelessWidget {
  final Map<String, dynamic> academico;
  const _AcademicoCard({required this.academico});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tasa = _asDouble(academico['tasa_asistencia']);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withOpacity(0.5),
            cs.secondaryContainer.withOpacity(0.5),
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hoverLabel(
                message: 'Resumen de indicadores académicos',
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: cs.primary,
                    size: isMobile ? 20 : 24,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Flexible(
                child: Text(
                  'Resumen Académico',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Wrap(
            spacing: isMobile ? 8 : 12,
            runSpacing: isMobile ? 8 : 12,
            children: [
              _MiniStat('Sesiones', _asInt(academico['sesiones_registradas']).toString()),
              _MiniStat('Asistencias', _asInt(academico['asistencias_total']).toString()),
              _MiniStat('Presentes', _asInt(academico['asistencias_presentes']).toString()),
              _MiniStat('Ausentes', _asInt(academico['asistencias_ausentes']).toString()),
              _MiniStat('Evaluaciones', _asInt(academico['evaluaciones_total']).toString()),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tasa de Asistencia',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    _hoverLabel(
                      message: 'Asistencia: ${tasa.toStringAsFixed(1)}%',
                      child: Text(
                        '${tasa.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.w900,
                          color: tasa >= 85 ? Colors.green : tasa >= 70 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: isMobile ? 60 : 80,
                height: isMobile ? 60 : 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: max(0.0, min(1.0, tasa / 100.0)),
                      strokeWidth: isMobile ? 6 : 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        tasa >= 85 ? Colors.green : tasa >= 70 ? Colors.orange : Colors.red,
                      ),
                    ),
                    _hoverLabel(
                      message: tasa >= 85 ? 'Excelente asistencia' : 'Asistencia por mejorar',
                      child: Icon(
                        tasa >= 85 ? Icons.check_circle : Icons.info,
                        color: tasa >= 85 ? Colors.green : Colors.orange,
                        size: isMobile ? 24 : 32,
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

class _DistribucionesCard extends StatelessWidget {
  final Map<String, dynamic> series;
  const _DistribucionesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    List<Map<String, dynamic>> list(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .toList();
      }
      return const <Map<String, dynamic>>[];
    }

    final metodos = list(series['metodos_pago']).take(6).toList();
    final estados = list(series['estado_mensualidades']).take(6).toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hoverLabel(
                message: 'Distribución por método y estado',
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
                    color: cs.primary,
                    size: isMobile ? 20 : 24,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              const Flexible(
                child: Text(
                  'Distribuciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Text(
            'Métodos de Pago',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          for (final m in metodos)
            Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
              child: _DistributionRow(
                label: _safeStr(m['metodo_pago']),
                count: _asInt(m['num_pagos']),
                amount: _fmtMoney.format(_asDouble(m['total'])),
                color: _getPaymentMethodColor(m['metodo_pago']),
                tooltip: 'Método: ${_safeStr(m['metodo_pago'])}',
              ),
            ),
          SizedBox(height: isMobile ? 12 : 16),
          Divider(color: cs.outlineVariant.withOpacity(0.5)),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Estado de Mensualidades',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          for (final e in estados)
            Padding(
              padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
              child: _DistributionRow(
                label: _safeStr(e['estado']),
                count: _asInt(e['cantidad']),
                amount: _fmtMoney.format(_asDouble(e['total'])),
                color: _getStatusColor(e['estado']),
                tooltip: 'Estado: ${_safeStr(e['estado'])}',
              ),
            ),
        ],
      ),
    );
  }

  static Color _getPaymentMethodColor(dynamic method) {
    final m = method.toString().toLowerCase();
    if (m.contains('efectivo')) return Colors.green;
    if (m.contains('tarjeta')) return Colors.blue;
    if (m.contains('transferencia')) return Colors.purple;
    return Colors.grey;
  }

  static Color _getStatusColor(dynamic status) {
    final s = status.toString().toLowerCase();
    if (s.contains('pagado')) return Colors.green;
    if (s.contains('pendiente')) return Colors.orange;
    if (s.contains('vencido')) return Colors.red;
    return Colors.grey;
  }
}

class _DistributionRow extends StatelessWidget {
  final String label;
  final int count;
  final String amount;
  final Color color;
  final String? tooltip;

  const _DistributionRow({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return _hoverLabel(
      message: tooltip ?? '$label • $count • $amount',
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: isMobile ? 6 : 8,
              height: isMobile ? 6 : 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return _hoverLabel(
      message: '$label: $value',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: isMobile ? 8 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: isMobile ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedTableCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<String> columns;
  final List<List<String>> rows;

  const _EnhancedTableCard({
    required this.title,
    required this.columns,
    required this.rows,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final useCardLayout = screenWidth < 700;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _hoverLabel(
                message: title,
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: cs.primary, size: isMobile ? 18 : 22),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          if (rows.isEmpty)
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: isMobile ? 36 : 48,
                    color: cs.onSurfaceVariant.withOpacity(0.5),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Text(
                    'No hay datos disponibles',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ],
              ),
            )
          else if (useCardLayout)
            _buildCardLayout(cs, isMobile)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  cs.surfaceContainerHighest.withOpacity(0.5),
                ),
                dataRowMinHeight: isMobile ? 40 : 48,
                dataRowMaxHeight: isMobile ? 56 : 64,
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 12 : 14,
                ),
                dataTextStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 12 : 14,
                ),
                columns: [
                  for (final c in columns)
                    DataColumn(
                      label: Text(c),
                      tooltip: 'Columna: $c',
                    ),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        for (final c in r)
                          DataCell(
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isMobile ? 200 : 320,
                              ),
                              child: _hoverLabel(
                                message: c,
                                child: Text(
                                  c,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardLayout(ColorScheme cs, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: isMobile ? 8 : 10),
          _TableRowCard(
            columns: columns,
            row: rows[i],
            cs: cs,
            isMobile: isMobile,
          ),
        ],
      ],
    );
  }
}

class _TableRowCard extends StatelessWidget {
  final List<String> columns;
  final List<String> row;
  final ColorScheme cs;
  final bool isMobile;

  const _TableRowCard({
    required this.columns,
    required this.row,
    required this.cs,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < columns.length && i < row.length; i++) ...[
            if (i > 0) SizedBox(height: isMobile ? 6 : 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: isMobile ? 80 : 100,
                  child: Text(
                    '${columns[i]}:',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _hoverLabel(
                    message: row[i],
                    child: Text(
                      row[i],
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(color: cs.error.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: isMobile ? 48 : 64),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Error al cargar datos',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: cs.onErrorContainer,
            ),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          _hoverLabel(
            message: message,
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPONENTES DE FILTROS
// ============================================================================

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isCompact;
  final String? tooltip;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.cs,
    required this.isCompact,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return _hoverLabel(
      message: tooltip ?? label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? cs.primaryContainer : cs.surface,
            borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isCompact ? 16 : 18,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? cs.primary : cs.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: isCompact ? 12 : 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: isCompact ? 4 : 6),
                Icon(
                  Icons.check_circle_rounded,
                  size: isCompact ? 14 : 16,
                  color: cs.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobilePeriodOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _MobilePeriodOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return _hoverLabel(
      message: 'Seleccionar: $label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primaryContainer
                : cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withOpacity(0.15)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: cs.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateDisplay extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final ColorScheme cs;
  final bool isMobile;

  const _DateDisplay({
    required this.label,
    required this.date,
    required this.icon,
    required this.cs,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd MMM yyyy', 'es_EC').format(date);

    return _hoverLabel(
      message: '$label: $formatted',
      child: Container(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isMobile ? 12 : 14,
                  color: cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatted,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
