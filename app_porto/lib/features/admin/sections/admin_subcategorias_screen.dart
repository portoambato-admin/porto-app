// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async'; // Debouncer
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as xls;

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

// ==== Intents (Ctrl+F / Ctrl+N / Ctrl+R) ====
class FocusSearchIntent extends Intent { const FocusSearchIntent(); }
class NewSubcatIntent extends Intent { const NewSubcatIntent(); }
class ReloadIntent extends Intent { const ReloadIntent(); }

enum _ViewMode { table, cards }

class _AdminSubcategoriasScreenState extends State<AdminSubcategoriasScreen>
    with SingleTickerProviderStateMixin {
  // Repos
  late dynamic _subRepo;
  late dynamic _catRepo;
  dynamic _alumnosRepo;

  // Estado
  late final TabController _tab;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  int? _idCategoria;

  List<Map<String, dynamic>> _catOptions = [];
  Map<int, String> _catById = {};

  bool _loading = false;
  String? _error;

  // Paginación
  int _actPage = 1, _actPageSize = 10, _actTotal = 0;
  int _inaPage = 1, _inaPageSize = 10, _inaTotal = 0;
  int _allPage = 1, _allPageSize = 10, _allTotal = 0;

  List<Map<String, dynamic>> _actItems = [];
  List<Map<String, dynamic>> _inaItems = [];
  List<Map<String, dynamic>> _allItems = [];

  bool _reposListos = false;

  // Preferencias visuales
  _ViewMode _viewMode = _ViewMode.table;
  bool _dense = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      if (_itemsForTab(_tab.index).isEmpty) _loadCurrent();
    });
    _search.addListener(_onSearchChanged);
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
      _init();
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.removeListener(_onSearchChanged);
    _searchDebounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===== Debouncer búsqueda =====
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _resetPages();
      _loadCurrent();
    });
  }

  void _resetPages() {
    _actPage = 1; _inaPage = 1; _allPage = 1;
  }

  Future<void> _init() async {
    setState(() { _error = null; });
    try {
      _catOptions = List<Map<String, dynamic>>.from(await _catRepo.simpleList());
      _catById = {
        for (final c in _catOptions)
          (c['id'] as num).toInt(): (c['nombre']?.toString() ?? '')
      };
      await _loadData(_tab.index);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    }
  }

  Future<void> _loadCurrent() async {
    if (_loading) return;
    await _loadData(_tab.index);
  }

  // ===== Orden natural: "Sub-4" < "Sub-10" (por nombre o código) =====
  int? _firstNum(String? s) {
    if (s == null) return null;
    final m = RegExp(r'(\d+)').firstMatch(s);
    return (m == null) ? null : int.tryParse(m.group(1)!);
  }

  int _compareSub(Map a, Map b) {
    final sa = a['nombre']?.toString();
    final sb = b['nombre']?.toString();
    final ca = a['codigo']?.toString();
    final cb = b['codigo']?.toString();

    final na = _firstNum(sa) ?? _firstNum(ca);
    final nb = _firstNum(sb) ?? _firstNum(cb);

    if (na != null && nb != null) return na.compareTo(nb);
    if (na != null) return -1;
    if (nb != null) return 1;

    final aa = (sa ?? ca ?? '').toLowerCase();
    final bb = (sb ?? cb ?? '').toLowerCase();
    return aa.compareTo(bb);
  }

  Future<void> _loadData(int tabIndex) async {
    setState(() { _loading = true; _error = null; });

    bool? onlyActive;
    int page, pageSize;
    switch (tabIndex) {
      case 1: onlyActive = false; page = _inaPage; pageSize = _inaPageSize; break;
      case 2: onlyActive = null;  page = _allPage; pageSize = _allPageSize; break;
      case 0:
      default: onlyActive = true; page = _actPage; pageSize = _actPageSize; break;
    }

    try {
      final res = await _subRepo.paged(
        page: page,
        pageSize: pageSize,
        q: _q,
        idCategoria: _idCategoria,
        onlyActive: onlyActive,
        sort: 'nombre_subcategoria', // backend; aquí reforzamos orden natural
        order: 'asc',
      );

      final items = List<Map<String, dynamic>>.from(res['items'])..sort(_compareSub);
      final total = (res['total'] as num).toInt();

      setState(() {
        switch (tabIndex) {
          case 1: _inaItems = items; _inaTotal = total; break;
          case 2: _allItems = items; _allTotal = total; break;
          case 0:
          default: _actItems = items; _actTotal = total; break;
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  // ===== Acciones fila/global =====
  Future<void> _onNew() async {
    final ok = await _openForm();
    if (ok == true) await _loadCurrent();
  }

  Future<void> _onEditDialog(Map<String, dynamic> row) async {
    final ok = await _openForm(row: row);
    if (ok == true) await _loadCurrent();
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

  // ===================== EXPORTACIÓN (SOLO EXCEL) =====================

  // Datos y nombre base por pestaña
  (List<Map<String, dynamic>> data, String baseName) _currentExportData() {
    final tab = _tab.index;
    final data = tab == 0 ? _actItems : (tab == 1 ? _inaItems : _allItems);
    final name = tab == 0
        ? 'subcategorias_activas'
        : (tab == 1 ? 'subcategorias_inactivas' : 'subcategorias_todas');
    return (data, name);
  }

  // Guardar bytes cross-platform
  Future<void> _saveBytes(Uint8List bytes, String filename, String mimeType) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final a = html.AnchorElement(href: url)..download = filename;
      a.click();
      html.Url.revokeObjectUrl(url);
      return;
    }
    dynamic dir = await getDownloadsDirectory();
    dir ??= await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename';
    final xf = XFile.fromData(bytes, name: filename, mimeType: mimeType);
    await xf.saveTo(path);
    _showSnack('Guardado en: $path');
  }

  // Exportar Excel (.xlsx)
  Future<void> _exportExcelCurrent() async {
    final (data, base) = _currentExportData();

    final book = xls.Excel.createExcel();
    const sheetName = 'Subcategorias';
    final defaultSheet = book.getDefaultSheet();
    if (defaultSheet != null) book.rename(defaultSheet, sheetName);
    final sheet = book[sheetName];

    // Encabezados
    sheet.appendRow( [
      xls.TextCellValue('ID'),
      xls.TextCellValue('Subcategoría'),
      xls.TextCellValue('Código'),
      xls.TextCellValue('Categoría'),
      xls.TextCellValue('Activo'),
      xls.TextCellValue('Creado'),
    ]);

    // Filas
    for (final r in data) {
      sheet.appendRow([
        xls.TextCellValue('${r['id'] ?? ''}'),
        xls.TextCellValue('${r['nombre'] ?? ''}'),
        xls.TextCellValue('${r['codigo'] ?? ''}'),
        xls.TextCellValue(_catNameOf(r)),
        xls.TextCellValue(r['activo'] == true ? '1' : '0'),
        xls.TextCellValue((r['creadoEn']?.toString().split('T').first) ?? ''),
      ]);
    }

    final bytes = Uint8List.fromList(book.encode()!);
    await _saveBytes(
      bytes,
      '$base.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // ====================================================================

  // ===== Asignación masiva (selector NO asignados) =====
  Future<void> _openBulkPickerDialog(Map<String, dynamic> row) async {
    if (_alumnosRepo == null) {
      _showSnack('No está inyectado AppScope.estudiantes (repo de estudiantes).');
      return;
    }

    final int idSub = (row['id'] as num).toInt();
    final String nombreSub = row['nombre']?.toString() ?? '';

    final qCtrl = TextEditingController();
    Timer? debounce;
    bool loading = true;
    String? error;

    int page = 1;
    int pageSize = 10;
    int total = 0;

    List<Map<String, dynamic>> items = [];
    final selected = <int>{};

    Future<void> load() async {
      loading = true;
      error = null;
      try {
        final res = await _fetchNoAsignadosGlobal(
          q: qCtrl.text.trim().isEmpty ? null : qCtrl.text.trim(),
          page: page,
          pageSize: pageSize,
        );
        items = List<Map<String, dynamic>>.from(res['items'] as List);
        total = (res['total'] as num).toInt();
      } catch (e) {
        error = e.toString();
      } finally {
        loading = false;
      }
    }

    Future<void> doAssign(BuildContext ctx, StateSetter setLocal) async {
      if (selected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos un estudiante.')),
        );
        return;
      }
      setLocal(() => loading = true);
      try {
        final result = await _asignarMasivoNormalizado(idSub: idSub, ids: selected.toList());
        final asignados = (result['asignados'] as List).length;
        final ya = (result['yaEstaban'] as List).length;
        final no = (result['noEncontrados'] as List).length;
        final errs = (result['errores'] as Map).length;

        await showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: Text('Resultado — $nombreSub'),
            content: Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _chipCount(Icons.check_circle, 'Asignados', asignados, Colors.green),
                _chipCount(Icons.info_outline, 'Ya estaban', ya, Colors.blueGrey),
                _chipCount(Icons.report_gmailerrorred, 'No encontrados', no, Colors.orange),
                _chipCount(Icons.error_outline, 'Errores', errs, Colors.red),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
          ),
        );

        if (mounted) Navigator.of(ctx).pop();
        await _loadCurrent();
        _showSnack('Asignación completada');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al asignar: $e')));
        setLocal(() => loading = false);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Future.microtask(() async {
            if (!loading && items.isNotEmpty) return;
            await load();
            if (mounted) setLocal(() {});
          });

          int totalPages = ((total + pageSize - 1) ~/ pageSize);
          if (totalPages < 1) totalPages = 1;
          final bool canBack = page > 1;
          final bool canFwd = page < totalPages;

          final int showingFrom = total == 0 ? 0 : ((page - 1) * pageSize + 1);
          final int rawTo = page * pageSize;
          final int showingTo = rawTo > total ? total : rawTo;

          return AlertDialog(
            title: Text('Asignar estudiantes → $nombreSub'),
            content: SizedBox(
              width: 720,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Búsqueda con debouncer
                  TextField(
                    controller: qCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar estudiante (nombre, cédula, código)…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          qCtrl.clear();
                          debounce?.cancel();
                          page = 1;
                          setLocal(() => loading = true);
                          load().then((_) => setLocal(() {}));
                        },
                      ),
                    ),
                    onChanged: (_) {
                      debounce?.cancel();
                      debounce = Timer(const Duration(milliseconds: 350), () {
                        page = 1;
                        setLocal(() => loading = true);
                        load().then((_) => setLocal(() {}));
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  if (error != null)
                    _ErrorView(
                      error: error!,
                      onRetry: () {
                        setLocal(() => loading = true);
                        load().then((_) => setLocal(() {}));
                      },
                    )
                  else if (loading)
                    const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
                  else if (items.isEmpty)
                    const SizedBox(
                      height: 180,
                      child: Center(child: Text('No hay estudiantes sin subcategoría con ese filtro.')),
                    )
                  else
                    SizedBox(
                      height: 360,
                      child: Column(
                        children: [
                          // Seleccionar toda la página + pageSize
                          Row(
                            children: [
                              Checkbox(
                                value: items.every((r) {
                                  final id = _studentIdOf(r);
                                  return id != null && selected.contains(id);
                                }),
                                onChanged: (v) {
                                  if (v == true) {
                                    for (final r in items) {
                                      final id = _studentIdOf(r);
                                      if (id != null) selected.add(id);
                                    }
                                  } else {
                                    for (final r in items) {
                                      final id = _studentIdOf(r);
                                      if (id != null) selected.remove(id);
                                    }
                                  }
                                  setLocal(() {});
                                },
                              ),
                              const SizedBox(width: 4),
                              const Text('Seleccionar página'),
                              const Spacer(),
                              DropdownButton<int>(
                                value: pageSize,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 10, child: Text('10 / pág.')),
                                  DropdownMenuItem(value: 20, child: Text('20 / pág.')),
                                  DropdownMenuItem(value: 50, child: Text('50 / pág.')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  pageSize = v;
                                  page = 1;
                                  setLocal(() => loading = true);
                                  load().then((_) => setLocal(() {}));
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Lista con checkboxes
                          Expanded(
                            child: ScrollConfiguration(
                              behavior: const ScrollBehavior().copyWith(scrollbars: true),
                              child: ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final r = items[i];
                                  final id = _studentIdOf(r);
                                  final checked = id != null && selected.contains(id);
                                  final title = _studentDisplayName(r);
                                  final subtitle = _studentSecondaryInfo(r);

                                  return CheckboxListTile(
                                    value: checked,
                                    onChanged: (v) {
                                      if (id == null) return;
                                      if (v == true) {
                                        selected.add(id);
                                      } else {
                                        selected.remove(id);
                                      }
                                      setLocal(() {});
                                    },
                                    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    secondary: id == null ? null : CircleAvatar(
                                      radius: 14,
                                      child: Text('$id', style: const TextStyle(fontSize: 12)),
                                    ),
                                    controlAffinity: ListTileControlAffinity.leading,
                                  );
                                },
                              ),
                            ),
                          ),

                          // Paginación
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Mostrando $showingFrom–$showingTo de $total'),
                              const SizedBox(width: 12),
                              IconButton(icon: const Icon(Icons.first_page), onPressed: canBack ? () { page = 1; setLocal(() => loading = true); load().then((_) => setLocal(() {})); } : null),
                              IconButton(icon: const Icon(Icons.chevron_left), onPressed: canBack ? () { page -= 1; setLocal(() => loading = true); load().then((_) => setLocal(() {})); } : null),
                              Text('$page / $totalPages'),
                              IconButton(icon: const Icon(Icons.chevron_right), onPressed: canFwd ? () { page += 1; setLocal(() => loading = true); load().then((_) => setLocal(() {})); } : null),
                              IconButton(icon: const Icon(Icons.last_page), onPressed: canFwd ? () { page = totalPages; setLocal(() => loading = true); load().then((_) => setLocal(() {})); } : null),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
              FilledButton.icon(
                icon: const Icon(Icons.group_add),
                label: Text('Asignar (${selected.length})'),
                onPressed: loading || selected.isEmpty ? null : () => doAssign(ctx, setLocal),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===== Helpers no asignados =====
  Future<Map<String, dynamic>> _fetchNoAsignadosGlobal({
    String? q,
    required int page,
    required int pageSize,
  }) async {
    if (_alumnosRepo == null) {
      throw 'Repo de estudiantes no disponible (AppScope.estudiantes).';
    }

    Future<dynamic> _tryCall(Future<dynamic> Function() fn) async {
      try { return await fn().timeout(const Duration(seconds: 6)); } catch (_) { return null; }
    }

    dynamic res;
    try { res ??= await _tryCall(() => _alumnosRepo.noAsignadosGlobal(q: q, page: page, pageSize: pageSize)); } catch (_) {}
    try { res ??= await _tryCall(() => _alumnosRepo.noAsignados(q: q, page: page, pageSize: pageSize)); } catch (_) {}
    try { res ??= await _tryCall(() => _alumnosRepo.sinSubcategoria(q: q, page: page, pageSize: pageSize)); } catch (_) {}
    try { res ??= await _tryCall(() => _alumnosRepo.paged(q: q, page: page, pageSize: pageSize, asignado: false)); } catch (_) {}

    if (res == null) throw 'No hay endpoint para listar estudiantes sin subcategoría.';

    List<Map<String, dynamic>> items = const [];
    int total = 0;
    final offset = (page - 1) * pageSize;

    Map<String, dynamic> _unwrapMap(Map m) {
      dynamic list = m['items'] ?? m['rows'] ?? (m['data'] is Map ? (m['data']['items'] ?? m['data']['rows']) : null);
      if (list is List) {
        items = List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e as Map)));
      } else if (m['data'] is List) {
        items = List<Map<String, dynamic>>.from((m['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      }
      final t = m['total'] ?? m['count'] ?? (m['data'] is Map ? m['data']['total'] ?? m['data']['count'] : null);
      total = (t is num) ? t.toInt() : (page == 1 ? items.length : (offset + items.length));
      return {'items': items, 'total': total};
    }

    if (res is Map) {
      final r = _unwrapMap(res);
      items = List<Map<String, dynamic>>.from(r['items']);
      total = (r['total'] as num).toInt();
    } else if (res is List) {
      items = List<Map<String, dynamic>>.from(res.map((e) => Map<String, dynamic>.from(e as Map)));
      total = (page == 1 ? items.length : (offset + items.length));
    } else {
      throw 'Respuesta de no asignados no reconocida.';
    }

    bool _isUnassigned(Map<String, dynamic> r) {
      if (r['asignado'] == true || r['tieneSubcategoria'] == true) return false;
      if (r['subcategoriaId'] != null || r['idSubcategoria'] != null) return false;
      final subcats = r['subcategorias'] ?? r['asignaciones'] ?? r['subs'] ?? r['grupos'];
      if (subcats is List && subcats.isNotEmpty) return false;
      return true;
    }

    items = items.where(_isUnassigned).toList();
    total = items.length < total ? total : items.length;
    return {'items': items, 'total': total};
  }

  // ===== Helpers estudiante =====
  int? _studentIdOf(Map<String, dynamic> r) {
    final v = r['id'] ?? r['id_estudiante'] ?? r['idEstudiante'] ?? r['estudianteId'];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  String _studentDisplayName(Map<String, dynamic> r) {
    final full = (r['nombreCompleto'] ?? r['full_name'] ?? r['fullName'])?.toString();
    if (full != null && full.trim().isNotEmpty) return full;

    final n = (r['nombres'] ?? r['nombre'] ?? r['first_name'] ?? r['firstName'] ?? '').toString();
    final a = (r['apellidos'] ?? r['apellido'] ?? r['last_name'] ?? r['lastName'] ?? '').toString();
    final combined = ('$n $a').trim();
    if (combined.isNotEmpty) return combined;

    return r['alias']?.toString() ?? r['codigo']?.toString() ?? 'Sin nombre';
  }

  String? _studentSecondaryInfo(Map<String, dynamic> r) {
    final ced = r['cedula'] ?? r['dni'] ?? r['documento'] ?? r['identificacion'];
    final cod = r['codigo'] ?? r['code'] ?? r['studentCode'];
    final tel = r['telefono'] ?? r['phone'];
    final parts = <String>[];
    if ('$ced'.trim().isNotEmpty && ced != null) parts.add('Cédula: $ced');
    if ('$cod'.trim().isNotEmpty && cod != null) parts.add('Código: $cod');
    if ('$tel'.trim().isNotEmpty && tel != null) parts.add('Tel: $tel');
    return parts.isEmpty ? null : parts.join(' · ');
  }

  // ===== Normalizador asignación masiva =====
  Future<Map<String, dynamic>> _asignarMasivoNormalizado({
    required int idSub,
    required List<int> ids,
  }) async {
    dynamic res;
    try {
      if (_alumnosRepo != null) {
        res = await _alumnosRepo.asignarASubcategoria(ids: ids, idSubcategoria: idSub);
        return _normalizeAssignResponse(res, ids);
      }
    } catch (_) {}
    try {
      final fn = _subRepo.asignarEstudiantesMasivo;
      if (fn != null) {
        res = await fn(idSubcategoria: idSub, ids: ids);
        return _normalizeAssignResponse(res, ids);
      }
    } catch (_) {}
    throw 'No se encontró método para asignación masiva en estudiantes o subcategorias.';
  }

  Map<String, dynamic> _normalizeAssignResponse(dynamic res, List<int> sent) {
    final asignados = <int>[];
    final ya = <int>[];
    final no = <int>[];
    final errs = <int, String>{};

    List<int> _toIntList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => (e is num) ? e.toInt() : int.tryParse('$e') ?? -1)
            .where((e) => e >= 0)
            .toList();
      }
      return const <int>[];
    }

    Map<int, String> _toErrMap(dynamic v) {
      if (v is Map) {
        final out = <int, String>{};
        v.forEach((k, val) {
          final id = (k is num) ? k.toInt() : int.tryParse('$k');
          if (id != null) out[id] = val?.toString() ?? 'Error';
        });
        return out;
      }
      return const <int, String>{};
    }

    if (res is Map) {
      asignados.addAll(_toIntList(res['asignados'] ?? res['insertados'] ?? res['ok']));
      ya.addAll(_toIntList(res['yaEstaban'] ?? res['existentes'] ?? res['duplicados']));
      no.addAll(_toIntList(res['noEncontrados'] ?? res['no_existentes'] ?? res['faltantes']));
      errs.addAll(_toErrMap(res['errores']));
      if (asignados.isEmpty && ya.isEmpty && no.isEmpty && errs.isEmpty) {
        asignados.addAll(sent);
      }
    } else if (res is List) {
      for (final e in res) {
        final v = (e is num) ? e.toInt() : int.tryParse('$e');
        if (v != null) asignados.add(v);
      }
    } else if (res == true) {
      asignados.addAll(sent);
    } else {
      for (final id in sent) {
        errs[id] = 'Respuesta no reconocida del servidor.';
      }
    }

    List<int> _clean(List<int> l) => l.toSet().toList()..sort();
    return {
      'asignados': _clean(asignados),
      'yaEstaban': _clean(ya),
      'noEncontrados': _clean(no),
      'errores': errs,
    };
  }

  // Chip contador
  Widget _chipCount(IconData icon, String label, int count, Color? color) {
    return Chip(avatar: Icon(icon, size: 18, color: color), label: Text('$label: $count'));
  }

  // ===== Paginación =====
  void _onPageChange(int tabIndex, int newPage) {
    if (newPage < 1) return;
    int totalItems, pageSize;
    switch (tabIndex) {
      case 1: totalItems = _inaTotal; pageSize = _inaPageSize; break;
      case 2: totalItems = _allTotal; pageSize = _allPageSize; break;
      case 0:
      default: totalItems = _actTotal; pageSize = _actPageSize; break;
    }
    int lastPage = (totalItems + pageSize - 1) ~/ pageSize;
    if (lastPage == 0) lastPage = 1;
    if (newPage > lastPage) return;

    setState(() {
      switch (tabIndex) {
        case 0: _actPage = newPage; break;
        case 1: _inaPage = newPage; break;
        case 2: _allPage = newPage; break;
      }
    });
    _loadCurrent();
  }

  void _onPageSizeChange(int tabIndex, int newSize) {
    if (newSize <= 0) return;
    setState(() {
      switch (tabIndex) {
        case 0: _actPageSize = newSize; _actPage = 1; break;
        case 1: _inaPageSize = newSize; _inaPage = 1; break;
        case 2: _allPageSize = newSize; _allPage = 1; break;
      }
    });
    _loadCurrent();
  }

  // ===== Helpers UI =====
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====================================================================
  // ============================ BUILD =================================
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    final isFirstLoad = _loading &&
        _actItems.isEmpty &&
        _inaItems.isEmpty &&
        _allItems.isEmpty;

    final core = LayoutBuilder(
      builder: (ctx, c) {
        final isNarrow = c.maxWidth < 820;
        const double maxContentWidth = 1200;
        final double width = c.maxWidth > maxContentWidth ? maxContentWidth : c.maxWidth;

        final header = _buildHeader(context, isNarrow);

        final tabs = TabBar(
          controller: _tab,
          isScrollable: isNarrow,
          tabs: [
            Tab(text: 'Activas ($_actTotal)'),
            Tab(text: 'Inactivas ($_inaTotal)'),
            Tab(text: 'Todas ($_allTotal)'),
          ],
        );

        final content = isFirstLoad
            ? _LoadingPlaceholder(isNarrow: isNarrow, viewMode: _viewMode, dense: _dense)
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _loadCurrent)
                : TabBarView(
                    controller: _tab,
                    children: [
                      _buildTabContent(context, isNarrow, 0),
                      _buildTabContent(context, isNarrow, 1),
                      _buildTabContent(context, isNarrow, 2),
                    ],
                  );

        final body = Align(
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
                Expanded(
                  child: Stack(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: content,
                      ),
                      if (_loading && !isFirstLoad)
                        const Positioned(
                          right: 12,
                          top: 8,
                          child: _LoadingChip(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        return _withShortcuts(body);
      },
    );

    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subcategorías')),
        body: Padding(padding: const EdgeInsets.all(12), child: core),
      );
    }
    return Padding(padding: const EdgeInsets.all(12), child: core);
  }

  // ===== Header =====
  Widget _buildHeader(BuildContext context, bool isNarrow) {
    final activeFilters = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (_q != null)
          InputChip(
            label: Text('Búsqueda: "${_q!}"'),
            onDeleted: () { _search.clear(); _loadCurrent(); },
            avatar: const Icon(Icons.search, size: 18),
          ),
        if (_idCategoria != null)
          InputChip(
            label: Text('Categoría: ${_catById[_idCategoria!] ?? '-'}'),
            onDeleted: () {
              setState(() => _idCategoria = null);
              _resetPages();
              _loadCurrent();
            },
            avatar: const Icon(Icons.category, size: 18),
          ),
        InputChip(
          label: Text(_viewMode == _ViewMode.table ? 'Tabla' : 'Tarjetas'),
          avatar: Icon(_viewMode == _ViewMode.table ? Icons.table_chart : Icons.view_agenda, size: 18),
          onPressed: () => setState(() {
            _viewMode = _viewMode == _ViewMode.table ? _ViewMode.cards : _ViewMode.table;
          }),
        ),
        InputChip(
          label: Text(_dense ? 'Denso' : 'Cómodo'),
          avatar: Icon(_dense ? Icons.compress : Icons.unfold_more, size: 18),
          onPressed: () => setState(() => _dense = !_dense),
        ),
      ],
    );

    final searchField = TextField(
      controller: _search,
      focusNode: _searchFocus,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o código…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Limpiar',
              child: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () { _search.clear(); _loadCurrent(); },
              ),
            ),
            Tooltip(
              message: 'Recargar (Ctrl+R)',
              child: IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCurrent),
            ),
          ],
        ),
      ),
      onSubmitted: (_) => _loadCurrent(),
      textInputAction: TextInputAction.search,
    );

    final viewSelector = SegmentedButton<_ViewMode>(
      segments: const [
        ButtonSegment<_ViewMode>(value: _ViewMode.table, icon: Icon(Icons.table_chart), label: Text('Tabla')),
        ButtonSegment<_ViewMode>(value: _ViewMode.cards,  icon: Icon(Icons.view_agenda), label: Text('Tarjetas')),
      ],
      selected: {_viewMode},
      onSelectionChanged: (s) => setState(() => _viewMode = s.first),
    );

    final cat = SizedBox(
      width: isNarrow ? double.infinity : 260,
      child: DropdownButtonFormField<int?>(
        value: _idCategoria,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.category), labelText: 'Categoría'),
        items: <DropdownMenuItem<int?>>[
          const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
          ..._catOptions.map((e) => DropdownMenuItem<int?>(
                value: (e['id'] as num).toInt(),
                child: Text(e['nombre']?.toString() ?? '—'),
              )),
        ],
        onChanged: (v) {
          _resetPages();
          setState(() => _idCategoria = v);
          _loadCurrent();
        },
      ),
    );

    // ✅ Solo Excel
    final exportBtn = OutlinedButton.icon(
      onPressed: _exportExcelCurrent,
      icon: const Icon(Icons.grid_on),
      label: const Text('Excel'),
    );

    final add = FilledButton.icon(
      onPressed: _onNew,
      icon: const Icon(Icons.add),
      label: const Text('Nueva'),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 8),
          viewSelector,
          const SizedBox(height: 8),
          cat,
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [exportBtn, const SizedBox(width: 8), add]),
          const SizedBox(height: 8),
          activeFilters,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 8),
            SizedBox(width: 240, child: viewSelector),
            const SizedBox(width: 8),
            SizedBox(width: 260, child: cat),
            const Spacer(),
            exportBtn,
            const SizedBox(width: 8),
            add,
          ],
        ),
        const SizedBox(height: 8),
        activeFilters,
      ],
    );
  }

  List<Map<String, dynamic>> _itemsForTab(int index) {
    switch (index) {
      case 1: return _inaItems;
      case 2: return _allItems;
      case 0:
      default: return _actItems;
    }
  }

  Widget _buildTabContent(BuildContext context, bool isNarrow, int tabIndex) {
    final items = _itemsForTab(tabIndex);

    int currentPage, totalItems, pageSize;
    switch (tabIndex) {
      case 1: currentPage = _inaPage; totalItems = _inaTotal; pageSize = _inaPageSize; break;
      case 2: currentPage = _allPage; totalItems = _allTotal; pageSize = _allPageSize; break;
      case 0:
      default: currentPage = _actPage; totalItems = _actTotal; pageSize = _actPageSize; break;
    }

    final paginator = _PaginationControls(
      currentPage: currentPage,
      totalItems: totalItems,
      pageSize: pageSize,
      onPageChange: (newPage) => _onPageChange(tabIndex, newPage),
      onPageSizeChange: (newSize) => _onPageSizeChange(tabIndex, newSize),
    );

    if (items.isEmpty && !_loading) {
      return Column(
        children: [
          Expanded(
            child: _EmptyState(
              title: 'Sin subcategorías',
              subtitle: 'Crea tu primera subcategoría o ajusta los filtros/búsqueda.',
              primary: ('Crear nueva', _onNew),
              secondary: ('Quitar filtros', () {
                setState(() { _idCategoria = null; _search.clear(); });
                _resetPages();
                _loadCurrent();
              }),
            ),
          ),
          const SizedBox(height: 8),
          paginator,
        ],
      );
    }

    final content = _viewMode == _ViewMode.cards
        ? _cards(context, items)
        : _table(context, items);

    return Column(
      children: [
        Expanded(child: content),
        if (totalItems > pageSize) paginator,
      ],
    );
  }

  // Encabezado compacto para DataTable (evita overflow)
  Widget _th(String s) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(s),
      );

  // ===== Tabla (desktop) =====
  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
    final isNarrow = MediaQuery.of(context).size.width < 820;
    final textStyle = _dense
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium;

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ClipRect(
          child: DataTable(
            columnSpacing: isNarrow ? 16 : 24,
            horizontalMargin: 12,
            headingRowHeight: _dense ? 36 : 48,
            dataRowMinHeight: _dense ? 32 : 44,
            dataRowMaxHeight: _dense ? 40 : null,
            columns: [
              DataColumn(label: _th('ID')),
              DataColumn(label: _th('Subcategoría')),
              DataColumn(label: _th('Código')),
              DataColumn(label: _th('Categoría')),
              DataColumn(label: _th('Estado')),
              DataColumn(label: _th('Creado')),
              DataColumn(label: _th('Acciones')),
            ],
            rows: rows.map((r) {
              final bool activo = r['activo'] == true;
              final estadoIcon = Icon(
                activo ? Icons.check_circle : Icons.cancel,
                color: activo ? Colors.green : Colors.grey,
                size: _dense ? 18 : 20,
                semanticLabel: activo ? 'Activa' : 'Inactiva',
              );
              return DataRow(cells: [
                DataCell(SelectableText(r['id']?.toString() ?? '', style: textStyle)),
                DataCell(SelectableText(r['nombre']?.toString() ?? '', style: textStyle)),
                DataCell(SelectableText(r['codigo']?.toString() ?? '', style: textStyle)),
                DataCell(SelectableText(_catNameOf(r), style: textStyle)),
                DataCell(estadoIcon),
                DataCell(SelectableText(r['creadoEn']?.toString().split('T').first ?? '', style: textStyle)),
                DataCell(_rowActions(r: r, activo: activo, dense: _dense)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ===== Tarjetas (móvil) =====
  Widget _cards(BuildContext context, List<Map<String, dynamic>> rows) {
    final spacing = _dense ? 6.0 : 8.0;
    final padding = EdgeInsets.all(_dense ? 10 : 12);

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: (ctx, i) {
        final r = rows[i];
        final bool activo = r['activo'] == true;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (widget.embedded && widget.onOpenEstudiantes != null) {
                widget.onOpenEstudiantes!(r);
                return;
              }
              Navigator.pushNamed(
                context,
                RouteNames.adminSubcatEstudiantes,
                arguments: {
                  'idSubcategoria': (r['id'] as num).toInt(),
                  'nombreSubcategoria': r['nombre'],
                  'idCategoria': r['idCategoria'],
                },
              );
            },
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r['nombre']?.toString() ?? '',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        activo ? Icons.check_circle : Icons.cancel,
                        size: 18,
                        color: activo ? Colors.green : Colors.grey,
                        semanticLabel: activo ? 'Activa' : 'Inactiva',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _KV('Código', r['codigo'] ?? ''),
                  _KV('Categoría', _catNameOf(r)),
                  _KV('Creado', r['creadoEn']?.toString().split('T').first ?? ''),
                  const SizedBox(height: 8),
                  _rowActions(r: r, activo: activo, dense: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _KV(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 96, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ===== Botonera por fila =====
  Widget _rowActions({required Map<String, dynamic> r, required bool activo, bool dense = false}) {
    final double iconSize = dense ? 20 : 24;
    final EdgeInsets padding = EdgeInsets.all(dense ? 6 : 8);

    return OverflowBar(
      spacing: dense ? 4 : 8,
      overflowSpacing: dense ? 4 : 8,
      children: [
        Tooltip(
          message: 'Estudiantes',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            icon: const Icon(Icons.people),
            onPressed: () {
              if (widget.embedded && widget.onOpenEstudiantes != null) {
                widget.onOpenEstudiantes!(r);
                return;
              }
              Navigator.pushNamed(
                context,
                RouteNames.adminSubcatEstudiantes,
                arguments: {
                  'idSubcategoria': (r['id'] as num).toInt(),
                  'nombreSubcategoria': r['nombre'],
                  'idCategoria': r['idCategoria'],
                },
              );
            },
          ),
        ),
        Tooltip(
          message: 'Asignar estudiantes (solo no asignados)',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            icon: const Icon(Icons.group_add),
            onPressed: () => _openBulkPickerDialog(r),
          ),
        ),
        Tooltip(
          message: 'Editar',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            icon: const Icon(Icons.edit),
            onPressed: () => _onEditDialog(r),
          ),
        ),
        Tooltip(
          message: activo ? 'Desactivar' : 'Activar',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            icon: Icon(activo ? Icons.visibility_off : Icons.visibility),
            onPressed: () => _onToggle(r),
          ),
        ),
      ],
    );
  }

  // ===== Atajos de teclado =====
  Widget _withShortcuts(Widget child) {
    return FocusTraversalGroup(
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const FocusSearchIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const NewSubcatIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const ReloadIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            FocusSearchIntent: CallbackAction<FocusSearchIntent>(
              onInvoke: (_) { _searchFocus.requestFocus(); return null; },
            ),
            NewSubcatIntent: CallbackAction<NewSubcatIntent>(
              onInvoke: (_) { _onNew(); return null; },
            ),
            ReloadIntent: CallbackAction<ReloadIntent>(
              onInvoke: (_) { _loadCurrent(); return null; },
            ),
          },
          child: Focus(autofocus: true, child: child),
        ),
      ),
    );
  }
}

// ======================= Widgets de apoyo UI =======================

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int pageSize;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;

  const _PaginationControls({
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  @override
  Widget build(BuildContext context) {
    int totalPages = (totalItems + pageSize - 1) ~/ pageSize;
    if (totalPages < 1) totalPages = 1;
    final bool canGoBack = currentPage > 1;
    final bool canGoFwd = currentPage < totalPages;
    final int from = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final int rawTo = currentPage * pageSize;
    final int to = rawTo > totalItems ? totalItems : rawTo;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Text('Mostrando $from–$to de $totalItems'),
            const Spacer(),
            DropdownButton<int>(
              value: pageSize,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10 / pág.')),
                DropdownMenuItem(value: 20, child: Text('20 / pág.')),
                DropdownMenuItem(value: 50, child: Text('50 / pág.')),
              ],
              onChanged: (v) { if (v != null) onPageSizeChange(v); },
            ),
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'Primera página',
              onPressed: canGoBack ? () => onPageChange(1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Página anterior',
              onPressed: canGoBack ? () => onPageChange(currentPage - 1) : null,
            ),
            Text('$currentPage / $totalPages'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Página siguiente',
              onPressed: canGoFwd ? () => onPageChange(currentPage + 1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              tooltip: 'Última página',
              onPressed: canGoFwd ? () => onPageChange(totalPages) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final (String, VoidCallback) primary;
  final (String, VoidCallback)? secondary;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: primary.$2, child: Text(primary.$1)),
                if (secondary != null)
                  OutlinedButton(onPressed: secondary!.$2, child: Text(secondary!.$1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 56),
            const SizedBox(height: 12),
            Text('Error al cargar datos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      label: const Text('Cargando…'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final bool isNarrow;
  final _ViewMode viewMode;
  final bool dense;

  const _LoadingPlaceholder({required this.isNarrow, required this.viewMode, required this.dense});

  @override
  Widget build(BuildContext context) {
    if (viewMode == _ViewMode.cards || isNarrow) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _Skeleton(height: dense ? 84 : 104),
        ),
      );
    }
    return Column(
      children: [
        _Skeleton(height: dense ? 44 : 52),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _Skeleton(height: dense ? 36 : 44),
            ),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
    );
  }
}
