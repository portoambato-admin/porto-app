// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async'; // Debouncer búsqueda
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/app_scope.dart';

class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({super.key});

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

// ==== Intents propios para atajos ====
class _FocusSearchIntent extends Intent { const _FocusSearchIntent(); }
class _NewIntent extends Intent { const _NewIntent(); }
class _ReloadIntent extends Intent { const _ReloadIntent(); }

enum _ViewMode { table, cards }

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen>
    with SingleTickerProviderStateMixin {
  // Repo
  dynamic _repo;
  bool _repoReady = false;

  // Estado general
  late final TabController _tab = TabController(length: 3, vsync: this)
    ..addListener(() {
      if (_tab.indexIsChanging) return;
      if (_itemsForTab(_tab.index).isEmpty) _loadCurrent();
    });

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  bool _loading = false;
  String? _error;

  // Preferencias visuales
  _ViewMode _viewMode = _ViewMode.cards;
  bool _dense = false;

  // Paginación por pestaña
  int _actPage = 1, _actPageSize = 10, _actTotal = 0;
  int _inaPage = 1, _inaPageSize = 10, _inaTotal = 0;
  int _allPage = 1, _allPageSize = 10, _allTotal = 0;

  List<Map<String, dynamic>> _actItems = [];
  List<Map<String, dynamic>> _inaItems = [];
  List<Map<String, dynamic>> _allItems = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repoReady) return;
    _repo = AppScope.of(context).categorias;
    _repoReady = true;
    _init();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===== Lógica de Búsqueda y Carga =====
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

  String? get _q {
    final s = _searchCtrl.text.trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _init() async {
    setState(() => _error = null);
    try {
      await _loadData(_tab.index);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadCurrent() async {
    if (_loading) return;
    await _loadData(_tab.index);
  }

  int? _numFromName(String? s) {
    if (s == null) return null;
    final m = RegExp(r'(\d+)').firstMatch(s);
    return (m == null) ? null : int.tryParse(m.group(1)!);
  }

  int _compareCategoria(dynamic a, dynamic b) {
    final sa = (a ?? '').toString();
    final sb = (b ?? '').toString();
    final na = _numFromName(sa);
    final nb = _numFromName(sb);

    if (na != null && nb != null) return na.compareTo(nb);
    if (na != null) return -1;
    if (nb != null) return 1;
    return sa.toLowerCase().compareTo(sb.toLowerCase());
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
      final res = await _repo.paged(
        page: page,
        pageSize: pageSize,
        q: _q,
        sort: 'nombre_categoria',
        order: 'asc',
        onlyActive: onlyActive,
      );

      final items = List<Map<String, dynamic>>.from(res['items'] as List)
        ..sort((a, b) => _compareCategoria(a['nombre'], b['nombre']));

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

  // ===== CRUD =====
  Future<void> _onNew() async {
    final ok = await _openForm();
    if (ok == true) _loadCurrent();
  }

  Future<void> _onEditDialog(Map<String, dynamic> row) async {
    final ok = await _openForm(row: row);
    if (ok == true) _loadCurrent();
  }

  Future<void> _toggleEstado(Map<String, dynamic> r) async {
    final activo = r['activo'] == true;
    try {
      if (activo) {
        await _repo.deactivate((r['id'] as num).toInt());
        _showSnack('Categoría desactivada');
      } else {
        await _repo.activate((r['id'] as num).toInt());
        _showSnack('Categoría activada');
      }
      _actItems.clear(); 
      _inaItems.clear();
      _allItems.clear();
      await _loadCurrent();
    } catch (e) {
      _showSnack('Error: $e');
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
    final edadMin = TextEditingController(text: row?['edadMin']?.toString() ?? '');
    final edadMax = TextEditingController(text: row?['edadMax']?.toString() ?? '');
    bool activa = row?['activo'] == true || row == null;
    bool isSaving = false;
    final cs = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (innerCtx, setInnerState) {
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
                              colors: [Colors.blue.shade800, Colors.blue.shade400],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(innerCtx, false),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          child: Hero(
                            tag: row != null ? 'cat_icon_${row['id']}' : 'new_cat_icon',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                              ),
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(Icons.category_rounded, size: 36, color: Colors.blue.shade700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(row == null ? 'Nueva Categoría' : 'Editar Categoría', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nombre,
                              decoration: _modernInputDeco('Nombre de categoría', Icons.label_outline),
                              maxLength: 60,
                              validator: (v) {
                                final s = v?.trim() ?? '';
                                if (s.isEmpty) return 'Requerido';
                                if (s.length < 3) return 'Muy corto';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: edadMin,
                                    decoration: _modernInputDeco('Edad mínima', Icons.arrow_downward),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: edadMax,
                                    decoration: _modernInputDeco('Edad máxima', Icons.arrow_upward),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Switch Estilizado
                            Container(
                              decoration: BoxDecoration(
                                color: activa ? Colors.green.withOpacity(0.1) : cs.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: activa ? Colors.green.withOpacity(0.3) : cs.outlineVariant)
                              ),
                              child: SwitchListTile(
                                value: activa,
                                onChanged: (v) => setInnerState(() => activa = v),
                                title: Text('Categoría Activa', style: TextStyle(fontWeight: FontWeight.w600, color: activa ? Colors.green.shade700 : cs.onSurface)),
                                secondary: Icon(Icons.check_circle_outline, color: activa ? Colors.green : cs.onSurfaceVariant),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: isSaving ? null : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setInnerState(() => isSaving = true);
                                  try {
                                    if (row == null) {
                                      await _repo.crear(
                                        nombre: nombre.text.trim(),
                                        edadMin: int.tryParse(edadMin.text.trim()),
                                        edadMax: int.tryParse(edadMax.text.trim()),
                                        activa: activa,
                                      );
                                    } else {
                                      await _repo.update(
                                        idCategoria: (row['id'] as num).toInt(),
                                        nombre: nombre.text.trim(),
                                        edadMin: int.tryParse(edadMin.text.trim()),
                                        edadMax: int.tryParse(edadMax.text.trim()),
                                        activa: activa,
                                      );
                                    }
                                    if (mounted) Navigator.pop(innerCtx, true);
                                  } catch (e) {
                                    setInnerState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: cs.error));
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                ),
                                child: isSaving 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(row == null ? 'CREAR CATEGORÍA' : 'GUARDAR CAMBIOS', style: const TextStyle(fontWeight: FontWeight.bold)),
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
        }
      ),
    );
  }

  // ===================== EXPORTACIONES ======================

  Future<void> _showExportOptions() async {
    final sel = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Exportar categorías'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'csv'), child: const ListTile(leading: Icon(Icons.table_rows), title: Text('CSV'))),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'xlsx'), child: const ListTile(leading: Icon(Icons.grid_on), title: Text('Excel (.xlsx)'))),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'pdf'), child: const ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('PDF'))),
        ],
      ),
    );
    if (sel == null) return;
    switch (sel) {
      case 'csv': _exportCsvCurrent(); break;
      case 'xlsx': _exportExcelCurrent(); break;
      case 'pdf': _exportPdfCurrent(); break;
    }
  }

  (List<Map<String, dynamic>> data, String baseName) _currentExportData() {
    final tab = _tab.index;
    final data = tab == 0 ? _actItems : (tab == 1 ? _inaItems : _allItems);
    final name = tab == 0 ? 'categorias_activas' : (tab == 1 ? 'categorias_inactivas' : 'categorias_todas');
    return (data, name);
  }

  Future<void> _saveBytes(Uint8List bytes, String filename, String mimeType, {List<String>? exts}) async {
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
    final String targetPath = '${dir.path}/$filename';
    final xf = XFile.fromData(bytes, name: filename, mimeType: mimeType);
    await xf.saveTo(targetPath);
    _showSnack('Guardado en: $targetPath');
  }

  void _exportCsvCurrent() {
    final (data, base) = _currentExportData();
    final csv = StringBuffer()..writeln('ID,Categoria,EdadMin,EdadMax,Activo,Creado');
    for (final r in data) {
      final id = r['id'] ?? '';
      final nom = _csvEscape(r['nombre']);
      final eMin = r['edadMin']?.toString() ?? '';
      final eMax = r['edadMax']?.toString() ?? '';
      final act = (r['activo'] == true) ? '1' : '0';
      final cre = r['creadoEn']?.toString().split('T').first ?? '';
      csv.writeln('$id,$nom,$eMin,$eMax,$act,$cre');
    }
    final content = csv.toString();
    final bytes = Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF]..addAll(utf8.encode(content))); 
    _saveBytes(bytes, '$base.csv', 'text/csv', exts: const ['csv']);
  }

  static String _csvEscape(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) return '"${s.replaceAll('"', '""')}"';
    return s;
  }

  Future<void> _exportExcelCurrent() async {
    final (data, base) = _currentExportData();
    final book = xls.Excel.createExcel();
    const sheetName = 'Categorias';
    final defaultSheet = book.getDefaultSheet();
    if (defaultSheet != null) book.rename(defaultSheet, sheetName);
    final sheet = book[sheetName];
    sheet.appendRow([xls.TextCellValue('ID'), xls.TextCellValue('Categoría'), xls.TextCellValue('EdadMin'), xls.TextCellValue('EdadMax'), xls.TextCellValue('Activo'), xls.TextCellValue('Creado')]);
    for (final r in data) {
      sheet.appendRow([
        xls.TextCellValue('${r['id'] ?? ''}'), xls.TextCellValue('${r['nombre'] ?? ''}'), xls.TextCellValue('${r['edadMin'] ?? ''}'), xls.TextCellValue('${r['edadMax'] ?? ''}'), xls.TextCellValue(r['activo'] == true ? '1' : '0'), xls.TextCellValue((r['creadoEn']?.toString().split('T').first) ?? '')
      ]);
    }
    final bytes = Uint8List.fromList(book.encode()!);
    await _saveBytes(bytes, '$base.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', exts: const ['xlsx']);
  }
  
  String _two(int n) => n < 10 ? '0$n' : '$n';
  String get _tabLabel {
    switch (_tab.index) {
      case 0: return 'Activas';
      case 1: return 'Inactivas';
      default: return 'Todas';
    }
  }
  pw.Widget _badge(String text) => pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4), margin: const pw.EdgeInsets.only(right: 6), decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF6FF), border: pw.Border.all(color: PdfColor.fromInt(0xFFBFD7FF)), borderRadius: pw.BorderRadius.circular(8)), child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)));
  pw.Widget _hCell(String t) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)));
  pw.Widget _cCell(String t) => pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6), child: pw.Text(t, style: const pw.TextStyle(fontSize: 10)));

  Future<void> _exportPdfCurrent() async {
    final (data, base) = _currentExportData();
    final now = DateTime.now();
    final fecha = '${now.year}-${_two(now.month)}-${_two(now.day)} ${_two(now.hour)}:${_two(now.minute)}';
    final headerBg = PdfColor.fromInt(0xFFEFEFEF);
    final altRowBg = PdfColor.fromInt(0xFFF7F7F7);
    final borderClr = PdfColor.fromInt(0xFFBBBBBB);
    final doc = pw.Document();
    final bodyRows = <pw.TableRow>[];
    for (var i = 0; i < data.length; i++) {
      final r = data[i];
      final isAlt = i.isOdd;
      bodyRows.add(pw.TableRow(decoration: isAlt ? pw.BoxDecoration(color: altRowBg) : null, children: [_cCell('${r['id'] ?? ''}'), _cCell('${r['nombre'] ?? ''}'), _cCell('${r['edadMin'] ?? ''}'), _cCell('${r['edadMax'] ?? ''}'), _cCell((r['activo'] == true) ? 'Sí' : 'No'), _cCell((r['creadoEn']?.toString().split('T').first) ?? '')]));
    }
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape, margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 36),
      footer: (ctx) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Página ${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
      build: (ctx) => [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Reporte de Categorías', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 2), pw.Text('Academia de Fútbol PortoAmbato', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700))])), pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text('Exportado: $fecha', style: const pw.TextStyle(fontSize: 10)), pw.Text('Vista: $_tabLabel', style: const pw.TextStyle(fontSize: 10))])]),
        pw.SizedBox(height: 8),
        if (_q != null && _q!.isNotEmpty) pw.Row(children: [_badge('Búsqueda: "${_q!}"')]),
        if (_q != null && _q!.isNotEmpty) pw.SizedBox(height: 8),
        pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: borderClr, width: 0.5), borderRadius: pw.BorderRadius.circular(6)), child: pw.Table(border: pw.TableBorder(left: pw.BorderSide(color: borderClr, width: 0.5), right: pw.BorderSide(color: borderClr, width: 0.5), horizontalInside: pw.BorderSide(color: borderClr, width: 0.5)), columnWidths: <int, pw.TableColumnWidth>{0: const pw.FixedColumnWidth(40), 1: const pw.FlexColumnWidth(3), 2: const pw.FixedColumnWidth(45), 3: const pw.FixedColumnWidth(45), 4: const pw.FixedColumnWidth(45), 5: const pw.FixedColumnWidth(80)}, children: [pw.TableRow(decoration: pw.BoxDecoration(color: headerBg), children: [_hCell('ID'), _hCell('Categoría'), _hCell('EdadMin'), _hCell('EdadMax'), _hCell('Activo'), _hCell('Creado')]), ...bodyRows])),
        pw.SizedBox(height: 8),
        pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Total: ${data.length}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
      ],
    ));
    final bytes = await doc.save();
    await _saveBytes(bytes, '$base.pdf', 'application/pdf', exts: const ['pdf']);
  }

  void _showSnack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  // ===== Paginación (Corrección: Métodos dentro de la clase) =====
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

  // ====================================================================
  // ============================ BUILD =================================
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    final isFirstLoad = _loading && _actItems.isEmpty && _inaItems.isEmpty && _allItems.isEmpty;

    final core = LayoutBuilder(
      builder: (ctx, c) {
        final isNarrow = c.maxWidth < 820;
        const double maxContentWidth = 1200;
        final double width = c.maxWidth > maxContentWidth ? maxContentWidth : c.maxWidth;

        final header = _buildModernHeader(context);

        final tabs = TabBar(
          controller: _tab,
          isScrollable: isNarrow,
          tabs: [
            Tab(text: 'Activas (${_actTotal})'),
            Tab(text: 'Inactivas (${_inaTotal})'),
            Tab(text: 'Todas (${_allTotal})'),
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
                      AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: content),
                      if (_loading && !isFirstLoad)
                        const Positioned(right: 12, top: 8, child: _LoadingChip()),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: Padding(padding: const EdgeInsets.all(12), child: core),
    );
  }

  // ===== Header alineado al formato =====
  Widget _buildModernHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre…',
                prefixIcon: Icon(Icons.search, color: cs.primary),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchCtrl.clear(); _loadCurrent(); }) : null,
              ),
              onChanged: (_) => _onSearchChanged(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.grid_view_rounded, color: _viewMode == _ViewMode.cards ? cs.primary : cs.onSurfaceVariant), onPressed: () => setState(() => _viewMode = _ViewMode.cards)),
                Container(width: 1, height: 20, color: cs.outlineVariant),
                IconButton(icon: Icon(Icons.table_rows_rounded, color: _viewMode == _ViewMode.table ? cs.primary : cs.onSurfaceVariant), onPressed: () => setState(() => _viewMode = _ViewMode.table)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(tooltip: 'Exportar', icon: const Icon(Icons.download_rounded), onPressed: _showExportOptions),
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
      return Column(
        children: [
          Expanded(
            child: _EmptyState(
              title: 'Sin categorías',
              subtitle: 'Crea tu primera categoría o ajusta la búsqueda.',
              primary: ('Crear nueva', _onNew),
              secondary: ('Quitar filtros', () {
                setState(() { _searchCtrl.clear(); });
                _resetPages();
                _loadCurrent();
              }),
            ),
          ),
        ],
      );
    }

    final content = _viewMode == _ViewMode.cards
        ? _cards(context, items)
        : _table(context, items);

    return Column(
      children: [
        Expanded(child: content),
        _PaginationControls(
          currentPage: currentPage,
          totalItems: totalItems,
          pageSize: pageSize,
          onPageChange: (newPage) => _onPageChange(tabIndex, newPage),
          onPageSizeChange: (newSize) => _onPageSizeChange(tabIndex, newSize),
        ),
      ],
    );
  }

  Widget _th(String s) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(s));

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
            columns: [
              DataColumn(label: _th('ID')),
              DataColumn(label: _th('Categoría')),
              DataColumn(label: _th('Edad')),
              DataColumn(label: _th('Estado')),
              DataColumn(label: _th('Creado')),
              DataColumn(label: _th('Acciones')),
            ],
            rows: rows.map((r) {
              final bool activo = r['activo'] == true;
              final String edades = [r['edadMin']?.toString(), r['edadMax']?.toString()].where((e) => (e != null && e.isNotEmpty)).join(' - ');
              return DataRow(cells: [
                DataCell(Text(r['id']?.toString() ?? '', style: const TextStyle(fontFamily: 'monospace'))),
                DataCell(Text(r['nombre']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(edades.isEmpty ? '—' : edades)),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: activo ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(activo ? 'Activa' : 'Inactiva', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: activo ? Colors.green.shade700 : Colors.grey.shade700))
                )),
                DataCell(Text(r['creadoEn']?.toString().split('T').first ?? '')),
                DataCell(_rowActions(r: r, activo: activo, dense: _dense)),
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
        final String edades = [r['edadMin']?.toString(), r['edadMax']?.toString()].where((e) => (e != null && e.isNotEmpty)).join(' - ');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'cat_icon_${r['id']}',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.category_rounded, color: Colors.blue.shade700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['nombre']?.toString() ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(edades.isEmpty ? 'Sin rango' : 'Edad: $edades', style: TextStyle(color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
                _rowActions(r: r, activo: activo, dense: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rowActions({required Map<String, dynamic> r, required bool activo, bool dense = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _onEditDialog(r)),
        IconButton(
          icon: Icon(activo ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          color: activo ? Colors.grey : Colors.green,
          onPressed: () => _toggleEstado(r),
        ),
      ],
    );
  }

  Widget _withShortcuts(Widget child) {
    return FocusTraversalGroup(
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _FocusSearchIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _NewIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const _ReloadIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(onInvoke: (_) { _searchFocus.requestFocus(); return null; }),
            _NewIntent: CallbackAction<_NewIntent>(onInvoke: (_) { _onNew(); return null; }),
            _ReloadIntent: CallbackAction<_ReloadIntent>(onInvoke: (_) { _loadCurrent(); return null; }),
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
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.category_outlined, size: 80, color: Theme.of(context).disabledColor.withOpacity(0.3)), const SizedBox(height: 16), Text(title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(subtitle, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 16), Wrap(spacing: 8, children: [FilledButton(onPressed: primary.$2, child: Text(primary.$1)), if (secondary != null) OutlinedButton(onPressed: secondary!.$2, child: Text(secondary!.$1))])]));
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