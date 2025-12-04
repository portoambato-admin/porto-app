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
  _ViewMode _viewMode = _ViewMode.cards;
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

  // ===== Orden natural =====
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
        sort: 'nombre_subcategoria', 
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
      // Limpiar cachés para forzar recarga
      _actItems.clear(); _inaItems.clear(); _allItems.clear();
      await _loadCurrent();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ========================= DIÁLOGO MODERNO =========================
  
  InputDecoration _modernInputDeco(String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.8)),
      prefixIcon: Icon(icon, color: cs.primary.withOpacity(0.7), size: 22),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.transparent)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cs.error.withOpacity(0.5))),
    );
  }

  Future<bool?> _openForm({Map<String, dynamic>? row}) async {
    final formKey = GlobalKey<FormState>();
    final nombre = TextEditingController(text: row?['nombre']?.toString() ?? '');
    final codigo = TextEditingController(text: row?['codigo']?.toString() ?? '');
    int? idCat = row?['idCategoria'] is num
        ? (row?['idCategoria'] as num).toInt()
        : row?['idCategoria'] as int?;
    
    final cs = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: cs.surface,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con Gradiente
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        child: Hero(
                          tag: row != null ? 'sub_icon_${row['id']}' : 'new_sub_icon',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.deepPurple.shade50,
                              child: Icon(Icons.class_rounded, size: 36, color: Colors.deepPurple.shade700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(row == null ? 'Nueva Subcategoría' : 'Editar Subcategoría', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            value: idCat,
                            decoration: _modernInputDeco('Categoría Padre', Icons.category),
                            items: _catOptions.map((e) {
                              return DropdownMenuItem<int>(
                                value: (e['id'] as num).toInt(),
                                child: Text(e['nombre']?.toString() ?? '—'),
                              );
                            }).toList(),
                            validator: (v) => v == null ? 'Selecciona una categoría' : null,
                            onChanged: (v) => idCat = v,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: nombre,
                            decoration: _modernInputDeco('Nombre de subcategoría', Icons.label_outline),
                            maxLength: 60,
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return 'Requerido';
                              if (s.length < 2) return 'Muy corto';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: codigo,
                            decoration: _modernInputDeco('Código único', Icons.qr_code),
                            maxLength: 32,
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
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
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                              ),
                              child: Text(row == null ? 'CREAR SUBCATEGORÍA' : 'GUARDAR CAMBIOS', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== EXPORTACIÓN (SOLO EXCEL) =====================

  (List<Map<String, dynamic>> data, String baseName) _currentExportData() {
    final tab = _tab.index;
    final data = tab == 0 ? _actItems : (tab == 1 ? _inaItems : _allItems);
    final name = tab == 0
        ? 'subcategorias_activas'
        : (tab == 1 ? 'subcategorias_inactivas' : 'subcategorias_todas');
    return (data, name);
  }

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

  Future<void> _exportExcelCurrent() async {
    final (data, base) = _currentExportData();
    final book = xls.Excel.createExcel();
    const sheetName = 'Subcategorias';
    final defaultSheet = book.getDefaultSheet();
    if (defaultSheet != null) book.rename(defaultSheet, sheetName);
    final sheet = book[sheetName];

    sheet.appendRow([
      xls.TextCellValue('ID'), xls.TextCellValue('Subcategoría'), xls.TextCellValue('Código'), 
      xls.TextCellValue('Categoría'), xls.TextCellValue('Activo'), xls.TextCellValue('Creado'),
    ]);

    for (final r in data) {
      sheet.appendRow([
        xls.TextCellValue('${r['id'] ?? ''}'), xls.TextCellValue('${r['nombre'] ?? ''}'), xls.TextCellValue('${r['codigo'] ?? ''}'),
        xls.TextCellValue(_catNameOf(r)), xls.TextCellValue(r['activo'] == true ? '1' : '0'),
        xls.TextCellValue((r['creadoEn']?.toString().split('T').first) ?? ''),
      ]);
    }
    final bytes = Uint8List.fromList(book.encode()!);
    await _saveBytes(bytes, '$base.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  // ===================== ASIGNACIÓN MASIVA (RESTAURADA) =====================

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

    int page = 1;
    int pageSize = 10;
    int total = 0;

    List<Map<String, dynamic>> items = [];
    final selected = <int>{};

    Future<void> load() async {
      loading = true;
      try {
        final res = await _fetchNoAsignadosGlobal(
          q: qCtrl.text.trim().isEmpty ? null : qCtrl.text.trim(),
          page: page,
          pageSize: pageSize,
        );
        items = List<Map<String, dynamic>>.from(res['items'] as List);
        total = (res['total'] as num).toInt();
      } catch (e) {
      } finally {
        loading = false;
      }
    }

    Future<void> doAssign(BuildContext ctx, StateSetter setLocal) async {
      if (selected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona al menos un estudiante.')));
        return;
      }
      setLocal(() => loading = true);
      try {
        // Asignación con lógica robusta
        final result = await _asignarMasivoNormalizado(idSub: idSub, ids: selected.toList());
        
        final asignados = (result['asignados'] as List).length;
        final ya = (result['yaEstaban'] as List).length;
        final no = (result['noEncontrados'] as List).length;
        final errs = (result['errores'] as Map).length;

        // Mostrar reporte detallado
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
            title: Text('Asignar a $nombreSub'),
            content: SizedBox(
              width: 720,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar estudiante...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (_) {
                      debounce?.cancel();
                      debounce = Timer(const Duration(milliseconds: 350), () {
                        page = 1; setLocal(() => loading = true);
                        load().then((_) => setLocal(() {}));
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  if (loading) const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                  else if (items.isEmpty) const SizedBox(height: 200, child: Center(child: Text('No hay estudiantes disponibles')))
                  else SizedBox(
                    height: 360,
                    child: Column(children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final r = items[i];
                            final id = _studentIdOf(r);
                            final checked = id != null && selected.contains(id);
                            return CheckboxListTile(
                              value: checked,
                              title: Text(_studentDisplayName(r)),
                              subtitle: Text(_studentSecondaryInfo(r) ?? ''),
                              onChanged: (v) {
                                if (id == null) return;
                                if (v == true) selected.add(id); else selected.remove(id);
                                setLocal(() {});
                              },
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(icon: const Icon(Icons.chevron_left), onPressed: canBack ? () { page--; setLocal(() => loading = true); load().then((_) => setLocal((){})); } : null),
                          Text('$showingFrom-$showingTo de $total'),
                          IconButton(icon: const Icon(Icons.chevron_right), onPressed: canFwd ? () { page++; setLocal(() => loading = true); load().then((_) => setLocal((){})); } : null),
                        ],
                      )
                    ]),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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

  // ===== Helpers RESTAURADOS para Asignación Masiva =====
  Future<Map<String, dynamic>> _fetchNoAsignadosGlobal({String? q, required int page, required int pageSize}) async {
    if (_alumnosRepo == null) throw 'Repo de estudiantes no disponible.';
    dynamic res;
    Future<dynamic> _tryCall(Future<dynamic> Function() fn) async {
      try { return await fn().timeout(const Duration(seconds: 6)); } catch (_) { return null; }
    }
    // Intenta varios métodos posibles en el repo
    try { res ??= await _tryCall(() => _alumnosRepo.noAsignadosGlobal(q: q, page: page, pageSize: pageSize)); } catch (_) {}
    try { res ??= await _tryCall(() => _alumnosRepo.noAsignados(q: q, page: page, pageSize: pageSize)); } catch (_) {}
    
    if (res == null) return {'items': [], 'total': 0}; // Fallback

    List<Map<String, dynamic>> items = const [];
    int total = 0;
    
    // Normalizar respuesta (puede venir como Lista o Mapa)
    if (res is Map) {
      final list = res['items'] ?? res['rows'] ?? res['data'] ?? [];
      items = List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e)));
      total = (res['total'] as num?)?.toInt() ?? items.length;
    } else if (res is List) {
      items = List<Map<String, dynamic>>.from(res.map((e) => Map<String, dynamic>.from(e)));
      total = items.length;
    }
    return {'items': items, 'total': total};
  }

  Future<Map<String, dynamic>> _asignarMasivoNormalizado({required int idSub, required List<int> ids}) async {
    dynamic res;
    // 1. Intentar repo de alumnos
    try {
      if (_alumnosRepo != null) {
        res = await _alumnosRepo.asignarASubcategoria(ids: ids, idSubcategoria: idSub);
        return _normalizeAssignResponse(res, ids);
      }
    } catch (_) {}
    // 2. Intentar repo de subcategorias
    try {
      final fn = _subRepo.asignarEstudiantesMasivo;
      if (fn != null) {
        res = await fn(idSubcategoria: idSub, ids: ids);
        return _normalizeAssignResponse(res, ids);
      }
    } catch (_) {}
    throw 'No se encontró método para asignación masiva.';
  }

  Map<String, dynamic> _normalizeAssignResponse(dynamic res, List<int> sent) {
    // Normalizador robusto que maneja cualquier formato de respuesta
    final asignados = <int>[];
    final ya = <int>[];
    final no = <int>[];
    final errs = <int, String>{};

    List<int> _toIntList(dynamic v) {
      if (v is List) return v.map((e) => (e is num) ? e.toInt() : int.tryParse('$e') ?? -1).where((e) => e >= 0).toList();
      return const [];
    }

    if (res is Map) {
      asignados.addAll(_toIntList(res['asignados'] ?? res['ok']));
      ya.addAll(_toIntList(res['yaEstaban'] ?? res['existentes']));
      no.addAll(_toIntList(res['noEncontrados']));
      if (asignados.isEmpty && ya.isEmpty && no.isEmpty) asignados.addAll(sent); // Asumir éxito si vacío
    } else if (res == true) {
      asignados.addAll(sent);
    }
    return {'asignados': asignados, 'yaEstaban': ya, 'noEncontrados': no, 'errores': errs};
  }

  Widget _chipCount(IconData icon, String label, int count, Color? color) {
    return Chip(avatar: Icon(icon, size: 18, color: color), label: Text('$label: $count'));
  }

  // ===== Helpers estudiante =====
  int? _studentIdOf(Map<String, dynamic> r) {
    final v = r['id'] ?? r['id_estudiante'];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  String _studentDisplayName(Map<String, dynamic> r) {
    return (r['nombreCompleto'] ?? r['nombres'] ?? 'Estudiante').toString();
  }

  String? _studentSecondaryInfo(Map<String, dynamic> r) {
    return r['cedula']?.toString();
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====================================================================
  // ============================ BUILD =================================
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    final isFirstLoad = _loading && _actItems.isEmpty && _inaItems.isEmpty && _allItems.isEmpty;

    final core = LayoutBuilder(
      builder: (ctx, c) {
        final isNarrow = c.maxWidth < 820;
        final header = _buildModernHeader(context, isNarrow);

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

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 12),
            tabs,
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: content),
                  if (_loading && !isFirstLoad)
                    const Positioned(right: 12, top: 8, child: _LoadingChip()),
                ],
              ),
            ),
          ],
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

  Widget _buildModernHeader(BuildContext context, bool isNarrow) {
    final cs = Theme.of(context).colorScheme;
    final searchField = TextField(
      controller: _search,
      focusNode: _searchFocus,
      decoration: InputDecoration(
        hintText: 'Buscar subcategoría...',
        prefixIcon: Icon(Icons.search, color: cs.primary),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        suffixIcon: _search.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _search.clear(); _loadCurrent(); }) : null,
      ),
      onChanged: (_) => _onSearchChanged(),
    );

    final viewToggle = Container(
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.grid_view_rounded, color: _viewMode == _ViewMode.cards ? cs.primary : cs.onSurfaceVariant), onPressed: () => setState(() => _viewMode = _ViewMode.cards)),
          Container(width: 1, height: 20, color: cs.outlineVariant),
          IconButton(icon: Icon(Icons.table_rows_rounded, color: _viewMode == _ViewMode.table ? cs.primary : cs.onSurfaceVariant), onPressed: () => setState(() => _viewMode = _ViewMode.table)),
        ],
      ),
    );

    // Filtro Categoría Padre (Dropdown)
    final catFilter = SizedBox(
        width: 200,
        child: DropdownButtonFormField<int?>(
            value: _idCategoria,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: cs.surface,
                hintText: 'Categoría',
                prefixIcon: const Icon(Icons.filter_list),
            ),
            items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ..._catOptions.map((e) => DropdownMenuItem(value: (e['id'] as num).toInt(), child: Text(e['nombre'] ?? ''))),
            ],
            onChanged: (v) {
                setState(() => _idCategoria = v);
                _resetPages();
                _loadCurrent();
            },
        ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: isNarrow 
        ? Column(children: [
            searchField, 
            const SizedBox(height: 8), 
            Row(children: [Expanded(child: catFilter), const SizedBox(width: 8), viewToggle]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                IconButton(icon: const Icon(Icons.grid_on), onPressed: _exportExcelCurrent, tooltip: 'Exportar Excel'),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: _onNew, icon: const Icon(Icons.add), label: const Text('Nueva'))
            ])
          ])
        : Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              catFilter,
              const SizedBox(width: 12),
              viewToggle,
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.grid_on), onPressed: _exportExcelCurrent, tooltip: 'Exportar Excel'),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _onNew, icon: const Icon(Icons.add), label: const Text('Nueva')),
            ],
          ),
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

    if (items.isEmpty && !_loading) {
      return Column(children: [
        Expanded(child: _EmptyState(
          title: 'Sin subcategorías',
          subtitle: 'Crea tu primera subcategoría o ajusta los filtros.',
          primary: ('Crear nueva', _onNew),
          secondary: ('Quitar filtros', () { setState(() { _idCategoria = null; _search.clear(); }); _resetPages(); _loadCurrent(); }),
        ))
      ]);
    }

    final content = _viewMode == _ViewMode.cards ? _cards(context, items) : _table(context, items);

    return Column(
      children: [
        Expanded(child: content),
        _PaginationControls(
          currentPage: currentPage,
          totalItems: totalItems,
          pageSize: pageSize,
          onPageChange: (p) => _onPageChange(tabIndex, p),
          onPageSizeChange: (s) => _onPageSizeChange(tabIndex, s),
        ),
      ],
    );
  }

  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant.withOpacity(0.4))),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(cs.surfaceContainerHighest.withOpacity(0.5)),
            columns: const [
              DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Subcategoría', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Creado', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: rows.map((r) {
              final bool activo = r['activo'] == true;
              return DataRow(cells: [
                DataCell(Text(r['id']?.toString() ?? '', style: const TextStyle(fontFamily: 'monospace'))),
                DataCell(Text(r['nombre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(r['codigo']?.toString() ?? '')),
                DataCell(Text(_catNameOf(r))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: activo ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(activo ? 'Activa' : 'Inactiva', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: activo ? Colors.green.shade700 : Colors.grey.shade700))
                )),
                DataCell(Text(r['creadoEn']?.toString().split('T').first ?? '')),
                DataCell(_rowActions(r: r, activo: activo, dense: true)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _cards(BuildContext context, List<Map<String, dynamic>> rows) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final r = rows[i];
        final bool activo = r['activo'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: InkWell(
            onTap: () {
               if (widget.embedded && widget.onOpenEstudiantes != null) { widget.onOpenEstudiantes!(r); return; }
               Navigator.pushNamed(context, RouteNames.adminSubcatEstudiantes, arguments: {'idSubcategoria': (r['id'] as num).toInt(), 'nombreSubcategoria': r['nombre'], 'idCategoria': r['idCategoria']});
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'sub_icon_${r['id']}',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.class_rounded, color: Colors.deepPurple.shade400),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['nombre']?.toString() ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.qr_code, size: 14, color: Theme.of(context).hintColor),
                          const SizedBox(width: 4),
                          Text(r['codigo'] ?? '', style: TextStyle(color: Theme.of(context).hintColor)),
                          const SizedBox(width: 12),
                          Icon(Icons.category_outlined, size: 14, color: Theme.of(context).hintColor),
                          const SizedBox(width: 4),
                          Expanded(child: Text(_catNameOf(r), overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).hintColor))),
                        ]),
                      ],
                    ),
                  ),
                  _rowActions(r: r, activo: activo, dense: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== Botonera por fila (AQUÍ ESTÁ LA DEFINICIÓN CORREGIDA) =====
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
            FocusSearchIntent: CallbackAction<FocusSearchIntent>(onInvoke: (_) { _searchFocus.requestFocus(); return null; }),
            NewSubcatIntent: CallbackAction<NewSubcatIntent>(onInvoke: (_) { _onNew(); return null; }),
            ReloadIntent: CallbackAction<ReloadIntent>(onInvoke: (_) { _loadCurrent(); return null; }),
          },
          child: Focus(autofocus: true, child: child),
        ),
      ),
    );
  }
}

// ======================= Widgets de apoyo UI =======================

class _PaginationControls extends StatelessWidget {
  final int currentPage, totalItems, pageSize;
  final void Function(int) onPageChange;
  final void Function(int) onPageSizeChange;
  const _PaginationControls({required this.currentPage, required this.totalItems, required this.pageSize, required this.onPageChange, required this.onPageSizeChange});
  @override
  Widget build(BuildContext context) {
    int totalPages = (totalItems + pageSize - 1) ~/ pageSize;
    if (totalPages < 1) totalPages = 1;
    final int from = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final int to = (currentPage * pageSize) > totalItems ? totalItems : (currentPage * pageSize);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$from-$to de $totalItems', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500)),
        Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: currentPage > 1 ? () => onPageChange(currentPage - 1) : null),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: to < totalItems ? () => onPageChange(currentPage + 1) : null),
        ])
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title, subtitle;
  final (String, VoidCallback) primary;
  final (String, VoidCallback)? secondary;
  const _EmptyState({required this.title, required this.subtitle, required this.primary, this.secondary});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.class_outlined, size: 80, color: Theme.of(context).disabledColor.withOpacity(0.3)), const SizedBox(height: 16), Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 16), Wrap(spacing: 8, children: [FilledButton(onPressed: primary.$2, child: Text(primary.$1)), if (secondary != null) OutlinedButton(onPressed: secondary!.$2, child: Text(secondary!.$1))])]));
  }
}

class _ErrorView extends StatelessWidget {
  final String error; final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 56), const SizedBox(height: 12), Text('Error al cargar', style: Theme.of(context).textTheme.titleLarge), Text(error), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))]));
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();
  @override
  Widget build(BuildContext context) => Chip(avatar: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)), label: const Text('Cargando…'));
}

class _LoadingPlaceholder extends StatelessWidget {
  final bool isNarrow; final _ViewMode viewMode; final bool dense;
  const _LoadingPlaceholder({required this.isNarrow, required this.viewMode, required this.dense});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemCount: 6, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: _Skeleton(height: dense ? 84 : 104)));
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) => Container(height: height, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(12)));
}