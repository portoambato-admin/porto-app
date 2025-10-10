import 'dart:convert';
// NOTE: si compilarás a iOS/Android nativos, elimina esta importación y
// usa únicamente el diálogo de "Copiar CSV". Para web funciona perfecto.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_scope.dart';
import '../../../core/constants/route_names.dart';

class AdminSubcategoriasScreen extends StatefulWidget {
  final bool embedded;
  final void Function(Map<String, dynamic> row)? onOpenEstudiantes;

  const AdminSubcategoriasScreen({
    super.key,
    this.embedded = false,
    this.onOpenEstudiantes,
  });

  @override
  State<AdminSubcategoriasScreen> createState() => _AdminSubcategoriasScreenState();
}

class _AdminSubcategoriasScreenState extends State<AdminSubcategoriasScreen>
    with SingleTickerProviderStateMixin {
  // Repos
  late dynamic _subRepo;
  late dynamic _catRepo;
  dynamic _alumnosRepo;

  // Estado
  late final TabController _tab;
  final _search = TextEditingController();
  int? _idCategoria;

  List<Map<String, dynamic>> _catOptions = [];
  Map<int, String> _catById = {};

  bool _loading = false;
  String? _error;

  // Paginación (totales para pestañas)
  int _actPage = 1, _actPageSize = 10, _actTotal = 0;
  int _inaPage = 1, _inaPageSize = 10, _inaTotal = 0;
  int _allPage = 1, _allPageSize = 10, _allTotal = 0;

  List<Map<String, dynamic>> _actItems = [];
  List<Map<String, dynamic>> _inaItems = [];
  List<Map<String, dynamic>> _allItems = [];

  // Edición en línea
  final Map<int, _RowEdit> _editing = {};

  bool _reposListos = false;
  bool _arrancado = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      _loadCurrent();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reposListos) {
      final scope = AppScope.of(context);
      _subRepo = scope.subcategorias;
      _catRepo = scope.categorias;
      try { _alumnosRepo = scope.estudiantes; } catch (_) {}
      _reposListos = true;
    }
    if (_reposListos && !_arrancado) {
      _arrancado = true;
      _init();
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    _editing.forEach((_, e) => e.dispose());
    super.dispose();
  }

  Future<void> _init() async {
    setState(() { _loading = true; _error = null; });
    try {
      _catOptions = List<Map<String, dynamic>>.from(await _catRepo.simpleList());
      _catById = {
        for (final c in _catOptions)
          (c['id'] as num).toInt() : (c['nombre']?.toString() ?? '')
      };
      await _loadCurrent();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _loadCurrent() async {
    switch (_tab.index) {
      case 0: return _loadActivas();
      case 1: return _loadInactivas();
      case 2: return _loadTodas();
    }
  }

  Future<void> _loadActivas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _subRepo.paged(
        page: _actPage,
        pageSize: _actPageSize,
        q: _q,
        idCategoria: _idCategoria,
        onlyActive: true,
        sort: 'nombre_subcategoria',
        order: 'asc',
      );
      setState(() {
        _actItems = List<Map<String, dynamic>>.from(res['items']);
        _actTotal = (res['total'] as num).toInt();
      });
    } catch (e) { setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _loadInactivas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _subRepo.paged(
        page: _inaPage,
        pageSize: _inaPageSize,
        q: _q,
        idCategoria: _idCategoria,
        onlyActive: false,
        sort: 'nombre_subcategoria',
        order: 'asc',
      );
      setState(() {
        _inaItems = List<Map<String, dynamic>>.from(res['items']);
        _inaTotal = (res['total'] as num).toInt();
      });
    } catch (e) { setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _loadTodas() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _subRepo.paged(
        page: _allPage,
        pageSize: _allPageSize,
        q: _q,
        idCategoria: _idCategoria,
        onlyActive: null,
        sort: 'nombre_subcategoria',
        order: 'asc',
      );
      setState(() {
        _allItems = List<Map<String, dynamic>>.from(res['items']);
        _allTotal = (res['total'] as num).toInt();
      });
    } catch (e) { setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  String? get _q {
    final s = _search.text.trim();
    return s.isEmpty ? null : s;
  }

  // ----- Categoría: resolver nombre coherente -----
  String _catNameOf(Map<String, dynamic> r) {
    final c = r['categoria'];
    if (c is String && c.trim().isNotEmpty) return c;
    if (c is Map) {
      final n = (c['nombre'] ?? c['name'] ?? c['title'])?.toString();
      if (n != null && n.trim().isNotEmpty) return n;
      final idFromObj = c['id'] ?? c['idCategoria'] ?? c['categoriaId'];
      if (idFromObj is num) return _catById[idFromObj.toInt()] ?? '—';
    }
    final id = r['idCategoria'] ?? r['id_categoria'] ?? r['categoriaId'];
    if (id is num) return _catById[id.toInt()] ?? '—';
    return '—';
  }

  // ====== Acciones ======
  Future<void> _onNew() async {
    final ok = await _openForm();
    if (ok == true) await _loadCurrent();
  }

  Future<void> _onEditDialog(Map<String, dynamic> row) async {
    final ok = await _openForm(row: row);
    if (ok == true) await _loadCurrent();
  }

  void _startInlineEdit(Map<String, dynamic> r) {
    final id = (r['id'] as num).toInt();
    if (_editing.containsKey(id)) return;
    _editing[id] = _RowEdit(
      TextEditingController(text: r['nombre']?.toString() ?? ''),
      TextEditingController(text: r['codigo']?.toString() ?? ''),
    );
    setState(() {});
  }

  void _cancelInlineEdit(int id) {
    _editing.remove(id)?.dispose();
    setState(() {});
  }

  Future<void> _saveInlineEdit(int id, Map<String, dynamic> r) async {
    final edit = _editing[id]; if (edit == null) return;
    final nuevoNombre = edit.nombre.text.trim();
    final nuevoCodigo = edit.codigo.text.trim();
    if (nuevoNombre.isEmpty || nuevoCodigo.isEmpty) {
      _showSnack('Nombre y código son requeridos');
      return;
    }
    try {
      await _subRepo.update(
        idSubcategoria: id,
        nombre: nuevoNombre,
        codigo: nuevoCodigo,
      );
      _showSnack('Guardado');
      _editing.remove(id)?.dispose();
      await _loadCurrent();
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _onToggle(Map<String, dynamic> row) async {
    final bool actual = row['activo'] == true;
    setState(() => _loading = true);
    try {
      await _subRepo.update(idSubcategoria: (row['id'] as num).toInt(), activo: !actual);
      _showSnack('Actualizado');
      await _loadCurrent();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onDelete(Map<String, dynamic> row) async {
    final id = (row['id'] as num).toInt();
    final ok = await _confirm('¿Eliminar subcategoría ${row['nombre']}?');
    if (ok != true) return;
    setState(() => _loading = true);
    try {
      await _subRepo.remove(id);
      _showSnack('Eliminada');
      await _loadCurrent();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _openForm({Map<String, dynamic>? row}) async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: row?['nombre']?.toString() ?? '');
    final codigo = TextEditingController(text: row?['codigo']?.toString() ?? '');
    int? idCat = row?['idCategoria'] is num
        ? (row?['idCategoria'] as num).toInt()
        : row?['idCategoria'] as int?;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(row == null ? 'Nueva subcategoría' : 'Editar subcategoría'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: idCat,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _catOptions.map((e) {
                      return DropdownMenuItem<int>(
                        value: (e['id'] as num).toInt(),
                        child: Text(e['nombre']?.toString() ?? '—'),
                      );
                    }).toList(),
                    validator: (v) => v == null ? 'Selecciona categoría' : null,
                    onChanged: (v) => idCat = v,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de subcategoría',
                      prefixIcon: Icon(Icons.label),
                    ),
                    maxLength: 60,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Requerido';
                      if (s.length < 3) return 'Muy corto';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: codigo,
                    decoration: const InputDecoration(
                      labelText: 'Código único',
                      prefixIcon: Icon(Icons.qr_code),
                      helperText: 'Identificador único (ej. SUB12A).',
                    ),
                    maxLength: 32,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  if (row == null) {
                    await _subRepo.crear(
                      idCategoria: idCat!,
                      nombre: nombre.text.trim(),
                      codigo: codigo.text.trim(),
                    );
                  } else {
                    await _subRepo.update(
                      idSubcategoria: (row['id'] as num).toInt(),
                      idCategoria: idCat,
                      nombre: nombre.text.trim(),
                      codigo: codigo.text.trim(),
                    );
                  }
                  if (mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  _showSnack('Error: $e');
                }
              },
              child: Text(row == null ? 'Crear' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  // ===== Exportar CSV =====
  void _exportCsvCurrent() {
    final tab = _tab.index;
    final data = tab == 0 ? _actItems : (tab == 1 ? _inaItems : _allItems);
    final name = tab == 0 ? 'subcategorias_activas' : (tab == 1 ? 'subcategorias_inactivas' : 'subcategorias_todas');

    final csv = StringBuffer()..writeln('ID,Subcategoria,Codigo,Categoria,Activo,Creado');
    for (final r in data) {
      final id = r['id'] ?? '';
      final nom = _csvEscape(r['nombre']);
      final cod = _csvEscape(r['codigo']);
      final cat = _csvEscape(_catNameOf(r));
      final act = (r['activo'] == true) ? '1' : '0';
      final cre = r['creadoEn']?.toString().split('T').first ?? '';
      csv.writeln('$id,$nom,$cod,$cat,$act,$cre');
    }
    final content = csv.toString();

    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final a = html.AnchorElement(href: url)..download = '$name.csv';
      a.click();
      html.Url.revokeObjectUrl(url);
    } else {
      _showCsvDialog(content, '$name.csv');
    }
  }

  static String _csvEscape(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  Future<void> _showCsvDialog(String data, String filename) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('CSV: $filename'),
        content: SizedBox(width: 600, height: 360, child: SelectableText(data)),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: data));
              if (mounted) Navigator.pop(context);
              _showSnack('Copiado al portapapeles');
            },
            child: const Text('Copiar'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ===== Asignación masiva =====
  Future<void> _openBulkAssignDialog(Map<String, dynamic> row) async {
    final idSub = (row['id'] as num).toInt();
    final nombreSub = row['nombre']?.toString() ?? '';
    final ctrl = TextEditingController();
    String? helpError;
    bool busy = false;

    Future<void> doAssign() async {
      final ids = _parseIds(ctrl.text);
      if (ids.isEmpty) {
        helpError = 'Ingresa al menos un ID numérico (separados por coma, espacio o nueva línea).';
        (context as Element).markNeedsBuild();
        return;
      }
      setState(() => _loading = true);
      try {
        if (_alumnosRepo != null) {
          await _alumnosRepo.asignarASubcategoria(ids: ids, idSubcategoria: idSub);
        } else if (_subRepo.asignarEstudiantesMasivo != null) {
          await _subRepo.asignarEstudiantesMasivo(idSubcategoria: idSub, ids: ids);
        } else {
          throw 'No se encontró método para asignación masiva en AppScope.estudiantes o subcategorias.';
        }
        _showSnack('Asignados ${ids.length} estudiante(s) a "$nombreSub"');
        Navigator.pop(context);
      } catch (e) {
        helpError = 'Error: $e';
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: !busy,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future<void> onAssign() async {
            if (busy) return;
            setLocal(() => busy = true);
            await doAssign();
            setLocal(() => busy = false);
          }

          return AlertDialog(
            title: Text('Asignación masiva → $nombreSub'),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    minLines: 6,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: 'IDs de estudiantes',
                      helperText: 'Pega IDs (números) separados por comas, espacios o saltos de línea.',
                      errorText: helpError,
                      prefixIcon: const Icon(Icons.paste),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\s]+'))],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ejemplo: 12, 45, 98 · o bien: 12 45 98 · o en líneas: 12\\n45\\n98',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton.icon(
                onPressed: busy ? null : onAssign,
                icon: const Icon(Icons.group_add),
                label: busy ? const Text('Asignando...') : const Text('Asignar'),
              ),
            ],
          );
        },
      ),
    );
  }

  static List<int> _parseIds(String raw) {
    final matches = RegExp(r'\d+').allMatches(raw);
    final ids = <int>{};
    for (final m in matches) {
      final v = int.tryParse(m.group(0)!);
      if (v != null) ids.add(v);
    }
    return ids.toList()..sort();
  }

  // ===== Helpers UI =====
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool?> _confirm(String msg) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = _ResponsiveContent(
      tab: _tab,
      search: _search,
      idCategoria: _idCategoria,
      catOptions: _catOptions,
      loading: _loading,
      error: _error,
      actItems: _actItems, inaItems: _inaItems, allItems: _allItems,
      actTotal: _actTotal, inaTotal: _inaTotal, allTotal: _allTotal,
      onSearch: _loadCurrent,
      onNew: _onNew,
      onEditDialog: _onEditDialog,
      onInlineStart: _startInlineEdit,
      onInlineCancel: _cancelInlineEdit,
      onInlineSave: _saveInlineEdit,
      onToggle: _onToggle,
      onDelete: _onDelete,
      onCatChanged: (v) { setState(() => _idCategoria = v); _loadCurrent(); },
      onOpenEstudiantes: (row) {
        if (widget.embedded && widget.onOpenEstudiantes != null) {
          widget.onOpenEstudiantes!(row);
          return;
        }
        Navigator.pushNamed(
          context,
          RouteNames.adminSubcatEstudiantes,
          arguments: {
            'idSubcategoria': (row['id'] as num).toInt(),
            'nombreSubcategoria': row['nombre'],
            'idCategoria': row['idCategoria'],
          },
        );
      },
      onExportCsv: _exportCsvCurrent,
      editing: _editing,
      onBulkAssign: _openBulkAssignDialog,
      catNameOf: _catNameOf,
    );

    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subcategorías')),
        body: Padding(padding: const EdgeInsets.all(12), child: core),
      );
    }
    return Padding(padding: const EdgeInsets.all(12), child: core);
  }
}

// ====================== UI/LAYOUT RESPONSIVO ======================

class _ResponsiveContent extends StatelessWidget {
  const _ResponsiveContent({
    required this.tab,
    required this.search,
    required this.idCategoria,
    required this.catOptions,
    required this.loading,
    required this.error,
    required this.actItems,
    required this.inaItems,
    required this.allItems,
    required this.actTotal,
    required this.inaTotal,
    required this.allTotal,
    required this.onSearch,
    required this.onNew,
    required this.onEditDialog,
    required this.onInlineStart,
    required this.onInlineCancel,
    required this.onInlineSave,
    required this.onToggle,
    required this.onDelete,
    required this.onCatChanged,
    required this.onOpenEstudiantes,
    required this.onExportCsv,
    required this.editing,
    required this.onBulkAssign,
    required this.catNameOf,
  });

  final TabController tab;
  final TextEditingController search;
  final int? idCategoria;
  final List<Map<String, dynamic>> catOptions;

  final bool loading;
  final String? error;

  final List<Map<String, dynamic>> actItems;
  final List<Map<String, dynamic>> inaItems;
  final List<Map<String, dynamic>> allItems;

  final int actTotal, inaTotal, allTotal;

  final VoidCallback onSearch;
  final VoidCallback onNew;
  final void Function(Map<String, dynamic>) onEditDialog;
  final void Function(Map<String, dynamic>) onInlineStart;
  final void Function(int) onInlineCancel;
  final void Function(int, Map<String, dynamic>) onInlineSave;
  final void Function(Map<String, dynamic>) onToggle;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(int?) onCatChanged;
  final void Function(Map<String, dynamic>) onOpenEstudiantes;
  final VoidCallback onExportCsv;
  final Map<int, _RowEdit> editing;
  final Future<void> Function(Map<String, dynamic>) onBulkAssign;

  final String Function(Map<String, dynamic>) catNameOf;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final isNarrow = c.maxWidth < 720;

        // ✨ Centrado y ancho máximo en web ancha
        const double maxContentWidth = 1200;
        final double width = c.maxWidth > maxContentWidth ? maxContentWidth : c.maxWidth;

        final header = _buildHeader(context, isNarrow);
        final tabs = TabBar(
          controller: tab,
          isScrollable: isNarrow, // por si el padding fuese muy justo
          tabs: [
            Tab(text: 'Activas ($actTotal)'),
            Tab(text: 'Inactivas ($inaTotal)'),
            Tab(text: 'Todas ($allTotal)'),
          ],
        );

        final content = loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : TabBarView(
                    controller: tab,
                    children: [
                      _buildBody(context, isNarrow, actItems),
                      _buildBody(context, isNarrow, inaItems),
                      _buildBody(context, isNarrow, allItems),
                    ],
                  );

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 12),
                tabs,
                const SizedBox(height: 8),
                Expanded(child: content),
              ],
            ),
          ),
        );
      },
    );
  }

  // Header responsive (FIX: sin Expanded dentro de Column en modo angosto)
  Widget _buildHeader(BuildContext context, bool isNarrow) {
    final searchField = TextField(
      controller: search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o código...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Limpiar',
          icon: const Icon(Icons.clear),
          onPressed: () { search.clear(); onSearch(); },
        ),
      ),
      onSubmitted: (_) => onSearch(),
    );

    final searchWide = Expanded(child: searchField);
    final searchNarrow = SizedBox(width: double.infinity, child: searchField);

    final cat = SizedBox(
      width: isNarrow ? double.infinity : 260,
      child: DropdownButtonFormField<int?>(
        value: idCategoria,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.category), labelText: 'Categoría'),
        items: <DropdownMenuItem<int?>>[
          const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
          ...catOptions.map((e) => DropdownMenuItem<int?>(
                value: (e['id'] as num).toInt(),
                child: Text(e['nombre']?.toString() ?? '—'),
              )),
        ],
        onChanged: onCatChanged,
      ),
    );

    final exportBtn = OutlinedButton.icon(
      onPressed: onExportCsv,
      icon: const Icon(Icons.download),
      label: const Text('Exportar'),
    );

    final add = FilledButton.icon(
      onPressed: onNew,
      icon: const Icon(Icons.add),
      label: const Text('Nueva'),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchNarrow,
          const SizedBox(height: 8),
          cat,
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [exportBtn, const SizedBox(width: 8), add]),
        ],
      );
    }
    return Row(children: [searchWide, const SizedBox(width: 8), cat, const Spacer(), exportBtn, const SizedBox(width: 8), add]);
  }

  // Decide tabla (wide) o tarjetas (narrow)
  Widget _buildBody(BuildContext context, bool isNarrow, List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return const Center(child: Text('Sin datos'));
    return isNarrow ? _cards(context, rows) : _table(context, rows);
  }

  // Tabla (desktop)
  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Subcategoría')),
          DataColumn(label: Text('Código')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Creado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: rows.map((r) {
          final id = (r['id'] as num).toInt();
          final bool activo = r['activo'] == true;
          final edit = editing[id];

          final nombreCell = edit == null
              ? Text(r['nombre']?.toString() ?? '')
              : SizedBox(width: 220, child: TextField(controller: edit.nombre, decoration: const InputDecoration(isDense: true)));

          final codigoCell = edit == null
              ? Text(r['codigo']?.toString() ?? '')
              : SizedBox(width: 160, child: TextField(controller: edit.codigo, decoration: const InputDecoration(isDense: true)));

          return DataRow(cells: [
            DataCell(Text('$id')),
            DataCell(nombreCell),
            DataCell(codigoCell),
            DataCell(Text(catNameOf(r))),
            DataCell(Icon(activo ? Icons.check_circle : Icons.cancel)),
            DataCell(Text(r['creadoEn']?.toString().split('T').first ?? '')),
            DataCell(_rowActions(r, isEditing: edit != null, activo: activo)),
          ]);
        }).toList(),
      ),
    );
  }

  // Tarjetas (móvil)
  Widget _cards(BuildContext context, List<Map<String, dynamic>> rows) {
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final r = rows[i];
        final id = (r['id'] as num).toInt();
        final bool activo = r['activo'] == true;
        final edit = editing[id];

        final nombre = edit == null
            ? Text(r['nombre']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium)
            : TextField(controller: edit.nombre, decoration: const InputDecoration(labelText: 'Nombre'));

        final codigo = edit == null
            ? Text('Código: ${r['codigo'] ?? ''}')
            : TextField(controller: edit.codigo, decoration: const InputDecoration(labelText: 'Código'));

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: nombre),
                    const SizedBox(width: 8),
                    Icon(activo ? Icons.check_circle : Icons.cancel, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                codigo,
                const SizedBox(height: 4),
                Text('Categoría: ${catNameOf(r)}'),
                const SizedBox(height: 4),
                Text('Creado: ${r['creadoEn']?.toString().split('T').first ?? ''}'),
                const SizedBox(height: 8),
                _rowActions(r, isEditing: edit != null, activo: activo, dense: true),
              ],
            ),
          ),
        );
      },
    );
  }

  // Botonera por fila (común)
  Widget _rowActions(
    Map<String, dynamic> r, {
    required bool isEditing,
    required bool activo,
    bool dense = false,
  }) {
    final id = (r['id'] as num).toInt();

    if (isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(tooltip: 'Guardar', icon: const Icon(Icons.check), onPressed: () => onInlineSave(id, r)),
          IconButton(tooltip: 'Cancelar', icon: const Icon(Icons.close), onPressed: () => onInlineCancel(id)),
        ],
      );
    }

    return Wrap(
      spacing: dense ? 4 : 8,
      children: [
        IconButton(tooltip: 'Estudiantes', icon: const Icon(Icons.people), onPressed: () => onOpenEstudiantes(r)),
        IconButton(tooltip: 'Asignación masiva', icon: const Icon(Icons.group_add), onPressed: () => onBulkAssign(r)),
        IconButton(tooltip: 'Editar en línea', icon: const Icon(Icons.edit), onPressed: () => onInlineStart(r)),
        IconButton(tooltip: activo ? 'Desactivar' : 'Activar', icon: Icon(activo ? Icons.visibility_off : Icons.visibility), onPressed: () => onToggle(r)),
        IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_forever), onPressed: () => onDelete(r)),
        IconButton(tooltip: 'Editar (diálogo)', icon: const Icon(Icons.border_color), onPressed: () => onEditDialog(r)),
      ],
    );
  }
}

// ===== Modelitos UI =====
class _RowEdit {
  final TextEditingController nombre;
  final TextEditingController codigo;
  _RowEdit(this.nombre, this.codigo);
  void dispose() { nombre.dispose(); codigo.dispose(); }
}
