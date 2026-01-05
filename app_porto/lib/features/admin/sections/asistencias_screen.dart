import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:table_calendar/table_calendar.dart';

import '../../../app/app_scope.dart';
import '../../../core/constants/endpoints.dart';

String _todayISO() => DateFormat('yyyy-MM-dd').format(DateTime.now());

// ===== Enum de Estatus de Asistencia =====
enum EstatusAsistencia {
  presente,
  tarde,
  ausente,
  justificado,
}

/// Helper para convertir el enum a un string para la BD
String estatusAsistenciaToString(EstatusAsistencia estatus) {
  switch (estatus) {
    case EstatusAsistencia.presente:
      return 'presente';
    case EstatusAsistencia.tarde:
      return 'tarde';
    case EstatusAsistencia.ausente:
      return 'ausente';
    case EstatusAsistencia.justificado:
      return 'justificado';
  }
}

/// Helper para leer el string desde la BD
EstatusAsistencia estatusAsistenciaFromString(String? s) {
  switch (s?.toLowerCase()) {
    case 'presente':
      return EstatusAsistencia.presente;
    case 'tarde':
      return EstatusAsistencia.tarde;
    case 'justificado':
      return EstatusAsistencia.justificado;
    case 'ausente':
      return EstatusAsistencia.ausente;
    default:
      // Por defecto (incluyendo null o 'falta'), es ausente
      return EstatusAsistencia.ausente;
  }
}

// ===== Helpers robustos (Top-level) =====
int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

int _toIntOrZero(dynamic v) => _toIntOrNull(v) ?? 0;

int? _readIdSesion(Map<String, dynamic>? sesion) {
  final raw = sesion?['id_sesion'] ?? sesion?['idSesion'] ?? sesion?['id'];
  return _toIntOrNull(raw);
}

String _mesNombre(int? m) {
  const meses = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];
  if (m == null || m < 1 || m > 12) return '-';
  return meses[m];
}
// =========================================

class AdminAsistenciasScreen extends StatefulWidget {
  const AdminAsistenciasScreen({super.key});
  @override
  State<AdminAsistenciasScreen> createState() => _AdminAsistenciasScreenState();
}

class _AdminAsistenciasScreenState extends State<AdminAsistenciasScreen> {
  // Repos
  get _subcatsRepo => AppScope.of(context).subcategorias;
  get _asistRepo => AppScope.of(context).asistencias;
  get _http => AppScope.of(context).http;

  // Estado UI
  int _step = 0; // 0: elegir subcategoría, 1: asistencia (tabs)

  // Subcategorías
  List<Map<String, dynamic>> _subcats = [];
  List<Map<String, dynamic>> _filteredSubcats = [];
  final _subcatSearchCtrl = TextEditingController();

  // Selección
  int? _selSubcatId;
  String? _selSubcatNombre;

  // Sesión actual
  String _fecha = _todayISO();
  final _iniCtrl = TextEditingController(text: '16:00');
  final _finCtrl = TextEditingController(text: '18:00');
  int? _idSesion;

  // Estudiantes sesión actual
  bool _loading = false;
  List<_RowAlumno> _rows = []; // Roster completo de la subcategoría
  final _alumnoSearchCtrl = TextEditingController();

  // Historial (Lista y Calendario)
  String _histDesde = _isoNDiasAtras(30);
  String _histHasta = _todayISO();
  bool _loadingHist = false;
  List<Map<String, dynamic>> _sesionesHistorial = [];
  Map<DateTime, String> _sesionResumenes = {}; // Para el calendario
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Reporte por Alumno
  int? _selAlumnoReporteId; // ID del alumno seleccionado para el reporte
  bool _loadingReporteAlumno = false;
  List<Map<String, dynamic>> _historialAlumno = []; // Asistencias del alumno

  // Lista para las sesiones del día seleccionado (Calendario)
  List<Map<String, dynamic>> _sesionesDelDiaSeleccionado = [];

  static String _isoNDiasAtras(int n) =>
      DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: n)));

  @override
  void initState() {
    super.initState();
    _subcatSearchCtrl.addListener(_applySubcatFilter);
    _alumnoSearchCtrl.addListener(_applyAlumnoFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSubcats();
    });
  }

  @override
  void dispose() {
    _subcatSearchCtrl.dispose();
    _alumnoSearchCtrl.dispose();
    _iniCtrl.dispose();
    _finCtrl.dispose();
    super.dispose();
  }

  // ====== SUBCATEGORÍAS ======
  Future<void> _loadSubcats() async {
    setState(() => _loading = true);
    try {
      final list = await _fetchSubcatsRobusto();
      final parsed = list
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _subcats = parsed;
        _filteredSubcats = parsed;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude cargar subcategorías: $e')),
      );
    }
  }

  Future<List> _fetchSubcatsRobusto() async {
    try {
      final dyn = _subcatsRepo as dynamic;
      final r = await dyn.todas();
      if (r is List && r.isNotEmpty) return r;
    } catch (_) {}
    try {
      final dyn = _subcatsRepo as dynamic;
      final r = await dyn.activas();
      if (r is List && r.isNotEmpty) return r;
    } catch (_) {}
    try {
      final dyn = _subcatsRepo as dynamic;
      final r = await dyn.listar();
      if (r is List && r.isNotEmpty) return r;
    } catch (_) {}
    final res = await _http.get(Endpoints.subcategorias,
        headers: const {'Accept': 'application/json'});
    return (res as List);
  }

  void _applySubcatFilter() {
    final q = _subcatSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredSubcats = _subcats);
      return;
    }
    setState(() {
      _filteredSubcats = _subcats.where((m) {
        final nombre = (m['nombre'] ?? m['nombre_subcategoria'] ?? '')
            .toString()
            .toLowerCase();
        return nombre.contains(q);
      }).toList();
    });
  }

  // ====== SESIÓN & ALUMNOS ======
  Future<void> _crearOAbrirSesionYListar() async {
    final id = _selSubcatId;
    if (id == null) return;

    setState(() {
      _loading = true;
      _rows = [];
      _idSesion = null;
    });

    try {
      // Buscar sesión existente para esta fecha
      final sesiones =
          await _asistRepo.listarSesiones(idSubcategoria: id, fechaISO: _fecha);
      Map<String, dynamic>? sesion = sesiones.isNotEmpty
          ? Map<String, dynamic>.from(sesiones.first as Map)
          : null;

      // Crear si no existe
      sesion ??= Map<String, dynamic>.from(
        await _asistRepo.crearSesion(
              idSubcategoria: id,
              fechaISO: _fecha,
              horaInicio: _iniCtrl.text,
              horaFin: _finCtrl.text,
            ) as Map,
      );

      _idSesion = _readIdSesion(sesion);

      // Roster base
      final roster = await _asistRepo.estudiantesPorSubcategoria(id);
      final map = <int, _RowAlumno>{};
      for (final e in roster) {
        final me = Map<String, dynamic>.from(e as Map);
        final idEst =
            _toIntOrZero(me['id_estudiante'] ?? me['idEstudiante']);
        if (idEst == 0) continue;
        final nombre = [
          (me['apellidos'] ?? me['apellido'] ?? '').toString(),
          (me['nombres'] ?? me['nombre'] ?? '').toString(),
        ].where((s) => s.isNotEmpty).join(' ');
        map[idEst] = _RowAlumno(idEstudiante: idEst, nombre: nombre);
      }

      // Marcas ya registradas
      if (_idSesion != null) {
        final marcas = await _asistRepo.detalleSesion(_idSesion!);
        for (final m in marcas) {
          final mm = Map<String, dynamic>.from(m as Map);
          final idEst =
              _toIntOrNull(mm['id_estudiante'] ?? mm['idEstudiante']);
          if (idEst == null) continue;

          final estatusStr = (mm['estatus'] ?? mm['status'])?.toString();
          final estatus = estatusAsistenciaFromString(estatusStr);

          final obs = (mm['observaciones'] ?? '').toString();
          map[idEst] = (map[idEst] ?? _RowAlumno(idEstudiante: idEst, nombre: ''))
            ..estatus = estatus
            ..observaciones = obs;
        }
      }

      setState(() {
        _rows = map.values.toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando/abriendo sesión: $e')),
      );
    }
  }

  // Abre una sesión pasada (desde Historial)
  Future<void> _abrirSesionExistente(
      Map<String, dynamic> sesion, TabController tabController) async {
    final id = _selSubcatId;
    if (id == null) return;

    final fechaRaw = (sesion['fecha'] ?? sesion['fechaISO'] ?? sesion['dia'])
        ?.toString();
    if (fechaRaw != null && fechaRaw.isNotEmpty) {
      final iso = fechaRaw.length >= 10 ? fechaRaw.substring(0, 10) : fechaRaw;
      setState(() => _fecha = iso);
    }
    final hi = (sesion['hora_inicio'] ?? sesion['horaInicio'])?.toString();
    final hf = (sesion['hora_fin'] ?? sesion['horaFin'])?.toString();
    if (hi != null && hi.isNotEmpty) _iniCtrl.text = hi;
    if (hf != null && hf.isNotEmpty) _finCtrl.text = hf;

    // Cambia al tab de "Tomar Asistencia"
    tabController.animateTo(0);
    // Carga los datos de esa sesión
    await _crearOAbrirSesionYListar();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1, 1, 1);
    final last = DateTime(now.year + 1, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_fecha) ?? now,
      firstDate: first,
      lastDate: last,
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() => _fecha = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: (parts.isNotEmpty ? int.tryParse(parts[0]) : null) ?? 8,
      minute: (parts.length > 1 ? int.tryParse(parts[1]) : null) ?? 0,
    );
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Selecciona hora',
    );
    if (t != null) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      setState(() => ctrl.text = '$h:$m');
    }
  }

  void _setAllStatus(EstatusAsistencia estatus) => setState(() {
        for (final r in _rows) r.estatus = estatus;
      });

  Future<void> _guardar() async {
    if (_idSesion == null) return;
    try {
      final marcas = _rows
          .map((r) => {
                'id_estudiante': r.idEstudiante,
                'estatus': estatusAsistenciaToString(r.estatus),
                if (r.observaciones.trim().isNotEmpty)
                  'observaciones': r.observaciones.trim(),
              })
          .toList();

      await _asistRepo.marcarBulk(_idSesion!, marcas);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asistencia guardada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando: $e')),
      );
    }
  }

  // ====== HISTORIAL (Y CALENDARIO) ======
  Future<void> _pickRange() async {
    final initialStart = DateTime.tryParse(_histDesde) ??
        DateTime.now().subtract(const Duration(days: 30));
    final initialEnd = DateTime.tryParse(_histHasta) ?? DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(initialStart.year - 1),
      lastDate: DateTime(initialEnd.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Selecciona rango',
      locale: const Locale('es'),
    );
    if (range != null) {
      setState(() {
        _histDesde = DateFormat('yyyy-MM-dd').format(range.start);
        _histHasta = DateFormat('yyyy-MM-dd').format(range.end);
      });
      await _loadHistorial();
    }
  }

  Future<List> _fetchSesionesHistorial({
    required int subcatId,
    required String desde,
    required String hasta,
  }) async {
    try {
      final dyn = _asistRepo as dynamic;
      final r =
          await dyn.listarSesiones(idSubcategoria: subcatId, desde: desde, hasta: hasta);
      if (r is List) return r;
    } catch (_) {}
    try {
      final dyn = _asistRepo as dynamic;
      final r = await dyn.historialSesiones(
          subcategoriaId: subcatId, desde: desde, hasta: hasta);
      if (r is List) return r;
    } catch (_) {}

    final path =
        '/asistencias/sesiones?subcategoria=$subcatId&desde=$desde&hasta=$hasta';
    final res =
        await _http.get(path, headers: const {'Accept': 'application/json'});
    return (res as List);
  }

  Future<void> _loadHistorial() async {
    final id = _selSubcatId;
    if (id == null) return;
    setState(() => _loadingHist = true);
    try {
      final list = await _fetchSesionesHistorial(
          subcatId: id, desde: _histDesde, hasta: _histHasta);
      final parsed = list
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final newResumenes = <DateTime, String>{};
      for (final s in parsed) {
        final fechaStr = _pickStr(s, ['fecha', 'fechaISO', 'dia']);
        if (fechaStr.length < 10) continue;
        final fechaDt = DateTime.tryParse(fechaStr.substring(0, 10));
        if (fechaDt != null) {
          final p = s['presentes'] ?? s['presentes_count'] ?? s['asistentes'];
          final t =
              s['total'] ?? s['total_estudiantes'] ?? s['inscritos'];
          if (p != null && t != null) {
            newResumenes[DateTime.utc(fechaDt.year, fechaDt.month, fechaDt.day)] =
                '$p/$t';
          }
        }
      }

      setState(() {
        _sesionesHistorial = parsed;
        _sesionResumenes = newResumenes;
        _loadingHist = false;

        if (_selectedDay != null) {
          _filtrarSesionesDelDia(_selectedDay!);
        }
      });
    } catch (e) {
      setState(() {
        _sesionesHistorial = [];
        _sesionResumenes = {};
        _sesionesDelDiaSeleccionado = [];
        _loadingHist = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude cargar el historial: $e')),
      );
    }
  }

  // ====== REPORTE POR ALUMNO ======
  Future<List> _fetchAsistenciasPorEstudiante({
    required int subcatId,
    required int estudianteId,
    required String desde,
    required String hasta,
  }) async {
    try {
      final dyn = _asistRepo as dynamic;
      final r = await dyn.asistenciaPorEstudiante(
        idSubcategoria: subcatId,
        idEstudiante: estudianteId,
        desde: desde,
        hasta: hasta,
      );
      if (r is List) return r;
    } catch (_) {}

    final path =
        '/asistencias/historial-estudiante?subcategoria=$subcatId&estudiante=$estudianteId&desde=$desde&hasta=$hasta';
    final res =
        await _http.get(path, headers: const {'Accept': 'application/json'});
    return (res as List);
  }

  Future<void> _loadHistorialPorEstudiante(int estudianteId) async {
    final idSubcat = _selSubcatId;
    if (idSubcat == null) return;

    setState(() {
      _loadingReporteAlumno = true;
      _selAlumnoReporteId = estudianteId;
      _historialAlumno = [];
    });

    try {
      final list = await _fetchAsistenciasPorEstudiante(
        subcatId: idSubcat,
        estudianteId: estudianteId,
        desde: _histDesde,
        hasta: _histHasta,
      );
      final parsed = list
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _historialAlumno = parsed;
        _loadingReporteAlumno = false;
      });
    } catch (e) {
      setState(() {
        _historialAlumno = [];
        _loadingReporteAlumno = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude cargar el historial del alumno: $e')),
      );
    }
  }

  // Filtra la lista de historial para el día seleccionado
  void _filtrarSesionesDelDia(DateTime diaSeleccionado) {
    final diaUtc =
        DateTime.utc(diaSeleccionado.year, diaSeleccionado.month, diaSeleccionado.day);

    final sesionesFiltradas = _sesionesHistorial.where((sesion) {
      final fechaStr = _pickStr(sesion, ['fecha', 'fechaISO', 'dia']);
      if (fechaStr.length < 10) return false;

      final fechaDt = DateTime.tryParse(fechaStr.substring(0, 10));
      if (fechaDt == null) return false;

      final fechaUtc = DateTime.utc(fechaDt.year, fechaDt.month, fechaDt.day);
      return isSameDay(fechaUtc, diaUtc);
    }).toList();

    setState(() {
      _sesionesDelDiaSeleccionado = sesionesFiltradas;
    });
  }

  // ====== FILTRO DE ALUMNOS EN MEMORIA ======
  List<_RowAlumno> get _rowsFiltered {
    final q = _alumnoSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) => r.nombre.toLowerCase().contains(q)).toList();
  }

  void _applyAlumnoFilter() => setState(() {/*rebuild*/});

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final isStepElegir = _step == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStepElegir
            ? 'Asistencias · Subcategorías'
            : 'Asistencias · ${_selSubcatNombre ?? ''}'),
        leading: isStepElegir
            ? null
            : BackButton(onPressed: () {
                setState(() {
                  _step = 0;
                  _rows.clear();
                  _idSesion = null;
                  _sesionesHistorial = [];
                  _sesionResumenes = {};
                  _historialAlumno = [];
                  _selAlumnoReporteId = null;
                  _sesionesDelDiaSeleccionado = [];
                });
              }),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: isStepElegir ? _buildStepSelectSubcat() : _buildStepAttendanceTabs(),
        ),
      ),
    );
  }

  Widget _buildStepSelectSubcat() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _subcatSearchCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar subcategoría...',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_filteredSubcats.isEmpty
                  ? _EmptySubcats(onReload: _loadSubcats)
                  : LayoutBuilder(
                      builder: (ctx, c) {
                        final w = c.maxWidth;
                        final cross =
                            w >= 1200 ? 4 : w >= 900 ? 3 : w >= 600 ? 2 : 1;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cross,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 3.5,
                          ),
                          itemCount: _filteredSubcats.length,
                          itemBuilder: (_, i) {
                            final it = _filteredSubcats[i];
                            final id =
                                _toIntOrZero(it['id'] ?? it['id_subcategoria']);
                            final nombre = (it['nombre'] ??
                                    it['nombre_subcategoria'] ??
                                    'Sin nombre')
                                .toString();

                            return InkWell(
                              onTap: () async {
                                setState(() {
                                  _selSubcatId = id;
                                  _selSubcatNombre = nombre;
                                  _step = 1;
                                  _histDesde = _isoNDiasAtras(30);
                                  _histHasta = _todayISO();
                                  _focusedDay = DateTime.now();
                                  _selectedDay = null;
                                  _sesionesDelDiaSeleccionado = [];
                                });
                                await _crearOAbrirSesionYListar();
                                await _loadHistorial();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.group, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          nombre,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )),
        ),
      ],
    );
  }

  // Tabs: 4 pestañas
  Widget _buildStepAttendanceTabs() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tomar asistencia', icon: Icon(Icons.fact_check_outlined)),
              Tab(text: 'Historial (Lista)', icon: Icon(Icons.history)),
              Tab(text: 'Calendario', icon: Icon(Icons.calendar_month)),
              Tab(text: 'Por Alumno', icon: Icon(Icons.person_search)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTakeAttendanceTab(),
                Builder(
                  builder: (context) => _buildHistoryTab(
                    DefaultTabController.of(context),
                  ),
                ),
                _buildCalendarTab(),
                _buildStudentReportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== PESTAÑA 1: TOMAR ASISTENCIA =====
  Widget _buildTakeAttendanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Fecha: $_fecha',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Cambiar'),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                  _TimeField(
                      controller: _iniCtrl,
                      label: 'Inicio',
                      onPick: () => _pickTime(_iniCtrl)),
                  _TimeField(
                      controller: _finCtrl,
                      label: 'Fin',
                      onPick: () => _pickTime(_finCtrl)),
                  FilledButton.icon(
                    onPressed:
                        (_selSubcatId == null) ? null : _crearOAbrirSesionYListar,
                    icon: const Icon(Icons.playlist_add_check),
                    label: const Text('Crear / abrir sesión'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _rows.isEmpty
                            ? null
                            : () => _setAllStatus(EstatusAsistencia.presente),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Todos Presentes'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _rows.isEmpty
                            ? null
                            : () => _setAllStatus(EstatusAsistencia.ausente),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Todos Ausentes'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _alumnoSearchCtrl,
                          decoration: const InputDecoration(
                            isDense: true,
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Buscar alumno...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed:
                            (_rows.isEmpty || _idSesion == null) ? null : _guardar,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rowsTable(
                  rows: _rowsFiltered,
                  onChanged: (idx, r) {
                    final origIndex =
                        _rows.indexWhere((x) => x.idEstudiante == r.idEstudiante);
                    if (origIndex >= 0) {
                      setState(() => _rows[origIndex] = r);
                    }
                  },
                ),
        ),
      ],
    );
  }

  // ===== Tarjeta de resumen de historial =====
  Widget _buildHistSummaryRow() {
    final theme = Theme.of(context);
    final totalSesiones = _sesionesHistorial.length;

    int totalPresentes = 0;
    int totalCapacidad = 0;

    for (final s in _sesionesHistorial) {
      final p = _toIntOrNull(s['presentes'] ?? s['presentes_count'] ?? s['asistentes']) ?? 0;
      final t = _toIntOrNull(s['total'] ?? s['total_estudiantes'] ?? s['inscritos']) ?? 0;
      totalPresentes += p;
      totalCapacidad += t;
    }

    final porcentajeGlobal =
        (totalCapacidad > 0) ? (totalPresentes / totalCapacidad * 100) : 0.0;

    Widget _statCard({
      required IconData icon,
      required String label,
      required String value,
      Color? color,
    }) {
      final c = color ?? theme.colorScheme.primaryContainer;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _statCard(
          icon: Icons.event_note,
          label: 'Sesiones en el rango',
          value: '$totalSesiones',
        ),
        _statCard(
          icon: Icons.groups,
          label: 'Total asistencias registradas',
          value: '$totalPresentes / $totalCapacidad',
        ),
        _statCard(
          icon: Icons.bar_chart_rounded,
          label: 'Asistencia promedio',
          value: totalCapacidad == 0 ? '—' : '${porcentajeGlobal.toStringAsFixed(1)} %',
        ),
      ],
    );
  }

  // ===== PESTAÑA 2: HISTORIAL (LISTA) =====
  Widget _buildHistoryTab(TabController tabController) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$_histDesde  →  $_histHasta',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range),
                    label: const Text('Cambiar rango'),
                  ),
                  const SizedBox(width: 4),
                  IconButton.outlined(
                    onPressed: _loadHistorial,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Exportar Historial',
                    enabled: !_loadingHist && _sesionesHistorial.isNotEmpty,
                    onSelected: (v) async {
                      try {
                        if (v == 'excel') {
                          await _exportHistorialExcel();
                        } else if (v == 'pdf') {
                          await _exportHistorialPdf();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al exportar: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'excel',
                        child: ListTile(
                          leading: Icon(Icons.grid_on),
                          title: Text('Exportar a Excel'),
                          subtitle: Text('Lista de sesiones'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf),
                          title: Text('Exportar a PDF'),
                          subtitle: Text('Lista de sesiones'),
                        ),
                      ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Icon(Icons.download),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loadingHist
              ? const Center(child: CircularProgressIndicator())
              : (_sesionesHistorial.isEmpty
                  ? const Center(child: Text('Sin sesiones registradas en el rango seleccionado'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: _buildHistSummaryRow(),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withOpacity(0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 720),
                                      child: SingleChildScrollView(
                                        child: DataTable(
                                          headingRowColor: MaterialStateProperty.all(
                                            theme.colorScheme.surfaceVariant,
                                          ),
                                          columns: const [
                                            DataColumn(
                                              label: Text('Fecha',
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            DataColumn(
                                              label: Text('Horario',
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            DataColumn(
                                              label: Text('Presentes',
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            DataColumn(
                                              label: Text('% Asistencia',
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                            DataColumn(
                                              label: Text('Acciones',
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                          rows: _sesionesHistorial.map((s) {
                                            final fechaStr =
                                                _pickStr(s, ['fecha', 'fechaISO', 'dia']);
                                            final fecha = _fmtDate(fechaStr);
                                            final hi =
                                                _pickStr(s, ['hora_inicio', 'horaInicio']);
                                            final hf =
                                                _pickStr(s, ['hora_fin', 'horaFin']);
                                            final horario = (hi.isNotEmpty && hf.isNotEmpty)
                                                ? '$hi – $hf'
                                                : 'N/A';

                                            final p = _toIntOrNull(
                                                  s['presentes'] ??
                                                      s['presentes_count'] ??
                                                      s['asistentes'],
                                                ) ??
                                                0;
                                            final t = _toIntOrNull(
                                                  s['total'] ??
                                                      s['total_estudiantes'] ??
                                                      s['inscritos'],
                                                ) ??
                                                0;
                                            final pct =
                                                (t > 0) ? (p / t * 100).toStringAsFixed(1) : '—';

                                            final id = _readIdSesion(s);

                                            return DataRow(
                                              cells: [
                                                DataCell(Text(fecha)),
                                                DataCell(Text(horario)),
                                                DataCell(Text('$p / $t')),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.circle,
                                                        size: 10,
                                                        color: t == 0
                                                            ? theme.disabledColor
                                                            : (p / (t == 0 ? 1 : t)) >= 0.8
                                                                ? Colors.green
                                                                : (p / (t == 0 ? 1 : t)) >= 0.5
                                                                    ? Colors.orange
                                                                    : Colors.red,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(t == 0 ? '—' : '$pct %'),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  TextButton.icon(
                                                    onPressed: id == null
                                                        ? null
                                                        : () => _abrirSesionExistente(
                                                              s,
                                                              tabController,
                                                            ),
                                                    icon: const Icon(Icons.open_in_new, size: 18),
                                                    label: const Text('Abrir'),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
        ),
      ],
    );
  }

  // ===== PESTAÑA 3: CALENDARIO =====
  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              locale: 'es_ES',
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _filtrarSesionesDelDia(selectedDay);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
                final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

                setState(() {
                  _histDesde = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
                  _histHasta = DateFormat('yyyy-MM-dd').format(lastDayOfMonth);
                  _selectedDay = null;
                  _sesionesDelDiaSeleccionado = [];
                });
                _loadHistorial();
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  final key = DateTime.utc(day.year, day.month, day.day);
                  final resumen = _sesionResumenes[key];
                  if (resumen != null) {
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          resumen,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _selectedDay == null
                  ? 'Sesiones del mes'
                  : 'Sesiones para: ${DateFormat('EEE dd, MMM y', 'es').format(_selectedDay!)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (_selectedDay == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
              child: Center(
                child: Text(
                  'Selecciona un día en el calendario para ver el detalle de las sesiones.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_loadingHist)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_sesionesDelDiaSeleccionado.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 20),
              child: Center(
                child: Text(
                  'No se encontraron sesiones registradas para este día.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sesionesDelDiaSeleccionado.length,
              itemBuilder: (_, i) {
                final s = _sesionesDelDiaSeleccionado[i];
                return _HistorialSesionTile(
                  sesion: s,
                  onAbrir: (sesion) =>
                      _abrirSesionExistente(sesion, DefaultTabController.of(context)),
                );
              },
            )
        ],
      ),
    );
  }

  // ===== Resumen para Reporte Alumno =====
  Widget _buildReporteAlumnoSummary() {
    if (_historialAlumno.isEmpty) return const SizedBox.shrink();

    int presentes = 0;
    int ausentes = 0;
    int tardes = 0;
    int justificados = 0;
    final total = _historialAlumno.length;

    for (final item in _historialAlumno) {
      final estatus = estatusAsistenciaFromString(item['estatus']?.toString());
      switch (estatus) {
        case EstatusAsistencia.presente:
          presentes++;
          break;
        case EstatusAsistencia.ausente:
          ausentes++;
          break;
        case EstatusAsistencia.tarde:
          tardes++;
          break;
        case EstatusAsistencia.justificado:
          justificados++;
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          Chip(
            avatar: const Icon(Icons.check_circle, color: Colors.green),
            label: Text('Presente: $presentes'),
          ),
          Chip(
            avatar: const Icon(Icons.schedule, color: Colors.orange),
            label: Text('Tarde: $tardes'),
          ),
          Chip(
            avatar: const Icon(Icons.cancel, color: Colors.red),
            label: Text('Ausente: $ausentes'),
          ),
          Chip(
            avatar: const Icon(Icons.assignment_turned_in, color: Colors.blue),
            label: Text('Justificado: $justificados'),
          ),
          Chip(
            label: Text('Total Sesiones: $total',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===== PESTAÑA 4: REPORTE POR ALUMNO =====
  Widget _buildStudentReportTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: DropdownButtonFormField<int>(
            value: _selAlumnoReporteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Seleccionar Estudiante',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            items: _rows.map((_RowAlumno alumno) {
              return DropdownMenuItem<int>(
                value: alumno.idEstudiante,
                child: Text(alumno.nombre, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                _loadHistorialPorEstudiante(newValue);
              }
            },
          ),
        ),
        Expanded(
          child: _selAlumnoReporteId == null
              ? const Center(child: Text('Selecciona un alumno para ver su reporte'))
              : _loadingReporteAlumno
                  ? const Center(child: CircularProgressIndicator())
                  : _historialAlumno.isEmpty
                      ? const Center(
                          child: Text(
                              'Este alumno no tiene asistencias registradas en el rango'))
                      : Column(
                          children: [
                            _buildReporteAlumnoSummary(),
                            const Divider(),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: _historialAlumno.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1, indent: 16, endIndent: 16),
                                itemBuilder: (context, index) {
                                  final item = _historialAlumno[index];

                                  final estatus =
                                      estatusAsistenciaFromString(item['estatus']?.toString());
                                  final (icon, color) = _StatusToggle._info[estatus]!;

                                  final fechaStr = _pickStr(item, ['fecha', 'fechaISO', 'dia']);
                                  final fechaFmt = _fmtDate(fechaStr);
                                  final obs = _pickStr(item, ['observaciones', 'obs']);

                                  return ListTile(
                                    leading: Icon(icon, color: color),
                                    title: Text(fechaFmt),
                                    subtitle: obs.isNotEmpty ? Text('Obs: $obs') : null,
                                    trailing: Chip(
                                      label: Text(
                                        estatusAsistenciaToString(estatus).toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: color.withOpacity(0.1),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
        ),
      ],
    );
  }

  // =================================================================
  // ===== EXPORTACIÓN ===============================================
  // =================================================================

  String _fmtDate(Object? v) {
    if (v == null) return '—';
    final s = v.toString();
    try {
      final d = DateTime.parse(s);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return s.isEmpty ? '—' : s;
    }
  }

  String _pickStr(Map r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v != null && '$v'.isNotEmpty) return '$v';
    }
    return '';
  }

  xls.CellValue _cv(dynamic v) {
    if (v == null) return  xls.TextCellValue('');
    if (v is bool) return xls.BoolCellValue(v);
    if (v is int) return xls.IntCellValue(v);
    if (v is double) return xls.DoubleCellValue(v);
    final s = '$v';
    final n = double.tryParse(s);
    return (n != null) ? xls.DoubleCellValue(n) : xls.TextCellValue(s);
  }

  Future<String?> _pickSavePath({
    required String suggestedName,
    required List<String> extensions,
    String? label,
    List<String>? mimeTypes,
  }) async {
    if (kIsWeb) return suggestedName;
    final location = await getSaveLocation(
      acceptedTypeGroups: [
        XTypeGroup(
          label: label ?? 'Archivo',
          extensions: extensions,
          mimeTypes: mimeTypes,
        ),
      ],
      suggestedName: suggestedName,
    );
    return location?.path;
  }

  Future<void> _saveBytes(
    Uint8List bytes, {
    required String defaultFileName,
    required List<String> extensions,
    String? mimeType,
  }) async {
    try {
      if (kIsWeb) {
        final xf = XFile.fromData(bytes, name: defaultFileName, mimeType: mimeType);
        await xf.saveTo(defaultFileName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Descarga iniciada: $defaultFileName')),
        );
        return;
      }

      final path = await _pickSavePath(
        suggestedName: defaultFileName,
        extensions: extensions,
        mimeTypes: mimeType == null ? null : [mimeType],
      );

      if (path == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado cancelado')),
        );
        return;
      }

      final xf = XFile.fromData(bytes, name: defaultFileName, mimeType: mimeType);
      await xf.saveTo(path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo guardado en: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    }
  }

  pw.Widget _buildSectionHeader(
    String title,
    IconData icon,
    PdfColor color,
    pw.Font materialFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(4),
          topRight: pw.Radius.circular(4),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Icon(
            pw.IconData(icon.codePoint),
            font: materialFont,
            color: PdfColors.white,
            size: 16,
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportHistorialExcel() async {
    final rows = _sesionesHistorial;
    if (rows.isEmpty) throw Exception('No hay datos para exportar');

    final nombreSubcat = _selSubcatNombre ?? 'historial';

    final book = xls.Excel.createExcel();
    final sheet = book['Historial'];
    sheet.appendRow( [
      xls.TextCellValue('Fecha'),
      xls.TextCellValue('Hora Inicio'),
      xls.TextCellValue('Hora Fin'),
      xls.TextCellValue('Presentes'),
      xls.TextCellValue('Total'),
    ]);

    for (final r in rows) {
      final fecha = _fmtDate(_pickStr(r, ['fecha', 'fechaISO', 'dia']));
      final hi = _pickStr(r, ['hora_inicio', 'horaInicio']);
      final hf = _pickStr(r, ['hora_fin', 'horaFin']);
      final presentes = _toIntOrNull(r['presentes'] ?? r['presentes_count'] ?? r['asistentes']);
      final total = _toIntOrNull(r['total'] ?? r['total_estudiantes'] ?? r['inscritos']);

      sheet.appendRow([
        _cv(fecha),
        _cv(hi),
        _cv(hf),
        _cv(presentes),
        _cv(total),
      ]);
    }
    final encoded = book.encode()!;
    final bytes = Uint8List.fromList(encoded);
    await _saveBytes(
      bytes,
      defaultFileName: 'asistencia_${nombreSubcat}.xlsx',
      extensions: const ['xlsx'],
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<Uint8List> _buildHistorialPdfBytes() async {
    final rows = _sesionesHistorial;
    if (rows.isEmpty) throw Exception('No hay datos para exportar');

    final robotoData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final robotoFont = pw.Font.ttf(robotoData);
    final materialData =
        await rootBundle.load('assets/fonts/MaterialIcons-Regular.ttf');
    final materialFont = pw.Font.ttf(materialData);

    final doc = pw.Document();
    final nombreSubcat = _selSubcatNombre ?? 'Historial';
    final titulo = 'Historial de Asistencias';

    const baseColor = PdfColors.blueGrey800;
    const lightColor = PdfColors.grey100;

    pw.Widget buildCell(
      String text, {
      pw.Alignment alignment = pw.Alignment.centerLeft,
      bool isHeader = false,
      PdfColor? background,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        color: background,
        alignment: alignment,
        child: pw.Text(
          text,
          style: isHeader
              ? pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                )
              : const pw.TextStyle(fontSize: 10),
        ),
      );
    }

    final List<pw.TableRow> tableRows = [];

    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: baseColor),
        children: [
          buildCell('Fecha', isHeader: true, alignment: pw.Alignment.center),
          buildCell('Horario', isHeader: true, alignment: pw.Alignment.center),
          buildCell('Asistencia', isHeader: true, alignment: pw.Alignment.center),
        ],
      ),
    );

    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final background = i % 2 == 0 ? lightColor : null;

      final fecha = _fmtDate(_pickStr(r, ['fecha', 'fechaISO', 'dia']));
      final hi = _pickStr(r, ['hora_inicio', 'horaInicio']);
      final hf = _pickStr(r, ['hora_fin', 'horaFin']);
      final horario = (hi.isNotEmpty && hf.isNotEmpty) ? '$hi - $hf' : 'N/A';

      final presentes = _toIntOrNull(r['presentes'] ?? r['presentes_count'] ?? r['asistentes']);
      final total = _toIntOrNull(r['total'] ?? r['total_estudiantes'] ?? r['inscritos']);
      final asistencia =
          (presentes != null && total != null) ? '$presentes / $total' : 'N/A';

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: background),
          children: [
            buildCell(fecha, alignment: pw.Alignment.center),
            buildCell(horario, alignment: pw.Alignment.center),
            buildCell(asistencia, alignment: pw.Alignment.center),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(base: robotoFont),
        ),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  titulo.toUpperCase(),
                  style: pw.TextStyle(
                    color: baseColor,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  nombreSubcat,
                  style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 14),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey400, height: 8),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado el: ${_fmtDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (context) => [
          _buildSectionHeader(
            'Sesiones en Rango ($_histDesde al $_histHasta)',
            Icons.history,
            baseColor,
            materialFont,
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: tableRows,
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total de sesiones: ${rows.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          )
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _exportHistorialPdf() async {
    final bytes = await _buildHistorialPdfBytes();
    final nombreSubcat = _selSubcatNombre ?? 'historial';
    await _saveBytes(
      bytes,
      defaultFileName: 'asistencia_${nombreSubcat}.pdf',
      extensions: const ['pdf'],
      mimeType: 'application/pdf',
    );
  }
}

// ===== Widgets auxiliares =====
class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onPick;
  const _TimeField({
    required this.controller,
    required this.label,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onPick,
        decoration: InputDecoration(
          labelText: '$label (HH:mm)',
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
      ),
    );
  }
}

class _EmptySubcats extends StatelessWidget {
  final Future<void> Function() onReload;
  const _EmptySubcats({required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('No hay subcategorías para mostrar'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onReload,
          icon: const Icon(Icons.refresh),
          label: const Text('Recargar'),
        ),
      ]),
    );
  }
}

// ===== WIDGET: _HistorialSesionTile (usado en Calendario) =====
class _HistorialSesionTile extends StatelessWidget {
  final Map<String, dynamic> sesion;
  final void Function(Map<String, dynamic>) onAbrir;

  const _HistorialSesionTile({required this.sesion, required this.onAbrir});

  String _pickStr(Map r, List<String> keys) {
    for (final k in keys) {
      final v = r[k];
      if (v != null && '$v'.isNotEmpty) return '$v';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final s = sesion;
    final id = _readIdSesion(s);
    final fecha = _pickStr(s, ['fecha', 'fechaISO', 'dia']);
    final fShort = fecha.isNotEmpty
        ? (fecha.length >= 10 ? fecha.substring(0, 10) : fecha)
        : null;

    DateTime? fechaDt;
    if (fShort != null) {
      try {
        fechaDt = DateTime.parse(fShort);
      } catch (_) {}
    }

    final hi = _pickStr(s, ['hora_inicio', 'horaInicio']);
    final hf = _pickStr(s, ['hora_fin', 'horaFin']);
    final horario = (hi.isNotEmpty && hf.isNotEmpty) ? '$hi - $hf' : 'N/A';

    final presentes = s['presentes'] ?? s['presentes_count'] ?? s['asistentes'];
    final total = s['total'] ?? s['total_estudiantes'] ?? s['inscritos'];

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 50,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (fechaDt != null) ...[
                Text(
                  DateFormat('MMM', 'es').format(fechaDt).toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  DateFormat('dd').format(fechaDt),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ] else
                const Icon(Icons.event_busy),
            ],
          ),
        ),
        title: Text(horario, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: (presentes != null && total != null)
            ? Text('Asistencia: $presentes / $total')
            : const Text('Sin detalle de asistencia'),
        trailing: TextButton(
          onPressed: id == null ? null : () => onAbrir(s),
          child: const Text('Abrir'),
        ),
      ),
    );
  }
}

// ===== Modelo _RowAlumno usa Estatus =====
class _RowAlumno {
  final int idEstudiante;
  final String nombre;
  EstatusAsistencia estatus;
  String observaciones;
  _RowAlumno({
    required this.idEstudiante,
    required this.nombre,
    this.estatus = EstatusAsistencia.ausente,
    this.observaciones = '',
  });
}

// ===== Selector de estatus =====
class _StatusToggle extends StatelessWidget {
  final EstatusAsistencia estatus;
  final ValueChanged<EstatusAsistencia> onEstatusChanged;

  const _StatusToggle({
    required this.estatus,
    required this.onEstatusChanged,
  });

  static const Map<EstatusAsistencia, (IconData, Color)> _info = {
    EstatusAsistencia.presente: (Icons.check_circle, Colors.green),
    EstatusAsistencia.tarde: (Icons.schedule, Colors.orange),
    EstatusAsistencia.ausente: (Icons.cancel, Colors.red),
    EstatusAsistencia.justificado: (Icons.assignment_turned_in, Colors.blue),
  };

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: EstatusAsistencia.values.map((e) => e == estatus).toList(),
      onPressed: (index) {
        onEstatusChanged(EstatusAsistencia.values[index]);
      },
      borderRadius: BorderRadius.circular(8),
      selectedColor: Colors.white,
      fillColor: _info[estatus]!.$2.withOpacity(0.8),
      color: _info[estatus]!.$2.withOpacity(0.6),
      borderColor: Colors.grey.withOpacity(0.3),
      selectedBorderColor: _info[estatus]!.$2.withOpacity(0.5),
      constraints: const BoxConstraints(minHeight: 36.0, minWidth: 36.0),
      children: EstatusAsistencia.values.map((e) {
        final (icon, _) = _info[e]!;
        return Tooltip(
          message: estatusAsistenciaToString(e).toUpperCase(),
          child: Icon(icon, size: 20),
        );
      }).toList(),
    );
  }
}

// ===== Tabla de alumnos =====
Widget _rowsTable({
  required List<_RowAlumno> rows,
  required void Function(int, _RowAlumno) onChanged,
}) {
  if (rows.isEmpty) return const Center(child: Text('Sin alumnos'));

  return Material(
    elevation: 1,
    child: ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = rows[i];
        return ListTile(
          dense: true,
          leading: _StatusToggle(
            estatus: r.estatus,
            onEstatusChanged: (v) => onChanged(
              i,
              _RowAlumno(
                idEstudiante: r.idEstudiante,
                nombre: r.nombre,
                estatus: v,
                observaciones: r.observaciones,
              ),
            ),
          ),
          title: Text(r.nombre),
          trailing: SizedBox(
            width: 300,
            child: TextFormField(
              initialValue: r.observaciones,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Observaciones',
                isDense: true,
              ),
              onChanged: (v) => onChanged(
                i,
                _RowAlumno(
                  idEstudiante: r.idEstudiante,
                  nombre: r.nombre,
                  estatus: r.estatus,
                  observaciones: v,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
