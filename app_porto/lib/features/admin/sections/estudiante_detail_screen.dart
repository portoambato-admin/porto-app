import 'package:flutter/material.dart';
import 'package:app_porto/app/app_scope.dart';
import '../presentation/widgets/pagos_mensualidad_panel.dart';

class EstudianteDetailScreen extends StatefulWidget {
  final int id;
  const EstudianteDetailScreen({super.key, required this.id});

  @override
  State<EstudianteDetailScreen> createState() => _EstudianteDetailScreenState();
}

class _EstudianteDetailScreenState extends State<EstudianteDetailScreen>
    with SingleTickerProviderStateMixin {
  // Repos
  late final _est  = AppScope.of(context).estudiantes;
  late final _mat  = AppScope.of(context).matriculas;
  late final _asig = AppScope.of(context).subcatEst;
  late final _cats = AppScope.of(context).categorias;
  late final _subs = AppScope.of(context).subcategorias;

  // Tabs
  late final TabController _tab = TabController(length: 2, vsync: this);

  // Estado
  Map<String, dynamic>? _info;
  Map<String, dynamic>? _matricula; // única (si existe)
  List<Map<String, dynamic>> _asignaciones = [];
  List<Map<String, dynamic>> _categorias = [];

  // UI asignación subcategoría
  int? _catForAssign;
  int? _subToAssign;
  List<Map<String, dynamic>> _subsDeCat = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final info  = await _est.byId(widget.id);
      final mats  = await _mat.porEstudiante(widget.id);
      final unica = (mats.isNotEmpty) ? mats.first : null;
      final asign = await _asig.porEstudiante(widget.id);
      final cats  = await _fetchCategorias();

      setState(() {
        _info = info;
        _matricula = unica;
        _asignaciones = asign;
        _categorias = cats;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Helpers de formato ----------
  String _fmt(Object? v) => (v == null || '$v'.trim().isEmpty) ? '—' : '$v';

  String _fmtDate(Object? v) {
    if (v == null) return '—';
    final s = v.toString();
    try {
      final d = DateTime.parse(s);
      return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    } catch (_) {
      return s.isEmpty ? '—' : s; // ya formateada
    }
  }

  String _categoriaLabel(Map<String, dynamic>? m) {
    if (m == null) return '—';
    final byName = m['categoriaNombre'];
    if (byName != null && byName.toString().trim().isNotEmpty) return '$byName';

    final id = m['idCategoria'] ?? m['id_categoria'];
    if (id == null) return '—';

    final match = _categorias.firstWhere(
      (c) => ((c['id_categoria'] ?? c['id']).toString() == '$id'),
      orElse: () => const {},
    );
    return (match['nombre_categoria'] ?? match['nombre'] ?? '—').toString();
  }

  // ---------- Helpers repos ----------
  Future<List<Map<String, dynamic>>> _fetchCategorias() async {
    final dyn = _cats as dynamic;
    try { final r = await dyn.activas(); return List<Map<String, dynamic>>.from(r); } catch (_) {}
    try { final r = await dyn.todas();   return List<Map<String, dynamic>>.from(r); } catch (_) {}
    try { final r = await dyn.listar();  return List<Map<String, dynamic>>.from(r); } catch (_) {}
    try { final r = await dyn.getAll();  return List<Map<String, dynamic>>.from(r); } catch (_) {}
    return const <Map<String, dynamic>>[];
  }

  Future<void> _loadSubsForCat(int idCat) async {
    final dyn = _subs as dynamic;
    try {
      final r = await dyn.porCategoria(idCat);
      setState(() {
        _subsDeCat = List<Map<String, dynamic>>.from(r);
        _subToAssign = null;
      });
      return;
    } catch (_) {}
    // Fallback: traer todas y filtrar por id_categoria / idCategoria
    try {
      final all = await dyn.todas();
      final list = List<Map<String, dynamic>>.from(all).where((e) {
        final a = e['id_categoria'] ?? e['idCategoria'];
        return a?.toString() == '$idCat';
      }).toList();
      setState(() {
        _subsDeCat = list;
        _subToAssign = null;
      });
    } catch (_) {
      setState(() { _subsDeCat = []; _subToAssign = null; });
    }
  }

  Future<void> _updateMatriculaFlexible({
    required int idMatricula,
    int? idCategoria,
    String? ciclo,
    String? fechaISO, // yyyy-MM-dd
  }) async {
    final dyn = _mat as dynamic;
    final Map<String, dynamic> dataSnake = {
      if (idCategoria != null) 'id_categoria': idCategoria,
      if (ciclo != null) 'ciclo': ciclo,
      if (fechaISO != null) 'fecha_matricula': fechaISO,
    };
    final Map<String, dynamic> dataCamel = {
      if (idCategoria != null) 'idCategoria': idCategoria,
      if (ciclo != null) 'ciclo': ciclo,
      if (fechaISO != null) 'fechaMatricula': fechaISO,
    };

    try { await dyn.update(idMatricula: idMatricula, idCategoria: idCategoria, ciclo: ciclo, fechaISO: fechaISO); return; } catch (_) {}
    try { await dyn.actualizar(idMatricula, dataSnake); return; } catch (_) {}
    try { await dyn.patch(idMatricula, dataSnake); return; } catch (_) {}
    try { await dyn.update(idMatricula, dataSnake); return; } catch (_) {}
    try { await dyn.actualizar({'id_matricula': idMatricula, ...dataSnake}); return; } catch (_) {}
    try { await dyn.actualizar({'idMatricula': idMatricula, ...dataCamel}); return; } catch (_) {}
    try {
      final payload = Map<String, dynamic>.from(dataSnake);
      payload['id_matricula'] = idMatricula;
      await dyn.update(payload);
      return;
    } catch (_) {}

    throw 'Tu MatriculasRepository no expone un método de actualización compatible.';
  }

  Future<void> _createMatriculaFlexible({
    required int idEstudiante,
    required int idCategoria,
    String? ciclo,
    String? fechaISO, // yyyy-MM-dd
  }) async {
    final dyn = _mat as dynamic;
    try {
      await dyn.crear(
        idEstudiante: idEstudiante,
        idCategoria: idCategoria,
        ciclo: ciclo,
        fechaISO: fechaISO,
      );
      return;
    } catch (_) {}
    try {
      await dyn.crear(
        id_estudiante: idEstudiante,
        id_categoria: idCategoria,
        ciclo: ciclo,
        fecha_matricula: fechaISO,
      );
      return;
    } catch (_) {}
    final bodySnake = {
      'id_estudiante': idEstudiante,
      'id_categoria': idCategoria,
      if (ciclo != null && ciclo.isNotEmpty) 'ciclo': ciclo,
      if (fechaISO != null) 'fecha_matricula': fechaISO,
    };
    final bodyCamel = {
      'idEstudiante': idEstudiante,
      'idCategoria': idCategoria,
      if (ciclo != null && ciclo.isNotEmpty) 'ciclo': ciclo,
      if (fechaISO != null) 'fechaMatricula': fechaISO,
    };
    try { await dyn.crear(bodySnake); return; } catch (_) {}
    try { await dyn.crear(bodyCamel); return; } catch (_) {}

    throw 'Tu MatriculasRepository no expone un método de creación compatible.';
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final title = _info == null
        ? 'Estudiante'
        : '${_info!['nombres'] ?? ''} ${_info!['apellidos'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'Estudiante' : title),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Información'), Tab(text: 'Pagos')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tab,
                  children: [
                    _tabInformacion(),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: PagosMensualidadPanel(idEstudiante: widget.id),
                    ),
                  ],
                ),
    );
  }

  Widget _tabInformacion() {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    Widget _row(IconData ic, String label, Object? v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ic, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: txt.bodyMedium,
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style:
                            txt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: _fmt(v)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ===== Header =====
        Card(
          elevation: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    (_info?['nombres'] ?? 'E')[0].toString().toUpperCase(),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_fmt(_info?['nombres'])} ${_fmt(_info?['apellidos'])}',
                        style: txt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      _row(
                        Icons.cake,
                        'Nacimiento',
                        _fmtDate(_info?['fechaNacimiento'] ?? _info?['fecha_nacimiento']),
                      ),
                      _row(Icons.phone, 'Teléfono',   _info?['telefono']),
                      _row(Icons.home,  'Dirección',  _info?['direccion']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ===== Inscripción =====
        Card(
          elevation: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_turned_in),
                    const SizedBox(width: 8),
                    Text('Inscripción',
                        style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (_matricula != null)
                      FilledButton.tonalIcon(
                        onPressed: _editarInscripcionDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar inscripción'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: _crearInscripcionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear inscripción'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_matricula == null)
                  Row(
                    children: const [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Expanded(child: Text('Sin inscripción registrada.')),
                    ],
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.category, size: 18),
                        label: Text(_categoriaLabel(_matricula)),
                      ),
                      Chip(
                        avatar: const Icon(Icons.repeat, size: 18),
                        label: Text('Ciclo: ${_fmt(_matricula?['ciclo'])}'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.event, size: 18),
                        label: Text('Fecha: ${_fmtDate(_matricula?['fecha'] ?? _matricula?['fecha_matricula'])}'),
                      ),
                      Chip(
                        avatar: Icon(
                          _matricula?['activo'] == true ? Icons.check_circle : Icons.cancel,
                          size: 18,
                        ),
                        label: Text(_matricula?['activo'] == true ? 'Activa' : 'Inactiva'),
                        backgroundColor: _matricula?['activo'] == true
                            ? cs.primaryContainer
                            : cs.surfaceVariant,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ===== Subcategorías =====
        Card(
          elevation: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.legend_toggle_outlined),
                    const SizedBox(width: 8),
                    Text('Subcategorías asignadas',
                        style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),

                // --- Form de asignación ---
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<int>(
                        value: _catForAssign,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categorias.map((c) {
                          final id = c['id_categoria'] ?? c['id'];
                          final nombre = c['nombre_categoria'] ?? c['nombre'] ?? '—';
                          return DropdownMenuItem<int>(
                            value: (id is int) ? id : int.tryParse('$id'),
                            child: Text('$nombre'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _catForAssign = v;
                            _subsDeCat = [];
                            _subToAssign = null;
                          });
                          if (v != null) _loadSubsForCat(v);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<int>(
                        value: _subToAssign,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Subcategoría',
                          prefixIcon: Icon(Icons.label),
                        ),
                        items: _subsDeCat.map((s) {
                          final id = s['id_subcategoria'] ?? s['id'];
                          final nombre = s['nombre_subcategoria'] ?? s['nombre'] ?? '—';
                          return DropdownMenuItem<int>(
                            value: (id is int) ? id : int.tryParse('$id'),
                            child: Text('$nombre'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _subToAssign = v),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: (_subToAssign == null)
                          ? null
                          : () async {
                              try {
                                await _asig.asignar(
                                  idEstudiante: widget.id,
                                  idSubcategoria: _subToAssign!,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Subcategoría asignada')),
                                );
                                await _loadAll();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('Asignar'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                if (_asignaciones.isEmpty)
                  Row(
                    children: const [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Expanded(child: Text('Sin subcategorías asignadas.')),
                    ],
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _asignaciones.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (_, i) {
                      final r = _asignaciones[i];
                      final idSub = (r['idSubcategoria'] as num?)?.toInt();
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.label_important_outline),
                        title: Text(_fmt(r['subcategoria'])),
                        subtitle: Text(
                          'Categoría: ${_fmt(r['categoria'])}   •   Unión: ${_fmt(r['fechaUnion'])}',
                        ),
                        trailing: (idSub == null)
                            ? null
                            : IconButton(
                                tooltip: 'Eliminar asignación',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await _asig.eliminar(
                                      idEstudiante: widget.id,
                                      idSubcategoria: idSub,
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Asignación eliminada')),
                                    );
                                    await _loadAll();
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                              ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Diálogos inscripción ----------
  Future<void> _editarInscripcionDialog() async {
    if (_matricula == null) return;

    final formKey = GlobalKey<FormState>();
    int? idCategoria = (_matricula?['idCategoria'] ?? _matricula?['id_categoria']) as int?;
    final cicloCtl = TextEditingController(text: _matricula?['ciclo']?.toString() ?? '');
    DateTime? fechaSel;

    String? fechaStr = (_matricula?['fecha'] ?? _matricula?['fecha_matricula'])?.toString();
    if (fechaStr != null && fechaStr.isNotEmpty) {
      try { fechaSel = DateTime.parse(fechaStr); } catch (_) {}
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar inscripción'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: idCategoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categorias.map((c) {
                    final id = c['id_categoria'] ?? c['id'];
                    final nombre = c['nombre_categoria'] ?? c['nombre'] ?? '—';
                    return DropdownMenuItem<int>(
                      value: (id is int) ? id : int.tryParse('$id'),
                      child: Text('$nombre'),
                    );
                  }).toList(),
                  validator: (v) => (v == null) ? 'Seleccione una categoría' : null,
                  onChanged: (v) => idCategoria = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cicloCtl,
                  decoration: const InputDecoration(labelText: 'Ciclo'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Fecha:'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final initial = fechaSel ?? now;
                        final sel = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(now.year - 5, 1, 1),
                          lastDate: DateTime(now.year + 1, 12, 31),
                        );
                        if (sel != null) setState(() => fechaSel = sel);
                      },
                      child: Text(
                        (fechaSel != null)
                            ? '${fechaSel!.year}-${fechaSel!.month.toString().padLeft(2, '0')}-${fechaSel!.day.toString().padLeft(2, '0')}'
                            : (_fmtDate(fechaStr)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final fechaISO = (fechaSel != null)
        ? '${fechaSel!.year}-${fechaSel!.month.toString().padLeft(2, '0')}-${fechaSel!.day.toString().padLeft(2, '0')}'
        : null;

    try {
      await _updateMatriculaFlexible(
        idMatricula: (_matricula!['id_matricula'] ?? _matricula!['id']) as int,
        idCategoria: idCategoria,
        ciclo: cicloCtl.text.trim().isEmpty ? null : cicloCtl.text.trim(),
        fechaISO: fechaISO,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inscripción actualizada')));
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _crearInscripcionDialog() async {
    final formKey = GlobalKey<FormState>();
    int? idCategoria;
    final cicloCtl = TextEditingController();
    DateTime? fechaSel;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear inscripción'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: idCategoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categorias.map((c) {
                    final id = c['id_categoria'] ?? c['id'];
                    final nombre = c['nombre_categoria'] ?? c['nombre'] ?? '—';
                    return DropdownMenuItem<int>(
                      value: (id is int) ? id : int.tryParse('$id'),
                      child: Text('$nombre'),
                    );
                  }).toList(),
                  validator: (v) => (v == null) ? 'Seleccione una categoría' : null,
                  onChanged: (v) => idCategoria = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cicloCtl,
                  decoration: const InputDecoration(labelText: 'Ciclo'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Fecha:'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final sel = await showDatePicker(
                          context: context,
                          initialDate: fechaSel ?? now,
                          firstDate: DateTime(now.year - 5, 1, 1),
                          lastDate: DateTime(now.year + 1, 12, 31),
                        );
                        if (sel != null) setState(() => fechaSel = sel);
                      },
                      child: Text(
                        (fechaSel != null)
                            ? '${fechaSel!.year}-${fechaSel!.month.toString().padLeft(2, '0')}-${fechaSel!.day.toString().padLeft(2, '0')}'
                            : 'Seleccionar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final fechaISO = (fechaSel != null)
        ? '${fechaSel!.year}-${fechaSel!.month.toString().padLeft(2, '0')}-${fechaSel!.day.toString().padLeft(2, '0')}'
        : null;

    try {
      await _createMatriculaFlexible(
        idEstudiante: widget.id,
        idCategoria: idCategoria!,
        ciclo: cicloCtl.text.trim().isEmpty ? null : cicloCtl.text.trim(),
        fechaISO: fechaISO,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inscripción creada')));
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
