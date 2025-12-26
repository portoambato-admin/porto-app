import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/app_roles.dart';
import '../../../app/app_scope.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/state/auth_state.dart';

import 'crear_estudiante_matricula_screen.dart';

class AdminEstudiantesScreen extends StatefulWidget {
  const AdminEstudiantesScreen({super.key});
  @override
  State<AdminEstudiantesScreen> createState() => _AdminEstudiantesScreenState();
}

// ==== Atajos ====
class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _ReloadIntent extends Intent {
  const _ReloadIntent();
}

enum _ViewMode { table, cards }

class _AdminEstudiantesScreenState extends State<AdminEstudiantesScreen> {
  // Repo
  late final _repo = AppScope.of(context).estudiantes;
  late final _catRepo = AppScope.of(context).categorias;

  // Estado base
  bool _loading = false;
  String? _error;

  // Filtros
  final _q = TextEditingController();
  int? _catId;
  bool? _onlyActive = true;
  List<Map<String, dynamic>> _catOptions = [];

  // Paginación y Datos
  List<Map<String, dynamic>> _rows = [];
  int _total = 0, _page = 1, _pageSize = 20;

  // Selección múltiple
  final Set<int> _selected = {};

  // UI
  _ViewMode _viewMode = _ViewMode.cards;
  bool _dense = false;
  final _searchFocus = FocusNode();
  Timer? _debounce;

  bool get _isAdmin {
    final role = AuthScope.of(context).role;
    return role == AppRoles.admin;
  }

  @override
  void initState() {
    super.initState();
    _loadCats();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _q.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCats() async {
    try {
      final list = await _catRepo.simpleList();
      if (mounted) {
        setState(() => _catOptions = List<Map<String, dynamic>>.from(list));
      }
    } catch (_) {}
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _page = 1;
      _load();
    });
  }

  int _idOf(Map<String, dynamic> r) {
    final v = r['id'] ?? r['id_estudiante'];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? -1;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
        _selected.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- NAVEGACIÓN AL DETALLE (según rol) ---
  void _openDetail(int id) {
    final role = AuthScope.of(context).role;
    final route =
        (role == AppRoles.profesor) ? RouteNames.profesorEstudianteDetalle : RouteNames.adminEstudianteDetalle;

    Navigator.pushNamed(
      context,
      route,
      arguments: {'id': id},
    );
  }

  // ================= EXPORTACIÓN (CSV + EXCEL + PDF) =================

  List<Map<String, dynamic>> get _dataToExport {
    if (_selected.isEmpty) return _rows;
    return _rows.where((r) => _selected.contains(_idOf(r))).toList();
  }

  Future<void> _saveBytes(Uint8List bytes, String name, String mime) async {
    try {
      final loc = await getSaveLocation(suggestedName: name);
      if (loc != null) {
        final xf = XFile.fromData(bytes, name: name, mimeType: mime);
        await xf.saveTo(loc.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Guardado en ${loc.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    final data = _dataToExport;
    final buf = StringBuffer()
      ..writeln(
          'ID,Nombres,Apellidos,Cedula,Telefono,Categoria,Subcategoria,Estado,Creado');

    String csvEsc(dynamic v) {
      final s = v?.toString() ?? '';
      if (s.contains(',') || s.contains('"') || s.contains('\n')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    for (final r in data) {
      buf.writeln([
        _idOf(r),
        csvEsc(r['nombres']),
        csvEsc(r['apellidos']),
        csvEsc(r['cedula']),
        csvEsc(r['telefono']),
        csvEsc(r['categoriaNombre']),
        csvEsc(r['subcategoriaNombre']),
        r['activo'] == true ? 'Activo' : 'Inactivo',
        r['creadoEn']?.toString().split('T').first ?? ''
      ].join(','));
    }

    await _saveBytes(
      Uint8List.fromList(utf8.encode(buf.toString())),
      'estudiantes_export.csv',
      'text/csv',
    );
  }

  Future<void> _exportExcel() async {
    final data = _dataToExport;
    final book = xls.Excel.createExcel();
    final sheet = book['Estudiantes'];

    sheet.appendRow([
      xls.TextCellValue('ID'),
      xls.TextCellValue('Nombres'),
      xls.TextCellValue('Apellidos'),
      xls.TextCellValue('Cédula'),
      xls.TextCellValue('Teléfono'),
      xls.TextCellValue('Categoría'),
      xls.TextCellValue('Subcategoría'),
      xls.TextCellValue('Estado'),
    ]);

    for (final r in data) {
      sheet.appendRow([
        xls.TextCellValue('${_idOf(r)}'),
        xls.TextCellValue('${r['nombres'] ?? ''}'),
        xls.TextCellValue('${r['apellidos'] ?? ''}'),
        xls.TextCellValue('${r['cedula'] ?? ''}'),
        xls.TextCellValue('${r['telefono'] ?? ''}'),
        xls.TextCellValue('${r['categoriaNombre'] ?? ''}'),
        xls.TextCellValue('${r['subcategoriaNombre'] ?? ''}'),
        xls.TextCellValue(r['activo'] == true ? 'Activo' : 'Inactivo'),
      ]);
    }

    await _saveBytes(
      Uint8List.fromList(book.encode()!),
      'estudiantes_export.xlsx',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> _exportPdf() async {
    final data = _dataToExport;
    final doc = pw.Document();

    final tableData = [
      ['ID', 'Nombre', 'Cédula', 'Subcategoría', 'Estado'],
      ...data.map((r) => [
            '${_idOf(r)}',
            '${r['nombres'] ?? ''} ${r['apellidos'] ?? ''}',
            '${r['cedula'] ?? '-'}',
            '${r['subcategoriaNombre'] ?? '-'}',
            r['activo'] == true ? 'Activo' : 'Inactivo'
          ])
    ];

    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Reporte de Estudiantes')),
          pw.Table.fromTextArray(
            headers: tableData.first,
            data: tableData.sublist(1),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    await _saveBytes(
      await doc.save(),
      'estudiantes_export.pdf',
      'application/pdf',
    );
  }

  Future<void> _showExportMenu() async {
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Exportar datos'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'csv'),
            child: const ListTile(
              leading: Icon(Icons.table_rows, color: Colors.blue),
              title: Text('CSV (.csv)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'excel'),
            child: const ListTile(
              leading: Icon(Icons.grid_on, color: Colors.green),
              title: Text('Excel (.xlsx)'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'pdf'),
            child: const ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('PDF (.pdf)'),
            ),
          ),
        ],
      ),
    );

    if (option == 'csv') _exportCsv();
    if (option == 'excel') _exportExcel();
    if (option == 'pdf') _exportPdf();
  }

  // ================= DIÁLOGO EDICIÓN (solo Admin) =================
  Future<void> _edit({required Map<String, dynamic> row}) async {
    if (!_isAdmin) return;

    final formKey = GlobalKey<FormState>();
    final nombres = TextEditingController(text: row['nombres'] ?? '');
    final apellidos = TextEditingController(text: row['apellidos'] ?? '');
    final fecha = TextEditingController(text: row['fechaNacimiento'] ?? '');
    final direccion = TextEditingController(text: row['direccion'] ?? '');
    final telefono = TextEditingController(text: row['telefono'] ?? '');
    int? idAcademia = row['idAcademia'] ?? 1;

    InputDecoration blueDeco(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue.shade800),
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.5),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.transparent)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade800, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade300)),
      );
    }

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
        firstDate: DateTime(1990),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: Colors.blue.shade800),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        fecha.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 10,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Gradiente
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade900, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'est_avatar_${row['id']}',
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Editar Estudiante',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nombres,
                          decoration: blueDeco('Nombres', Icons.badge_outlined),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: apellidos,
                          decoration:
                              blueDeco('Apellidos', Icons.person_outline),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: telefono,
                                decoration:
                                    blueDeco('Teléfono', Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: fecha,
                                readOnly: true,
                                onTap: pickDate,
                                decoration: blueDeco(
                                    'Nacimiento', Icons.calendar_month_outlined),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: direccion,
                          decoration:
                              blueDeco('Dirección', Icons.location_on_outlined),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: idAcademia.toString(),
                          decoration: blueDeco('ID Academia', Icons.school_outlined),
                          keyboardType: TextInputType.number,
                          onChanged: (v) =>
                              idAcademia = int.tryParse(v) ?? 1,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              try {
                                await _repo.update(
                                  idEstudiante: _idOf(row),
                                  nombres: nombres.text.trim(),
                                  apellidos: apellidos.text.trim(),
                                  fechaNacimiento: fecha.text.trim().isEmpty
                                      ? null
                                      : fecha.text.trim(),
                                  direccion: direccion.text.trim().isEmpty
                                      ? null
                                      : direccion.text.trim(),
                                  telefono: telefono.text.trim().isEmpty
                                      ? null
                                      : telefono.text.trim(),
                                  idAcademia: idAcademia,
                                );
                                if (mounted) {
                                  Navigator.pop(ctx, true);
                                  _load();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Actualizado correctamente'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'GUARDAR CAMBIOS',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
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
      ),
    );
  }

  Future<void> _toggleEstado(Map<String, dynamic> r) async {
    if (!_isAdmin) return;

    final activo = r['activo'] == true;
    final id = _idOf(r);

    setState(() {
      r['activo'] = !activo;
    });

    try {
      if (activo) {
        await _repo.deactivate(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estudiante desactivado'), duration: Duration(seconds: 1)),
        );
      } else {
        await _repo.activate(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estudiante activado'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      setState(() {
        r['activo'] = activo;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirstLoad = _loading && _rows.isEmpty;

    final core = LayoutBuilder(
      builder: (ctx, c) {
        final isNarrow = c.maxWidth < 820;

        final header =
            _selected.isNotEmpty ? _buildSelectionBar(context) : _buildModernHeader(context, isNarrow);

        final content = isFirstLoad
            ? _LoadingPlaceholder(isNarrow: isNarrow, viewMode: _viewMode, dense: _dense)
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : (_rows.isEmpty
                    ? _EmptyState(
                        title: 'Sin estudiantes',
                        subtitle: 'No se encontraron registros.',
                        primary: ('Refrescar', _load),
                        secondary: ('Limpiar filtros', () {
                          _q.clear();
                          _catId = null;
                          _onlyActive = null;
                          _load();
                        }),
                      )
                    : (_viewMode == _ViewMode.cards ? _buildCards(_rows) : _buildTable(_rows)));

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (_error != null)
              Container(
                color: Colors.red.shade50,
                padding: const EdgeInsets.all(8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade900),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: content),
                  if (_loading && !isFirstLoad)
                    const Positioned(right: 12, top: 8, child: _LoadingChip()),
                ],
              ),
            ),
            _PaginationControls(
              currentPage: _page,
              totalItems: _total,
              pageSize: _pageSize,
              onPageChange: (p) {
                setState(() => _page = p);
                _load();
              },
              onPageSizeChange: (s) {
                setState(() {
                  _pageSize = s;
                  _page = 1;
                });
                _load();
              },
            ),
          ],
        );

        return _withShortcuts(body);
      },
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Estudiantes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refrescar')
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearEstudianteMatriculaScreen()),
                );
                if (created == true) _load();
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo'),
            )
          : null,
      body: Padding(padding: const EdgeInsets.all(12), child: core),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isNarrow) {
    final cs = Theme.of(context).colorScheme;

    final search = TextField(
      controller: _q,
      focusNode: _searchFocus,
      decoration: InputDecoration(
        hintText: 'Buscar estudiante...',
        prefixIcon: Icon(Icons.search, color: cs.primary),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        suffixIcon: _q.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _q.clear();
                  _onSearchChanged();
                },
              )
            : null,
      ),
      onChanged: (_) => _onSearchChanged(),
    );

    final catFilter = SizedBox(
      width: 180,
      child: DropdownButtonFormField<int?>(
        value: _catId,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: cs.surface,
          prefixIcon: const Icon(Icons.category_outlined, size: 20),
          hintText: 'Categoría',
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todas')),
          ..._catOptions.map((e) => DropdownMenuItem(
                value: (e['id'] as num).toInt(),
                child: Text(e['nombre']?.toString() ?? ''),
              )),
        ],
        onChanged: (v) {
          setState(() {
            _catId = v;
            _page = 1;
          });
          _load();
        },
      ),
    );

    final statusFilter = SizedBox(
      width: 160,
      child: DropdownButtonFormField<bool?>(
        value: _onlyActive,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: cs.surface,
          prefixIcon: const Icon(Icons.filter_alt_outlined, size: 20),
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('Todos')),
          DropdownMenuItem(value: true, child: Text('Activos')),
          DropdownMenuItem(value: false, child: Text('Inactivos')),
        ],
        onChanged: (v) {
          setState(() {
            _onlyActive = v;
            _page = 1;
          });
          _load();
        },
      ),
    );

    final viewToggle = Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.grid_view_rounded,
                color: _viewMode == _ViewMode.cards
                    ? cs.primary
                    : cs.onSurfaceVariant),
            onPressed: () => setState(() => _viewMode = _ViewMode.cards),
          ),
          Container(width: 1, height: 20, color: cs.outlineVariant),
          IconButton(
            icon: Icon(Icons.table_rows_rounded,
                color: _viewMode == _ViewMode.table
                    ? cs.primary
                    : cs.onSurfaceVariant),
            onPressed: () => setState(() => _viewMode = _ViewMode.table),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: isNarrow
          ? Column(
              children: [
                search,
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: catFilter),
                  const SizedBox(width: 8),
                  Expanded(child: statusFilter)
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    viewToggle,
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: _showExportMenu,
                    )
                  ],
                )
              ],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                catFilter,
                const SizedBox(width: 12),
                statusFilter,
                const SizedBox(width: 12),
                viewToggle,
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _showExportMenu,
                  tooltip: 'Exportar',
                ),
              ],
            ),
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _selected.clear())),
          const SizedBox(width: 8),
          Text(
            '${_selected.length} seleccionados',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.grid_on), onPressed: _exportExcel, tooltip: 'Exportar selección a Excel'),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPdf, tooltip: 'Exportar selección a PDF'),
          IconButton(icon: const Icon(Icons.table_rows), onPressed: _exportCsv, tooltip: 'Exportar selección a CSV'),
        ],
      ),
    );
  }

  Widget _buildCards(List<Map<String, dynamic>> rows) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final r = rows[i];
        final activo = r['activo'] == true;
        final id = _idOf(r);
        final isSelected = _selected.contains(id);

        return Card(
          elevation: isSelected ? 4 : 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openDetail(id),
            onLongPress: () => setState(() => isSelected ? _selected.remove(id) : _selected.add(id)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_selected.isNotEmpty) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (v) => setState(() => v! ? _selected.add(id) : _selected.remove(id)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Hero(
                    tag: 'est_avatar_${r['id']}',
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        '${r['nombres']}'.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['nombres']} ${r['apellidos']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          r['cedula'] ?? 'Sin cédula',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: activo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                activo ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  color: activo ? Colors.green : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (v) {
                          if (v == 'detail') _openDetail(id);
                          if (v == 'edit') _edit(row: r);
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'detail',
                            child: Row(children: [
                              Icon(Icons.visibility, size: 18),
                              SizedBox(width: 8),
                              Text('Ver perfil')
                            ]),
                          ),
                          if (_isAdmin)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Editar')
                              ]),
                            ),
                        ],
                      ),
                      if (_isAdmin)
                        IconButton(
                          icon: Icon(
                            activo ? Icons.block : Icons.check_circle_outline,
                            color: activo ? Colors.red.shade300 : Colors.green,
                            size: 20,
                          ),
                          onPressed: () => _toggleEstado(r),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> rows) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: true,
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Cédula')),
                DataColumn(label: Text('Subcategoría')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: rows.map((r) {
                final activo = r['activo'] == true;
                final id = _idOf(r);
                final isSelected = _selected.contains(id);

                return DataRow(
                  selected: isSelected,
                  onSelectChanged: (v) => setState(() => v! ? _selected.add(id) : _selected.remove(id)),
                  cells: [
                    DataCell(Text('${r['nombres']} ${r['apellidos']}', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(r['cedula'] ?? '—')),
                    DataCell(Text(r['subcategoriaNombre']?.toString() ?? '—')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: activo ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Ver detalle',
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _openDetail(id),
                          ),
                          if (_isAdmin)
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(row: r),
                            ),
                          if (_isAdmin)
                            IconButton(
                              tooltip: activo ? 'Desactivar' : 'Activar',
                              icon: Icon(
                                activo ? Icons.block : Icons.check_circle_outline,
                                color: activo ? Colors.red.shade400 : Colors.green.shade600,
                              ),
                              onPressed: () => _toggleEstado(r),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _withShortcuts(Widget child) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const _ReloadIntent(),
      },
      child: Actions(
        actions: {
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(onInvoke: (_) {
            _searchFocus.requestFocus();
            return null;
          }),
          _ReloadIntent: CallbackAction<_ReloadIntent>(onInvoke: (_) {
            _load();
            return null;
          }),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

// === WIDGETS DE APOYO ===

class _PaginationControls extends StatelessWidget {
  final int currentPage, totalItems, pageSize;
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

    final from = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final to = (currentPage * pageSize) > totalItems ? totalItems : (currentPage * pageSize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$from-$to de $totalItems',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              )),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1 ? () => onPageChange(currentPage - 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: to < totalItems ? () => onPageChange(currentPage + 1) : null,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title, subtitle;
  final (String, VoidCallback) primary;
  final (String, VoidCallback)? secondary;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Theme.of(context).disabledColor.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: primary.$2, child: Text(primary.$1)),
                if (secondary != null)
                  OutlinedButton(onPressed: secondary!.$2, child: Text(secondary!.$1)),
              ],
            )
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            const Text('Error', style: TextStyle(fontSize: 18)),
            Text(error),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            )
          ],
        ),
      );
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();
  @override
  Widget build(BuildContext context) => const Chip(
        avatar: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        label: Text('Cargando...'),
      );
}

class _LoadingPlaceholder extends StatelessWidget {
  final bool isNarrow;
  final _ViewMode viewMode;
  final bool dense;

  const _LoadingPlaceholder({
    required this.isNarrow,
    required this.viewMode,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
