import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_scope.dart';

// ===== Helpers UI (solo front) =====
String _iniciales(String nombres, String apellidos) {
  final n = nombres.trim().isEmpty ? '' : nombres.trim().split(' ').first;
  final a = apellidos.trim().isEmpty ? '' : apellidos.trim().split(' ').first;
  final i1 = n.isEmpty ? '' : n.characters.first;
  final i2 = a.isEmpty ? '' : a.characters.first;
  final r = (i1 + i2).toUpperCase();
  return r.isEmpty ? '👤' : r;
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v');
}

Color _avatarColor(String seed){
  final h = seed.hashCode & 0xFFFFFF;
  return Color(0xFF000000 | h).withOpacity(1);
}

enum ViewMode { cards, table }
enum SortBy { apellidoAZ, apellidoZA, nombreAZ, reciente }

class SubcategoriaEstudiantesScreen extends StatefulWidget {
  final int idSubcategoria;
  final String nombreSubcategoria;
  final int? idCategoria; // para matrícula

  const SubcategoriaEstudiantesScreen({
    super.key,
    required this.idSubcategoria,
    required this.nombreSubcategoria,
    this.idCategoria,
  });

  @override
  State<SubcategoriaEstudiantesScreen> createState() => _SubcategoriaEstudiantesScreenState();
}

class _SubcategoriaEstudiantesScreenState extends State<SubcategoriaEstudiantesScreen> {
  // Repos existentes
  late final _subcatEst = AppScope.of(context).subcatEst;
  late final _est = AppScope.of(context).estudiantes;
  late final _mat = AppScope.of(context).matriculas;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  // UI/UX solo front
  final _qCtrl = TextEditingController();
  bool _soloActivos = true;
  ViewMode _view = ViewMode.cards;
  SortBy _sort = SortBy.apellidoAZ;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final asign = await _subcatEst.porSubcategoria(widget.idSubcategoria);

      final list = <Map<String, dynamic>>[];
      for (final a in asign) {
        final idEst = _toIntOrNull(a['idEstudiante'] ?? a['id'] ?? a['id_estudiante']);
        if (idEst == null) continue;

        String? nombres = a['nombres']?.toString();
        String? apellidos = a['apellidos']?.toString();

        if ((nombres == null || apellidos == null) && a['estudiante'] != null) {
          final s = a['estudiante'].toString().trim();
          final parts = s.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            nombres = parts.sublist(0, parts.length - 1).join(' ');
            apellidos = parts.last;
          } else {
            nombres = s; apellidos = '';
          }
        }

        if (nombres == null || apellidos == null) {
          try {
            final info = await _est.byId(idEst);
            nombres = info?['nombres']?.toString() ?? nombres ?? '—';
            apellidos = info?['apellidos']?.toString() ?? apellidos ?? '';
          } catch (_) {}
        }

        list.add({
          'id': idEst,
          'nombres': nombres ?? '—',
          'apellidos': apellidos ?? '',
          'activo': (a['activo'] is bool) ? a['activo'] : true,
        });
      }

      setState(() {
        _rows = list;
        _selected.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _sortRows(List<Map<String,dynamic>> list) {
    final r = [...list];
    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    switch (_sort) {
      case SortBy.apellidoAZ: r.sort((a,b)=>cmp('${a['apellidos']}','${b['apellidos']}')); break;
      case SortBy.apellidoZA: r.sort((a,b)=>cmp('${b['apellidos']}','${a['apellidos']}')); break;
      case SortBy.nombreAZ:   r.sort((a,b)=>cmp('${a['nombres']}','${b['nombres']}')); break;
      case SortBy.reciente:   r.sort((a,b)=>((b['id']??0) as int).compareTo((a['id']??0) as int)); break;
    }
    return r;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _qCtrl.text.trim().toLowerCase();
    final base = _rows.where((r) {
      if (_soloActivos && r['activo'] == false) return false;
      if (q.isEmpty) return true;
      final n = (r['nombres'] ?? '').toString().toLowerCase();
      final a = (r['apellidos'] ?? '').toString().toLowerCase();
      return n.contains(q) || a.contains(q) || ('$n $a').contains(q);
    }).toList();
    return _sortRows(base);
  }

  // ====== KPIs ======
  Widget _kpiChips() {
    final total = _rows.length;
    final activos = _rows.where((e) => e['activo'] == true).length;
    final inactivos = total - activos;
    Chip _c(IconData i, String t, String v) => Chip(
      avatar: Icon(i, size: 18),
      label: Text('$t: $v'),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        _c(Icons.people, 'Total', '$total'),
        _c(Icons.verified_user, 'Activos', '$activos'),
        _c(Icons.person_off, 'Inactivos', '$inactivos'),
      ],
    );
  }

  // ===== Export CSV (copiar al portapapeles) =====
  String _csv(List<Map<String,dynamic>> rows){
    const cols = ['id','nombres','apellidos','activo'];
    String esc(v){ final s='${v??''}'; return '"${s.replaceAll('"','""')}"'; }
    final header = cols.map(esc).join(',');
    final lines = rows.map((r)=>cols.map((c)=>esc(r[c])).join(','));
    return ([header, ...lines]).join('\n');
  }

  Future<void> _exportCsvSelected() async {
    final rows = _rows.where((r)=>_selected.contains(r['id'])).toList();
    final content = _csv(rows.isEmpty ? _filtered : rows);
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copiado al portapapeles')),
    );
  }

  void _printList() {
    showDialog(context: context, builder: (_)=>AlertDialog(
      title: const Text('Impresión'),
      content: const Text('Vista de impresión en desarrollo (solo UI).'),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cerrar'))],
    ));
  }

  // ====== UI ======
  String _letterOf(Map r) {
    final base = (r['apellidos'] ?? r['nombres'] ?? '').toString().trim();
    return base.isEmpty ? '#' : base[0].toUpperCase();
  }

  Widget _skeleton() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.black12.withOpacity(.06),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  Future<void> _inscribir() async {
    // Misma lógica que tenías, UI mejorada
    final formKey = GlobalKey<FormState>();
    final nombres = TextEditingController();
    final apellidos = TextEditingController();
    final telefono = TextEditingController();
    final direccion = TextEditingController();
    final fecha = TextEditingController(); // YYYY-MM-DD (opcional)
    int idAcademia = 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person_add)),
                    title: Text('Inscribir en ${widget.nombreSubcategoria}'),
                    subtitle: const Text('Completa los datos obligatorios'),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: nombres,
                          decoration: const InputDecoration(
                            labelText: 'Nombres',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (v) => (v==null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: apellidos,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos',
                            prefixIcon: Icon(Icons.assignment_ind),
                          ),
                          validator: (v) => (v==null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: telefono,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono (opcional)',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: fecha,
                          decoration: const InputDecoration(
                            labelText: 'Fecha nac. YYYY-MM-DD (opcional)',
                            prefixIcon: Icon(Icons.cake),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: direccion,
                    decoration: const InputDecoration(
                      labelText: 'Dirección (opcional)',
                      prefixIcon: Icon(Icons.home),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: '1',
                    decoration: const InputDecoration(
                      labelText: 'ID Academia',
                      prefixIcon: Icon(Icons.school),
                    ),
                    onChanged: (v) => idAcademia = int.tryParse(v) ?? 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          try {
                            final nuevo = await _est.crear(
                              nombres: nombres.text.trim(),
                              apellidos: apellidos.text.trim(),
                              telefono: telefono.text.trim().isEmpty ? null : telefono.text.trim(),
                              direccion: direccion.text.trim().isEmpty ? null : direccion.text.trim(),
                              fechaNacimiento: fecha.text.trim().isEmpty ? null : fecha.text.trim(),
                              idAcademia: idAcademia,
                            );
                            final idEst = _toIntOrNull(nuevo['id'] ?? nuevo['id_estudiante']);
                            if (idEst == null) throw Exception('No se pudo obtener el ID del estudiante');

                            if (widget.idCategoria != null) {
                              await _mat.crear(
                                idEstudiante: idEst,
                                idCategoria: widget.idCategoria!,
                                ciclo: null,
                              );
                            }

                            await _subcatEst.asignar(
                              idEstudiante: idEst,
                              idSubcategoria: widget.idSubcategoria,
                            );

                            if (mounted) {
                              Navigator.pop(context, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Estudiante inscrito')),
                              );
                              _load();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Inscribir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true) _load();
  }

  PreferredSizeWidget _selectionBar(BuildContext ctx) => AppBar(
    leading: IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => setState(() => _selected.clear()),
      tooltip: 'Limpiar selección',
    ),
    title: Text('${_selected.length} seleccionado(s)'),
    actions: [
      IconButton(icon: const Icon(Icons.download), onPressed: _selected.isEmpty ? null : _exportCsvSelected, tooltip: 'Exportar CSV'),
      IconButton(icon: const Icon(Icons.print), onPressed: _selected.isEmpty ? null : _printList, tooltip: 'Imprimir'),
    ],
  );

  // FAB abre menú contextual
  Future<void> _showFabMenu() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final size = overlay.size;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        size.width - 80, // izquierda
        size.height - 100, // arriba
        16, // derecha
        80, // abajo
      ),
      items: const [
        PopupMenuItem(
          value: 'inscribir',
          child: ListTile(leading: Icon(Icons.person_add), title: Text('Inscribir')),
        ),
        PopupMenuItem(
          value: 'export',
          child: ListTile(leading: Icon(Icons.download), title: Text('Exportar CSV (copiar)')),
        ),
      ],
    );
    if (selected == 'inscribir') _inscribir();
    if (selected == 'export') _exportCsvSelected();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final header = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.colorScheme.primaryContainer, t.colorScheme.surface],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: t.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Text(widget.nombreSubcategoria.characters.take(2).toString().toUpperCase()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.nombreSubcategoria,
                      style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _kpiChips(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o apellido…',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: _qCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () { _qCtrl.clear(); setState(() {}); },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<ViewMode>(
                    segments: const [
                      ButtonSegment(value: ViewMode.cards, icon: Icon(Icons.view_agenda), label: Text('Tarjetas')),
                    ButtonSegment(value: ViewMode.table, icon: Icon(Icons.table_rows), label: Text('Tabla')),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s)=>setState(()=>_view=s.first),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<SortBy>(
                    value: _sort,
                    onChanged: (v){ if (v!=null) setState(()=>_sort=v); },
                    items: const [
                      DropdownMenuItem(value: SortBy.apellidoAZ, child: Text('Apellido A→Z')),
                      DropdownMenuItem(value: SortBy.apellidoZA, child: Text('Apellido Z→A')),
                      DropdownMenuItem(value: SortBy.nombreAZ,   child: Text('Nombre A→Z')),
                      DropdownMenuItem(value: SortBy.reciente,   child: Text('Más recientes')),
                    ],
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('Solo activos'),
                    selected: _soloActivos,
                    onSelected: (v) => setState(() => _soloActivos = v),
                  ),
                  IconButton(
                    tooltip: 'Recargar',
                    onPressed: _loading ? null : _load,
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // ====== Cuerpo ======
    Widget buildCards() {
      if (_loading) return _skeleton();
      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 8),
                    Text('Ocurrió un error', style: t.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      final data = _filtered;
      if (data.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_outlined, size: 48),
                    const SizedBox(height: 8),
                    const Text('Sin estudiantes en esta subcategoría'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _inscribir,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Inscribir estudiante'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Agrupar por inicial
      String? current;
      final widgets = <Widget>[];
      for (final r in data) {
        final l = _letterOf(r);
        if (l != current) {
          current = l;
          widgets.add(Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
            child: Text(l, style: const TextStyle(fontWeight: FontWeight.w700)),
          ));
        }

        final id = _toIntOrNull(r['id']) ?? 0;
        final nombres = (r['nombres'] ?? '').toString();
        final apellidos = (r['apellidos'] ?? '').toString();
        final activo = (r['activo'] == true);

        widgets.add(
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              leading: SizedBox(
                width: 72,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _selected.contains(id),
                      onChanged: (v){
                        setState(()=> v==true ? _selected.add(id) : _selected.remove(id));
                      },
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      backgroundColor: _avatarColor('$nombres $apellidos'),
                      child: Text(_iniciales(nombres, apellidos)),
                    ),
                  ],
                ),
              ),
              title: Text('$nombres $apellidos'),
              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ID: $id'),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(activo ? 'Activo' : 'Inactivo'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Acciones',
                onSelected: (v) {
                  if (v == 'detalle') {
                    Navigator.pushNamed(
                      context,
                      '/admin/estudiantes/detalle',
                      arguments: {'id': id},
                    );
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'detalle',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Ver detalle'),
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.more_vert),
                ),
              ),
              onTap: () => Navigator.pushNamed(
                context,
                '/admin/estudiantes/detalle',
                arguments: {'id': id},
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
          children: widgets,
        ),
      );
    }

    Widget buildTable() {
      if (_loading) return _skeleton();
      if (_error != null) {
        return Center(child: Text(_error!));
      }
      final data = _filtered;
      if (data.isEmpty) {
        return const Center(child: Text('Sin estudiantes.'));
      }

      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Sel')),
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Estudiante')),
              DataColumn(label: Text('Estado')),
            ],
            rows: [
              for (final r in data)
                DataRow(
                  cells: [
                    DataCell(Checkbox(
                      value: _selected.contains(r['id']),
                      onChanged: (v){
                        setState(()=> v==true ? _selected.add(r['id'] as int) : _selected.remove(r['id']));
                      },
                    )),
                    DataCell(Text('${r['id']}')),
                    DataCell(Text('${r['nombres']} ${r['apellidos']}')),
                    DataCell(Text(r['activo']==true ? 'Activo' : 'Inactivo')),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _selected.isEmpty
          ? AppBar(
              title: Text(widget.nombreSubcategoria),
              actions: [
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Chip(
                      avatar: const Icon(Icons.group, size: 18),
                      label: Text('${_filtered.length}'),
                    ),
                  ),
              ],
            )
          : _selectionBar(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFabMenu,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          header,
          Expanded(
            child: _view == ViewMode.cards ? buildCards() : buildTable(),
          ),
        ],
      ),
    );
  }
}
