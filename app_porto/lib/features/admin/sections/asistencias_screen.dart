// lib/features/admin/sections/admin_asistencias_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/app_scope.dart';
import '../../../core/constants/endpoints.dart';

String _todayISO() => DateFormat('yyyy-MM-dd').format(DateTime.now());

// ===== Helpers robustos =====
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

class AdminAsistenciasScreen extends StatefulWidget {
  const AdminAsistenciasScreen({super.key});
  @override
  State<AdminAsistenciasScreen> createState() => _AdminAsistenciasScreenState();
}

class _AdminAsistenciasScreenState extends State<AdminAsistenciasScreen> {
  // Repos
  get _subcatsRepo => AppScope.of(context).subcategorias;
  get _asistRepo   => AppScope.of(context).asistencias;
  get _http        => AppScope.of(context).http;

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
  List<_RowAlumno> _rows = [];
  final _alumnoSearchCtrl = TextEditingController();

  // Historial
  String _histDesde = _isoNDiasAtras(30);
  String _histHasta = _todayISO();
  bool _loadingHist = false;
  List<Map<String, dynamic>> _sesionesHistorial = [];

  static String _isoNDiasAtras(int n) =>
      DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: n)));

  @override
  void initState() {
    super.initState();
    _subcatSearchCtrl.addListener(_applySubcatFilter);
    _alumnoSearchCtrl.addListener(_applyAlumnoFilter);

    // Cargar subcategorías post-frame (evita dependOnInheritedWidget en initState)
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
      final parsed = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _subcats = parsed;
        _filteredSubcats = parsed;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _subcats = [];
        _filteredSubcats = [];
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
    final res = await _http.get(Endpoints.subcategorias, headers: const {'Accept': 'application/json'});
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
        final nombre = (m['nombre'] ?? m['nombre_subcategoria'] ?? '').toString().toLowerCase();
        return nombre.contains(q);
      }).toList();
    });
  }

  // ====== SESIÓN & ALUMNOS ======
  Future<void> _crearOAbrirSesionYListar() async {
    final id = _selSubcatId;
    if (id == null) return;

    setState(() { _loading = true; _rows = []; _idSesion = null; });

    try {
      // Buscar sesión existente para esta fecha
      final sesiones = await _asistRepo.listarSesiones(idSubcategoria: id, fechaISO: _fecha);
      Map<String, dynamic>? sesion =
          sesiones.isNotEmpty ? Map<String, dynamic>.from(sesiones.first as Map) : null;

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
        final idEst = _toIntOrZero(me['id_estudiante'] ?? me['idEstudiante']);
        if (idEst == 0) continue;
        final nombre = [
          (me['apellidos'] ?? me['apellido'] ?? '').toString(),
          (me['nombres']   ?? me['nombre']   ?? '').toString(),
        ].where((s) => s.isNotEmpty).join(' ');
        map[idEst] = _RowAlumno(idEstudiante: idEst, nombre: nombre);
      }

      // Marcas ya registradas
      if (_idSesion != null) {
        final marcas = await _asistRepo.detalleSesion(_idSesion!);
        for (final m in marcas) {
          final mm = Map<String, dynamic>.from(m as Map);
          final idEst = _toIntOrNull(mm['id_estudiante'] ?? mm['idEstudiante']);
          if (idEst == null) continue;
          final presente = mm['presente'] == true;
          final obs = (mm['observaciones'] ?? '').toString();
          map[idEst] = (map[idEst] ?? _RowAlumno(idEstudiante: idEst, nombre: ''))
            ..presente = presente
            ..observaciones = obs;
        }
      }

      setState(() {
        _rows = map.values.toList()..sort((a, b) => a.nombre.compareTo(b.nombre));
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
  Future<void> _abrirSesionExistente(Map<String, dynamic> sesion) async {
    final id = _selSubcatId;
    if (id == null) return;
    // Configura fecha/horas si vienen
    final fechaRaw = (sesion['fecha'] ?? sesion['fechaISO'] ?? sesion['dia'])?.toString();
    if (fechaRaw != null && fechaRaw.isNotEmpty) {
      // tomar yyyy-MM-dd del inicio
      final iso = fechaRaw.length >= 10 ? fechaRaw.substring(0, 10) : fechaRaw;
      setState(() => _fecha = iso);
    }
    final hi = (sesion['hora_inicio'] ?? sesion['horaInicio'])?.toString();
    final hf = (sesion['hora_fin'] ?? sesion['horaFin'])?.toString();
    if (hi != null && hi.isNotEmpty) _iniCtrl.text = hi;
    if (hf != null && hf.isNotEmpty) _finCtrl.text = hf;

    // Reutiliza el flujo que busca/crea y lista (no recreará si ya existe)
    await _crearOAbrirSesionYListar();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1, 1, 1);
    final last = DateTime(now.year + 1, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_fecha),
      firstDate: first,
      lastDate: last,
      locale: const Locale('es'),
    );
    if (picked != null) setState(() => _fecha = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: (parts.isNotEmpty ? int.tryParse(parts[0]) : null) ?? 8,
      minute: (parts.length > 1 ? int.tryParse(parts[1]) : null) ?? 0,
    );
    final t = await showTimePicker(context: context, initialTime: initial, helpText: 'Selecciona hora');
    if (t != null) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      setState(() => ctrl.text = '$h:$m');
    }
  }

  void _toggleAll(bool v) => setState(() { for (final r in _rows) r.presente = v; });

  Future<void> _guardar() async {
    if (_idSesion == null) return;
    try {
      final marcas = _rows.map((r) => {
        'id_estudiante': r.idEstudiante,
        'presente': r.presente,
        if (r.observaciones.trim().isNotEmpty) 'observaciones': r.observaciones.trim(),
      }).toList();
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

  // ====== HISTORIAL ======
  Future<void> _pickRange() async {
    final initialStart = DateTime.parse(_histDesde);
    final initialEnd   = DateTime.parse(_histHasta);
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
    // 1) Intenta con métodos del repo si existen (flexible)
    try {
      final dyn = _asistRepo as dynamic;
      final r = await dyn.listarSesiones(idSubcategoria: subcatId, desde: desde, hasta: hasta);
      if (r is List) return r;
    } catch (_) {}
    try {
      final dyn = _asistRepo as dynamic;
      final r = await dyn.historialSesiones(subcategoriaId: subcatId, desde: desde, hasta: hasta);
      if (r is List) return r;
    } catch (_) {}

    // 2) Fallback: GET directo
    final path = '/asistencias/sesiones?subcategoria=$subcatId&desde=$desde&hasta=$hasta';
    final res = await _http.get(path, headers: const {'Accept': 'application/json'});
    return (res as List);
  }

  Future<void> _loadHistorial() async {
    final id = _selSubcatId;
    if (id == null) return;
    setState(() => _loadingHist = true);
    try {
      final list = await _fetchSesionesHistorial(subcatId: id, desde: _histDesde, hasta: _histHasta);
      final parsed = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _sesionesHistorial = parsed;
        _loadingHist = false;
      });
    } catch (e) {
      setState(() {
        _sesionesHistorial = [];
        _loadingHist = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No pude cargar el historial: $e')),
      );
    }
  }

  // ====== FILTRO DE ALUMNOS EN MEMORIA ======
  List<_RowAlumno> get _rowsFiltered {
    final q = _alumnoSearchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) => r.nombre.toLowerCase().contains(q)).toList();
  }
  void _applyAlumnoFilter() => setState(() { /* solo para rebuild */ });

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final isStepElegir = _step == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStepElegir ? 'Asistencias · Subcategorías' : 'Asistencias · ${_selSubcatNombre ?? ''}'),
        leading: isStepElegir ? null : BackButton(onPressed: () {
          setState(() {
            _step = 0;
            _rows.clear();
            _idSesion = null;
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
                      final cross = w >= 1200 ? 4 : w >= 900 ? 3 : w >= 600 ? 2 : 1;
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
                          final id = _toIntOrZero(it['id'] ?? it['id_subcategoria']);
                          final nombre = (it['nombre'] ?? it['nombre_subcategoria'] ?? 'Sin nombre').toString();

                          return InkWell(
                            onTap: () async {
                              setState(() {
                                _selSubcatId = id;
                                _selSubcatNombre = nombre;
                                _step = 1;
                              });
                              // Carga la sesión (hoy) y también el historial por defecto
                              await _crearOAbrirSesionYListar();
                              await _loadHistorial();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // Tabs: Tomar asistencia / Historial
  Widget _buildStepAttendanceTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Tomar asistencia', icon: Icon(Icons.fact_check_outlined)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
          ]),
          Expanded(
            child: TabBarView(
              children: [
                _buildTakeAttendanceTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeAttendanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controles de sesión
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Fecha: $_fecha', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Cambiar'),
                    onPressed: _pickDate,
                  ),
                ],
              ),
              _TimeField(controller: _iniCtrl, label: 'Inicio', onPick: () => _pickTime(_iniCtrl)),
              _TimeField(controller: _finCtrl,  label: 'Fin',    onPick: () => _pickTime(_finCtrl)),
              FilledButton.icon(
                onPressed: (_selSubcatId == null) ? null : _crearOAbrirSesionYListar,
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('Crear / abrir sesión'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Acciones + buscador alumno
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _rows.isEmpty ? null : () => _toggleAll(true),
                icon: const Icon(Icons.check_box),
                label: const Text('Marcar todos'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _rows.isEmpty ? null : () => _toggleAll(false),
                icon: const Icon(Icons.check_box_outline_blank),
                label: const Text('Desmarcar todos'),
              ),
              const Spacer(),
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
                onPressed: (_rows.isEmpty || _idSesion == null) ? null : _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rowsTable(
                  rows: _rowsFiltered,
                  onChanged: (idx, r) {
                    final origIndex = _rows.indexWhere((x) => x.idEstudiante == r.idEstudiante);
                    if (origIndex >= 0) {
                      setState(() => _rows[origIndex] = r);
                    }
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Filtros de rango
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Text('Desde: $_histDesde · Hasta: $_histHasta'),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range),
                label: const Text('Cambiar rango'),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _loadHistorial,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loadingHist
              ? const Center(child: CircularProgressIndicator())
              : (_sesionesHistorial.isEmpty
                ? const Center(child: Text('Sin sesiones en el rango'))
                : ListView.separated(
                    itemCount: _sesionesHistorial.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = _sesionesHistorial[i];
                      final id = _readIdSesion(s);
                      final fecha = (s['fecha'] ?? s['fechaISO'] ?? s['dia'] ?? '').toString();
                      final fShort = fecha.isNotEmpty
                          ? (fecha.length >= 10 ? fecha.substring(0, 10) : fecha)
                          : '(sin fecha)';
                      final hi = (s['hora_inicio'] ?? s['horaInicio'] ?? '--:--').toString();
                      final hf = (s['hora_fin'] ?? s['horaFin'] ?? '--:--').toString();

                      // Si el backend devuelve conteos, los mostramos (opcionales)
                      final presentes = s['presentes'] ?? s['presentes_count'] ?? s['asistentes'];
                      final total = s['total'] ?? s['total_estudiantes'] ?? s['inscritos'];

                      return ListTile(
                        leading: const Icon(Icons.event_note),
                        title: Text('Fecha: $fShort  ·  $hi - $hf'),
                        subtitle: (presentes != null && total != null)
                            ? Text('Presentes: $presentes / $total')
                            : null,
                        trailing: TextButton.icon(
                          onPressed: id == null ? null : () => _abrirSesionExistente(s),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Abrir'),
                        ),
                      );
                    },
                  )),
        ),
      ],
    );
  }
}

// ===== Widgets auxiliares =====
class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onPick;
  const _TimeField({required this.controller, required this.label, required this.onPick});

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

class _RowAlumno {
  final int idEstudiante;
  final String nombre;
  bool presente;
  String observaciones;
  _RowAlumno({
    required this.idEstudiante,
    required this.nombre,
    this.presente = false,
    this.observaciones = '',
  });
}

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
          leading: Checkbox(
            value: r.presente,
            onChanged: (v) => onChanged(
              i,
              _RowAlumno(
                idEstudiante: r.idEstudiante,
                nombre: r.nombre,
                presente: v ?? false,
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
                  presente: r.presente,
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
