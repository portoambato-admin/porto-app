import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:characters/characters.dart'; // para .characters

import '../../../app/app_scope.dart';
import 'crear_estudiante_matricula_screen.dart';

// === Export helpers (multiplataforma) ===
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminEstudiantesScreen extends StatefulWidget {
  const AdminEstudiantesScreen({super.key});
  @override
  State<AdminEstudiantesScreen> createState() => _AdminEstudiantesScreenState();
}

// ==== Atajos (Ctrl+F / Ctrl+N / Ctrl+R) ====
class _FocusSearchIntent extends Intent { const _FocusSearchIntent(); }
class _NewIntent extends Intent { const _NewIntent(); }
class _ReloadIntent extends Intent { const _ReloadIntent(); }

enum _ViewMode { table, cards }

class _AdminEstudiantesScreenState extends State<AdminEstudiantesScreen> {
  // Repo
  late final _repo = AppScope.of(context).estudiantes;

  // Estado base
  bool _loading = false;
  String? _error;

  // ===== Filtros (NO se modifican) =====
  final _q = TextEditingController();
  int? _catId;
  bool? _onlyActive;

  // Datos + paginación (server-side)
  List<Map<String, dynamic>> _rows = [];
  int _total = 0, _page = 1, _pageSize = 20;

  // Preferencias visuales (solo UI)
  _ViewMode _viewMode = _ViewMode.cards; // 👉 por defecto: Tarjetas
  bool _dense = false;

  // Focus para Ctrl+F
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _q.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _repo.paged(
        page: _page,
        pageSize: _pageSize,
        q: _q.text.trim().isEmpty ? null : _q.text.trim(),
        categoriaId: _catId,
        onlyActive: _onlyActive,
      );
      setState(() {
        _rows = List<Map<String, dynamic>>.from(res['items']);
        _total = (res['total'] as num).toInt();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit({required Map<String, dynamic> row}) async {
    final formKey = GlobalKey<FormState>();
    final nombres   = TextEditingController(text: row['nombres'] ?? '');
    final apellidos = TextEditingController(text: row['apellidos'] ?? '');
    final fecha     = TextEditingController(text: row['fechaNacimiento'] ?? '');
    final direccion = TextEditingController(text: row['direccion'] ?? '');
    final telefono  = TextEditingController(text: row['telefono'] ?? '');
    int? idAcademia = row['idAcademia'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar estudiante'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombres,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: apellidos,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: fecha,
                  decoration: const InputDecoration(labelText: 'Fecha nacimiento (YYYY-MM-DD, opcional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: telefono,
                  decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: direccion,
                  decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: idAcademia?.toString() ?? '1',
                  decoration: const InputDecoration(labelText: 'ID Academia'),
                  onChanged: (v) => idAcademia = int.tryParse(v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await _repo.update(
                  idEstudiante: (row['id'] as num).toInt(),
                  nombres: nombres.text.trim(),
                  apellidos: apellidos.text.trim(),
                  fechaNacimiento: fecha.text.trim().isEmpty ? null : fecha.text.trim(),
                  direccion: direccion.text.trim().isEmpty ? null : direccion.text.trim(),
                  telefono: telefono.text.trim().isEmpty ? null : telefono.text.trim(),
                  idAcademia: idAcademia,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estudiante actualizado')));
                Navigator.pop(context, true);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok == true) _load();
  }

  Future<void> _toggleEstado(Map<String, dynamic> r) async {
    final activo = r['activo'] == true;
    final id = (r['id'] as num).toInt();
    try {
      if (activo) {
        await _repo.deactivate(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estudiante desactivado')));
      } else {
        await _repo.activate(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estudiante activado')));
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ======== EXPORT (página actual) ========
  // CSV helpers
  static String _csvEsc(Object? v) {
    final s = v?.toString() ?? '';
    return (s.contains(',') || s.contains('"') || s.contains('\n'))
        ? '"${s.replaceAll('"', '""')}"'
        : s;
  }

  String _csvFrom(List<Map<String, dynamic>> rows) {
    final buf = StringBuffer()..writeln('ID,Estudiante,Categoría,Teléfono,Estado,Creado');
    for (final r in rows) {
      final id  = r['id'] ?? '';
      final est = _csvEsc('${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}'.trim());
      final cat = _csvEsc(r['categoriaNombre']);
      final tel = _csvEsc(r['telefono']);
      final estd = (r['activo'] == true) ? 'Activo' : 'Inactivo';
      final cre = r['creadoEn']?.toString().split('T').first ?? '';
      buf.writeln('$id,$est,$cat,$tel,$estd,$cre');
    }
    return buf.toString();
  }

  // file_selector
  Future<String?> _pickSavePath({
    required String suggestedName,
    required List<String> extensions,
    String? label,
    List<String>? mimeTypes,
  }) async {
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
      final path = await _pickSavePath(
        suggestedName: defaultFileName,
        extensions: extensions,
        mimeTypes: mimeType == null ? null : [mimeType],
      );
      if (path == null) return; // cancelado
      final xf = XFile.fromData(bytes, name: defaultFileName, mimeType: mimeType);
      await xf.saveTo(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo guardado en: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  Future<void> _exportCsv() async {
    final content = _csvFrom(_rows); // 👉 página actual
    await _saveBytes(
      Uint8List.fromList(utf8.encode(content)),
      defaultFileName: 'estudiantes_page$_page.csv',
      extensions: ['csv'],
      mimeType: 'text/csv',
    );
  }

  // Excel
  xls.CellValue _cv(dynamic v) {
    if (v == null) return  xls.TextCellValue('');
    if (v is bool) return xls.BoolCellValue(v);
    if (v is int)  return xls.IntCellValue(v);
    if (v is double) return xls.DoubleCellValue(v);
    return xls.TextCellValue('$v');
  }

  Uint8List _excelBytes(List<Map<String, dynamic>> rows) {
    final book = xls.Excel.createExcel();
    final sheet = book['Estudiantes'];
    sheet.appendRow([
      xls.TextCellValue('ID'),
      xls.TextCellValue('Estudiante'),
      xls.TextCellValue('Categoría'),
      xls.TextCellValue('Teléfono'),
      xls.TextCellValue('Estado'),
      xls.TextCellValue('Creado'),
    ]);
    for (final r in rows) {
      final nombre = ('${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}').trim();
      sheet.appendRow([
        _cv(r['id']),
        _cv(nombre),
        _cv(r['categoriaNombre'] ?? '—'),
        _cv(r['telefono'] ?? '—'),
        _cv(r['activo'] == true ? 'Activo' : 'Inactivo'),
        _cv(r['creadoEn']?.toString().split('T').first ?? ''),
      ]);
    }
    return Uint8List.fromList(book.encode()!);
  }

  Future<void> _exportExcel() async {
    await _saveBytes(
      _excelBytes(_rows), // 👉 página actual
      defaultFileName: 'estudiantes_page$_page.xlsx',
      extensions: ['xlsx'],
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // PDF
  Future<Uint8List> _pdfBytes(List<Map<String, dynamic>> rows) async {
    final doc = pw.Document();
    final headers = ['ID','Estudiante','Categoría','Teléfono','Estado','Creado'];
    final data = [
      for (final r in rows)
        [
          '${r['id'] ?? ''}',
          ('${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}').trim(),
          '${r['categoriaNombre'] ?? '—'}',
          '${r['telefono'] ?? '—'}',
          (r['activo']==true) ? 'Activo' : 'Inactivo',
          r['creadoEn']?.toString().split('T').first ?? '',
        ]
    ];

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        header: (ctx) => pw.Text(
          'Estudiantes — Página $_page',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(width: 0.2),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _exportPdf() async {
    final bytes = await _pdfBytes(_rows); // 👉 página actual
    await _saveBytes(
      bytes,
      defaultFileName: 'estudiantes_page$_page.pdf',
      extensions: ['pdf'],
      mimeType: 'application/pdf',
    );
  }

  Future<void> _previewPdf() async {
    final bytes = await _pdfBytes(_rows); // 👉 página actual
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // ======= BUILD =======
  @override
  Widget build(BuildContext context) {
    final isFirstLoad = _loading && _rows.isEmpty;

    final core = LayoutBuilder(
      builder: (_, c) {
        final isNarrow = c.maxWidth < 820;

        // ====== Header con chips + Acciones (Exportar / Nuevo) ======
        final headerRow = Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: LayoutBuilder(
            builder: (_, cc) {
              final compact = cc.maxWidth < 720;

              final chips = Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Vista
                  InputChip(
                    label: Text(_viewMode == _ViewMode.table ? 'Tabla' : 'Tarjetas'),
                    avatar: Icon(_viewMode == _ViewMode.table ? Icons.table_chart : Icons.view_agenda, size: 18),
                    onPressed: () => setState(() {
                      _viewMode = _viewMode == _ViewMode.table ? _ViewMode.cards : _ViewMode.table;
                    }),
                  ),
                  // Densidad
                  InputChip(
                    label: Text(_dense ? 'Denso' : 'Cómodo'),
                    avatar: Icon(_dense ? Icons.compress : Icons.unfold_more, size: 18),
                    onPressed: () => setState(() => _dense = !_dense),
                  ),
                  // Filtros activos (informativos)
                  if (_q.text.trim().isNotEmpty)
                    InputChip(
                      avatar: const Icon(Icons.search, size: 18),
                      label: Text('Búsqueda: "${_q.text.trim()}"'),
                      onDeleted: () { _q.clear(); _page = 1; _load(); },
                    ),
                  if (_catId != null)
                    InputChip(
                      avatar: const Icon(Icons.category, size: 18),
                      label: Text('Categoría: $_catId'),
                      onDeleted: () { setState(() { _catId = null; _page = 1; }); _load(); },
                    ),
                  if (_onlyActive != null)
                    InputChip(
                      avatar: const Icon(Icons.filter_alt, size: 18),
                      label: Text(_onlyActive == true ? 'Estado: Activos' : 'Estado: Inactivos'),
                      onDeleted: () { setState(() { _onlyActive = null; _page = 1; }); _load(); },
                    ),
                ],
              );

              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // === Menú Exportar (página actual) ===
                  PopupMenuButton<String>(
  tooltip: 'Exportar',
  onSelected: (v) async {
    switch (v) {
      case 'csv':  await _exportCsv(); break;
      case 'xlsx': await _exportExcel(); break;
      case 'pdf':  await _exportPdf(); break;
      case 'preview': await _previewPdf(); break;
    }
  },
  itemBuilder: (ctx) => const [
    PopupMenuItem(value: 'csv',    child: ListTile(leading: Icon(Icons.file_download), title: Text('CSV (página)'))),
    PopupMenuItem(value: 'xlsx',   child: ListTile(leading: Icon(Icons.grid_on),       title: Text('Excel (página)'))),
    PopupMenuItem(value: 'pdf',    child: ListTile(leading: Icon(Icons.picture_as_pdf),title: Text('PDF (página)'))),
    PopupMenuItem(value: 'preview',child: ListTile(leading: Icon(Icons.print),         title: Text('Vista previa PDF'))),
  ],
  // 👇 Este wrapper evita que el hijo consuma el tap,
  //    pero mantiene el look "habilitado"
  child: IgnorePointer(
    ignoring: true,
    child: OutlinedButton.icon(
      onPressed: () {}, // solo para que se vea habilitado
      icon: const Icon(Icons.download),
      label: const Text('Exportar'),
    ),
  ),
)
,
                  FilledButton.icon(
                    onPressed: () async {
                      final created = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CrearEstudianteMatriculaScreen()),
                      );
                      if (created == true) _load();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo'),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    chips,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: chips),
                  actions,
                ],
              );
            },
          ),
        );

        final content = isFirstLoad
            ? _LoadingPlaceholder(isNarrow: isNarrow, viewMode: _viewMode, dense: _dense)
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : (_rows.isEmpty
                    ? const _EmptyState(
                        title: 'Sin estudiantes',
                        subtitle: 'Ajusta los filtros o crea un nuevo estudiante.',
                        primary: ('Refrescar', null),
                      )
                    : (_viewMode == _ViewMode.cards
                        ? _cards(context, _rows)
                        : _table(context, _rows)));

        return Column(
          children: [
            _toolbar(),     // ❗️Filtros intactos
            headerRow,      // Acciones y chips
            Expanded(
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: content,
                  ),
                  if (_loading && !isFirstLoad)
                    const Positioned(right: 12, top: 8, child: _LoadingChip()),
                ],
              ),
            ),
            // --- Solo info de página, sin paginador ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(alignment: Alignment.centerLeft, child: _pageInfoText()),
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ❌ Quitamos FAB; ya hay botón azul en el header
      body: _withShortcuts(core),
    );
  }

  // ====== Info “Mostrando X–Y de Z” ======
  Widget _pageInfoText() {
    final from = _total == 0 ? 0 : ((_page - 1) * _pageSize) + 1;
    final to = _total == 0 ? 0 : ((_page - 1) * _pageSize) + _rows.length;
    return Text('Mostrando $from–$to de $_total');
  }

  // ====== Vista TABLA ======
  Widget _table(BuildContext context, List<Map<String, dynamic>> rows) {
  final textStyle = _dense
      ? Theme.of(context).textTheme.bodySmall
      : Theme.of(context).textTheme.bodyMedium;

  String fullName(Map r) =>
      ('${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  return ScrollConfiguration(
    behavior: const ScrollBehavior().copyWith(scrollbars: true),
    child: LayoutBuilder(
      builder: (ctx, constraints) {
        // Scroll vertical exterior + scroll horizontal interior
        return SingleChildScrollView(
          // deja espacio para que no se solape con el footer
          padding: const EdgeInsets.only(bottom: 80),
          physics: const AlwaysScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // asegura que como mínimo ocupe el ancho disponible
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: _dense ? 36 : 48,
                dataRowMinHeight: _dense ? 32 : 44,
                dataRowMaxHeight: _dense ? 40 : null,
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Estudiante')),
                  DataColumn(label: Text('Categoría')),
                  DataColumn(label: Text('Teléfono')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Creado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: rows.map((r) {
                  final bool activo = r['activo'] == true;
                  final estadoIcon = Icon(
                    activo ? Icons.check_circle : Icons.cancel,
                    color: activo ? Colors.green : Colors.grey,
                    size: _dense ? 18 : 20,
                    semanticLabel: activo ? 'Activo' : 'Inactivo',
                  );
                  return DataRow(cells: [
                    DataCell(SelectableText(r['id']?.toString() ?? '', style: textStyle)),
                    DataCell(SelectableText(fullName(r), style: textStyle)),
                    DataCell(SelectableText(r['categoriaNombre']?.toString() ?? '—', style: textStyle)),
                    DataCell(SelectableText(r['telefono']?.toString() ?? '—', style: textStyle)),
                    DataCell(estadoIcon),
                    DataCell(SelectableText(r['creadoEn']?.toString().split('T').first ?? '', style: textStyle)),
                    DataCell(_rowActions(r: r, activo: activo, dense: _dense)),
                  ]);
                }).toList(),
              ),
            ),
          ),
        );
      },
    ),
  );
}

  // ====== Vista TARJETAS (compacta y estética) ======
  Widget _cards(BuildContext context, List<Map<String, dynamic>> rows) {
    final compactPad = EdgeInsets.symmetric(horizontal: 12, vertical: _dense ? 4 : 6);

    String fullName(Map r) =>
        ('${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    Widget miniChip(BuildContext ctx, String text, IconData icon) {
      final theme = Theme.of(ctx);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(text, style: theme.textTheme.labelSmall),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final r = rows[i];
        final activo = r['activo'] == true;
        final nombre = fullName(r);
        final cat = r['categoriaNombre']?.toString() ?? '—';
        final tel = r['telefono']?.toString() ?? '—';
        final creado = r['creadoEn']?.toString().split('T').first ?? '—';
        final initials = _initials(r['nombres'], r['apellidos']);
        final avatarColor = _avatarColor('$nombre$cat');

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            dense: true,
            contentPadding: compactPad,
            onTap: () => Navigator.pushNamed(
              context,
              '/admin/estudiantes/detalle',
              arguments: {'id': (r['id'] as num).toInt()},
            ),
            leading: CircleAvatar(
              radius: _dense ? 14 : 16,
              backgroundColor: avatarColor.withOpacity(0.15),
              child: Text(
                initials,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: avatarColor,
                    ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    nombre.isEmpty ? 'Sin nombre' : nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  activo ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: activo ? Colors.green : Colors.grey,
                  semanticLabel: activo ? 'Activo' : 'Inactivo',
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  miniChip(context, cat, Icons.category),
                  if (tel.trim().isNotEmpty && tel != '—')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call, size: 14),
                        const SizedBox(width: 3),
                        Text(tel, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 14),
                      const SizedBox(width: 3),
                      Text(creado, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            // acciones compactas a la derecha
            trailing: _rowActions(r: r, activo: activo, dense: true),
          ),
        );
      },
    );
  }

  Widget _kv(BuildContext ctx, String label, String value, {IconData? icon}) {
    final styleLabel = Theme.of(ctx).textTheme.bodySmall;
    final styleValue = Theme.of(ctx).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          SizedBox(width: 90, child: Text(label, style: styleLabel)),
          Expanded(child: Text(value, style: styleValue, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ===== Acciones por fila =====
  Widget _rowActions({required Map<String, dynamic> r, required bool activo, bool dense = false}) {
    final double iconSize = dense ? 18 : 24;
    final EdgeInsets padding = EdgeInsets.all(dense ? 4 : 8);
    final BoxConstraints? k = dense ? const BoxConstraints(minWidth: 36, minHeight: 36) : null;
    final VisualDensity vd = dense ? VisualDensity.compact : VisualDensity.standard;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Editar',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            constraints: k,
            visualDensity: vd,
            icon: const Icon(Icons.edit),
            onPressed: () => _edit(row: r),
          ),
        ),
        Tooltip(
          message: activo ? 'Desactivar' : 'Activar',
          child: IconButton(
            iconSize: iconSize,
            padding: padding,
            constraints: k,
            visualDensity: vd,
            icon: Icon(activo ? Icons.visibility_off : Icons.visibility),
            onPressed: () => _toggleEstado(r),
          ),
        ),
      ],
    );
  }

  // ====== Filtros (intactos, sin cambios) ======
  Widget _toolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final search = Expanded(
            child: TextField(
              controller: _q,
              focusNode: _searchFocus, // para Ctrl+F
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nombre…'),
              onSubmitted: (_) { _page = 1; _load(); },
            ),
          );

          final catDropdown = FutureBuilder<List<Map<String, dynamic>>>(
            future: AppScope.of(context).categorias.simpleList(),
            builder: (_, snap) {
              final list = snap.data ?? const <Map<String, dynamic>>[];
              return SizedBox(
                width: 260,
                child: DropdownButtonFormField<int>(
                  value: _catId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category)),
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Todas')),
                    ...list.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['nombre'] as String),
                        )),
                  ],
                  onChanged: (v) { setState(() { _catId = v; _page = 1; }); _load(); },
                ),
              );
            },
          );

          final estado = SizedBox(
            width: 220,
            child: DropdownButtonFormField<bool>(
              value: _onlyActive,
              decoration: const InputDecoration(labelText: 'Estado', prefixIcon: Icon(Icons.filter_alt)),
              items: const [
                DropdownMenuItem<bool>(value: null, child: Text('Todos')),
                DropdownMenuItem<bool>(value: true, child: Text('Activos')),
                DropdownMenuItem<bool>(value: false, child: Text('Inactivos')),
              ],
              onChanged: (v) { setState(() { _onlyActive = v; _page = 1; }); _load(); },
            ),
          );

          final perPage = SizedBox(
            width: 140,
            child: DropdownButtonFormField<int>(
              value: _pageSize,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.format_list_numbered), labelText: 'Por página'),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (v) { if (v != null) { setState(() { _pageSize = v; _page = 1; }); _load(); } },
            ),
          );

          final narrow = c.maxWidth < 900;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 8), catDropdown, const SizedBox(height: 8), estado, const SizedBox(height: 8), perPage],
            );
          }
          return Row(children: [search, const SizedBox(width: 8), catDropdown, const SizedBox(width: 8), estado, const SizedBox(width: 8), perPage]);
        },
      ),
    );
  }

  // ====== Atajos ======
  Widget _withShortcuts(Widget child) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _NewIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const _ReloadIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) { _searchFocus.requestFocus(); return null; },
          ),
          _NewIntent: CallbackAction<_NewIntent>(
            onInvoke: (_) async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrearEstudianteMatriculaScreen()),
              );
              if (created == true) _load();
              return null;
            },
          ),
          _ReloadIntent: CallbackAction<_ReloadIntent>(
            onInvoke: (_) { _load(); return null; },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  // ===== Helpers para tarjetas =====
  String _initials(String? nombres, String? apellidos) {
    final n = (nombres ?? '').trim().split(' ').where((e) => e.isNotEmpty).toList();
    final a = (apellidos ?? '').trim().split(' ').where((e) => e.isNotEmpty).toList();
    final i1 = n.isNotEmpty ? n.first.characters.first : '';
    final i2 = a.isNotEmpty ? a.first.characters.first : '';
    final r = (i1 + i2).toUpperCase();
    return r.isEmpty ? '👤' : r;
  }

  Color _avatarColor(String seed) {
    final h = seed.hashCode & 0xFFFFFF;
    return Color(0xFF000000 | h).withOpacity(1);
  }
}

// ======================= Widgets de apoyo UI =======================

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final (String, VoidCallback?) primary;
  final (String, VoidCallback)? secondary;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.primary,
    // ignore: unused_element_parameter
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
          mainAxisSize: MainAxisSize.min,
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
  const _LoadingChip({super.key});

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

  const _LoadingPlaceholder({super.key, required this.isNarrow, required this.viewMode, required this.dense});

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
  const _Skeleton({super.key, required this.height});

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
